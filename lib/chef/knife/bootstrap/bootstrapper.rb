#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
# Copyright:: Copyright (c) 2012-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Azure
  class ResourceManagement
    autoload :ARMInterface, "azure/resource_management/ARM_interface"
  end
end

class Chef
  class Knife
    class Bootstrap
      module Bootstrapper

        def get_chef_extension_name
          is_image_windows? ? "ChefClient" : "LinuxChefClient"
        end

        def get_chef_extension_publisher
          "Chef.Bootstrap.WindowsAzure"
        end

        def default_hint_options
          %w{
            vm_name
            public_fqdn
            platform
          }
        end

        # get latest version
        def get_chef_extension_version(chef_extension_name = nil)
          if config[:azure_chef_extension_version]
            config[:azure_chef_extension_version]
          else
            chef_extension_name ||= get_chef_extension_name
            service.get_latest_chef_extension_version(
              azure_service_location: config[:azure_service_location],
              chef_extension_publisher: get_chef_extension_publisher,
              chef_extension: chef_extension_name
            )
          end
        end

        def ohai_hints
          hint_values = config[:ohai_hints]
          if hint_values.casecmp("default") == 0
            default_hint_options
          else
            hint_values.split(",")
          end
        end

        def get_chef_extension_public_params
          pub_config = {}

          if config[:azure_extension_client_config]
            pub_config[:client_rb] = File.read(File.expand_path(config[:azure_extension_client_config]))
          else
            # `chef_license` is set here (rather than left to interactive/env-var
            # acceptance) because the VM extension's first chef-client run
            # otherwise fails with "Chef Infra Client cannot execute without
            # accepting the license" -- there's no TTY/CHEF_LICENSE env var
            # available inside the freshly-provisioned VM.
            pub_config[:client_rb] = "chef_server_url \t #{Chef::Config[:chef_server_url].to_json}\nvalidation_client_name\t#{Chef::Config[:validation_client_name].to_json}\nchef_license\t\"accept-no-persist\""
          end

          # The `chef_license` line in client_rb above only covers chef-client
          # invocations that read that config file (`-c client.rb`). The VM
          # extension also runs a separate `chef-apply -e "cron '...' do ... end"`
          # step (with no `-c` flag) to install the periodic chef-client cron job,
          # which does not read client.rb and fails with the same license error.
          # The extension's own shared.sh reads this top-level "CHEF_LICENSE"
          # public setting and exports it as an environment variable before
          # running any step, so setting it here covers that cron step too.
          pub_config[:CHEF_LICENSE] = "accept-no-persist"

          # chef_license_key is now forwarded via get_chef_extension_private_params
          # below (protectedSettings), not here -- see
          # chef-partners/azure-chef-extension#413 (version 1210.15.11.1,
          # rolled out to all regions), which added a decrypt path for it.

          pub_config[:runlist] = config[:run_list].empty? ? "" : config[:run_list].join(",").to_json
          pub_config[:custom_json_attr] = config[:json_attributes] || {}
          pub_config[:extendedLogs] = config[:extended_logs] ? "true" : "false"
          pub_config[:hints] = ohai_hints if @service.instance_of?(Azure::ResourceManagement::ARMInterface) && !config[:ohai_hints].nil?
          pub_config[:chef_daemon_interval] = config[:chef_daemon_interval] if config[:chef_daemon_interval]
          pub_config[:daemon] = config[:daemon] if config[:daemon]

          # bootstrap attributes
          pub_config[:bootstrap_options] = {}
          # The Chef VM extension always renders this value into a "-E <value>"
          # chef-client argument. If it's left blank (nil, or an explicitly
          # empty string, both of which are truthy in Ruby), chef-client's
          # option parser fails with "missing argument: -E" because the flag
          # gets emitted without a value. Default to Chef's standard
          # "_default" environment whenever --environment isn't supplied or
          # was supplied blank.
          pub_config[:bootstrap_options][:environment] = config[:environment].to_s.empty? ? "_default" : config[:environment]
          pub_config[:bootstrap_options][:chef_node_name] = config[:chef_node_name] if config[:chef_node_name]
          pub_config[:bootstrap_options][:chef_server_url] = Chef::Config[:chef_server_url] if Chef::Config[:chef_server_url]
          pub_config[:bootstrap_options][:validation_client_name] = Chef::Config[:validation_client_name] if Chef::Config[:validation_client_name]
          pub_config[:bootstrap_options][:node_verify_api_cert] = config[:node_verify_api_cert] ? "true" : "false" if config.key?(:node_verify_api_cert)
          # If --bootstrap-version isn't given, the extension's chef-install.sh
          # treats bootstrap_version as blank, can't tell the major version is
          # >= 19, and falls back to installing the legacy "chef" product
          # (currently capped in the 18.x line) instead of "chef-ice" (19.x+).
          # Chef::Knife::Bootstrap#version_to_install (used by the stock
          # SSH-based chef-full.erb bootstrap that knife-ec2/knife-google rely
          # on) defaults to the major version of the `chef` gem bundled
          # alongside `knife` itself (`Chef::VERSION.split(".").first`) in
          # that same situation, so mirror that default here too.
          resolved_bootstrap_version = config[:bootstrap_version] || Chef::VERSION.split(".").first
          pub_config[:bootstrap_options][:bootstrap_version] = resolved_bootstrap_version
          pub_config[:bootstrap_options][:node_ssl_verify_mode] = config[:node_ssl_verify_mode] if config[:node_ssl_verify_mode]
          pub_config[:bootstrap_options][:bootstrap_proxy] = config[:bootstrap_proxy] if config[:bootstrap_proxy]
          pub_config
        end

        def load_correct_secret
          secret_file = config[:encrypted_data_bag_secret_file]
          secret = config[:encrypted_data_bag_secret]

          secret_file = Chef::EncryptedDataBagItem.load_secret(secret_file) unless secret_file.nil?

          secret_file || secret
        end

        def create_node_and_client_pem
          client_builder ||= begin
            require "chef/knife/bootstrap/client_builder"
            Chef::Knife::Bootstrap::ClientBuilder.new(
              chef_config: Chef::Config,
              config: config,
              ui: ui
            )
          end
          client_builder.run
          client_builder.client_path
        end

        def get_chef_extension_private_params
          pri_config = {}
          # validator less bootstrap support for bootstrap protocol cloud-api
          if Chef::Config[:validation_key] && File.exist?(File.expand_path(Chef::Config[:validation_key]))
            pri_config[:validation_key] = File.read(File.expand_path(Chef::Config[:validation_key]))
          else
            if Chef::VERSION.split(".").first.to_i == 11
              ui.error("Unable to find validation key. Please verify your configuration file for validation_key config value.")
              exit 1
            end
            if config[:server_count].to_i > 1
              node_name = config[:chef_node_name]
              0.upto(config[:server_count].to_i - 1) do |count|
                config[:chef_node_name] = node_name + count.to_s
                key_path = create_node_and_client_pem
                pri_config[("client_pem" + count.to_s).to_sym] = File.read(key_path)
              end
              config[:chef_node_name] = node_name
            else
              key_path = create_node_and_client_pem
              if File.exist?(key_path)
                pri_config[:client_pem] = File.read(key_path)
              else
                ui.error('Unable to find client.pem at given path #{key_path}')
                exit 1
              end
            end
          end

          # SSL cert bootstrap support
          if config[:cert_path]
            if File.exist?(File.expand_path(config[:cert_path]))
              pri_config[:chef_server_crt] = File.read(File.expand_path(config[:cert_path]))
            else
              ui.error("Specified SSL certificate does not exist.")
              exit 1
            end
          end

          # encrypted_data_bag_secret key for encrypting/decrypting the data bags
          pri_config[:encrypted_data_bag_secret] = load_correct_secret

          # The extension's install scripts (chef-install.sh/shared.sh,
          # chef-install.psm1/shared.ps1) now decrypt protectedSettings for
          # chef_license_key and prefer it over the deprecated publicSettings
          # location (chef-partners/azure-chef-extension#413, shipped as
          # version 1210.15.11.1, rolled out to all regions for both
          # ChefClient and LinuxChefClient). Forwarding it here instead of via
          # get_chef_extension_public_params means it is delivered to the VM
          # encrypted (CMS/PKCS7, decrypted locally using the cert the Azure
          # Guest Agent provisions), matching the treatment already given to
          # validation_key/chef_server_crt/encrypted_data_bag_secret above,
          # instead of as recoverable plaintext.
          #
          # chef_license_key is optional, not required: when it (and
          # config[:license_id]) are both absent, the extension's
          # chef-install.sh/shared.sh simply fall back to the unlicensed
          # omnitruck.chef.io download host with a warning; there is no
          # "chef_license_bypass" setting to set and no exit/failure path
          # to work around.
          #
          # NOTE: chef-partners/azure-chef-extension#384 briefly made
          # chef_license_key required-by-default with a chef_license_bypass
          # escape hatch, but #409 ("Route to omnitruck when no license_id
          # is specified, instead of chef_license_bypass") removed
          # chef_license_bypass entirely and restored the always-optional,
          # warning-only fallback described above for both the Linux and
          # Windows install scripts. Do not reintroduce bypass handling
          # here based on #384 alone -- check the extension's current HEAD
          # first, since that requirement no longer exists as of #409.
          #
          # Auto-forwarding here when a key IS available
          # (rather than requiring --chef-license-key on every single
          # invocation) mirrors exactly what upstream
          # Chef::Knife::Core::BootstrapContext/WindowsBootstrapContext do for
          # the stock SSH-based bootstrap that knife-ec2/knife-google rely on:
          # prefer an explicitly passed --chef-license-key, else fall back to
          # config[:license_id] (the already-persisted/validated local
          # license that Chef::Knife::Bootstrap#run populates via
          # fetch_license before any plugin_* hook runs). Unlike the stock
          # SSH-based context classes, there is no knife-azure-specific
          # handling of --disable-license-activation: that upstream option
          # isn't honored by this VM-extension delivery path, matching
          # knife-ec2/knife-google, which also have no special-case code for
          # it (their stock bootstrap context handles it generically for
          # SSH/WinRM delivery only, which doesn't apply here either).
          license_key = config[:chef_license_key] || config[:license_id]
          if license_key
            reject_pinned_extension_without_protected_license_support!(license_key)
            pri_config[:chef_license_key] = license_key
          end

          pri_config
        end

        # chef-partners/azure-chef-extension release that first decrypts
        # protectedSettings for chef_license_key (see the comment above the
        # pri_config[:chef_license_key] assignment); builds older than this
        # only read the deprecated, plaintext publicSettings location.
        MIN_LICENSE_CAPABLE_EXTENSION_VERSION = "1210.15.11.1".freeze

        # --azure-chef-extension-version lets a user pin an older extension
        # build via get_chef_extension_version. If that pinned build predates
        # MIN_LICENSE_CAPABLE_EXTENSION_VERSION, it cannot read the
        # protectedSettings-only chef_license_key we now forward, so the VM
        # would silently receive no usable license and the licensed Chef
        # Infra Client install would fail. Fail fast here instead, before the
        # ARM deployment is even built.
        def reject_pinned_extension_without_protected_license_support!(license_key)
          return unless license_key

          pinned_version = config[:azure_chef_extension_version]
          # Not pinned (resolved via get_latest_chef_extension_version) or a
          # "<major>.*" family selector: Azure resolves either to a current
          # build that supports protectedSettings, so there's nothing to
          # reject here.
          return if pinned_version.nil? || pinned_version.include?("*")

          begin
            pinned = Gem::Version.new(pinned_version)
          rescue ArgumentError
            # Not a comparable version string; let the Azure API validate (or
            # reject) it instead of guessing here.
            return
          end

          return if pinned >= Gem::Version.new(MIN_LICENSE_CAPABLE_EXTENSION_VERSION)

          ui.error(
            "--azure-chef-extension-version #{pinned_version} is older than " \
            "#{MIN_LICENSE_CAPABLE_EXTENSION_VERSION}, the chef-partners/azure-chef-extension " \
            "release that added protectedSettings support for chef_license_key. That version " \
            "only reads the deprecated, plaintext publicSettings location, so the forwarded " \
            "license key would be silently ignored and the licensed Chef Infra Client install " \
            "would fail. Pin a version >= #{MIN_LICENSE_CAPABLE_EXTENSION_VERSION}, omit " \
            "--azure-chef-extension-version to use the latest extension build, or pass " \
            "--disable-license-activation to intentionally bootstrap without forwarding a " \
            "license key."
          )
          exit 1
        end

      end
    end
  end
end
