#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
#
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

require "chef/knife"

class Chef
  class Knife
    module AzurermBase
      include Chef::Mixin::ShellOut

      ## azure-xplat-cli version that introduced deprecation of Windows Credentials
      ## Manager (WCM) usage for authentication credentials storage purpose ##
      XPLAT_VERSION_WITH_WCM_DEPRECATED ||= "0.10.5".freeze

      def self.included(includer)
        includer.class_eval do
          deps do
            require "readline"
            require "chef/json_compat"
            require_relative "../../../azure/resource_management/ARM_interface"
            require "chef/mixin/shell_out"
            require "time" unless defined?(Time)
            require "json" unless defined?(JSON)

            if Chef::Platform.windows?
              require_relative "../../azure/resource_management/windows_credentials"
              include Azure::ARM::WindowsCredentials
            end
          end

          option :azure_resource_group_name,
            short: "-r RESOURCE_GROUP_NAME",
            long: "--azure-resource-group-name RESOURCE_GROUP_NAME",
            description: "The Resource Group name."
        end
      end

      def service
        details = authentication_details
        details.update(azure_subscription_id: config[:azure_subscription_id])
        @service ||= begin
                      require_relative "../../../azure/resource_management/ARM_interface"
                      service = Azure::ResourceManagement::ARMInterface.new(details)
                    end
        @service.ui = ui
        @service
      end

      # validates ARM mandatory keys
      def validate_arm_keys!(*keys)
        parse_publish_settings_file(config[:azure_publish_settings_file]) unless config[:azure_publish_settings_file].nil?
        keys.push(:azure_subscription_id)

        if azure_cred?
          validate_azure_login
        else
          keys.concat(%i{azure_tenant_id azure_client_id azure_client_secret})
        end

        errors = []
        keys.each do |k|
          if config[k].nil?
            errors << "You did not provide a valid '#{pretty_key(k)}' value. Please set knife[:#{k}] in your config.rb (knife.rb)."
          end
        end
        if errors.each { |e| ui.error(e) }.any?
          exit 1
        end
      end

      def authentication_details
        if is_azure_cred?
          return { azure_tenant_id: config[:azure_tenant_id], azure_client_id: config[:azure_client_id], azure_client_secret: config[:azure_client_secret] }
        elsif Chef::Platform.windows?
          token_details = token_details_for_windows
        else
          token_details = token_details_for_linux
        end

        check_token_validity(token_details)
      end

      def get_azure_cli_version
        if @azure_version != ""
          get_version = shell_out!("azure -v || az -v | grep azure-cli", returns: [0]).stdout
          @azure_version = get_version.gsub(/[^0-9.]/, "")
        end
        @azure_prefix = @azure_version.to_i < 2 ? "azure" : "az"
        @azure_version
      end

      def token_details_for_windows
        if is_old_xplat?
          token_details_from_WCM
        else
          is_WCM_env_var_set? ? token_details_from_WCM : token_details_from_accessToken_file
        end
      end

      def token_details_for_linux
        token_details_from_accessToken_file
      end

      def token_details_from_accessToken_file
        home_dir = File.expand_path("~")
        file = File.read(home_dir + "/.azure/accessTokens.json")
        file = JSON.parse(file)
        { tokentype: file[-1]["tokenType"], user: file[-1]["userId"], token: file[-1]["accessToken"], clientid: file[-1]["_clientId"], expiry_time: file[-1]["expiresOn"], refreshtoken: file[-1]["refreshToken"] }
      end

      def is_token_valid?(token_details)
        time_difference = Time.parse(token_details[:expiry_time]) - Time.now.utc
        if time_difference <= 0
          false
        elsif time_difference <= 600 # 600sec = 10min
          # This is required otherwise a long running command may fail inbetween if the token gets expired.
          raise "Token will expire within 10 minutes. Please run '#{@azure_prefix} login' command"
        else
          true
        end
      end

      def refresh_token
        azure_authentication
        token_details = Chef::Platform.windows? ? token_details_for_windows : token_details_for_linux
      end

      def azure_authentication
        ui.log("Authenticating...")
        Mixlib::ShellOut.new("#{@azure_prefix} vm show 'knifetest@resourcegroup' testvm", timeout: 30).run_command
      rescue Mixlib::ShellOut::CommandTimeout
      rescue Exception
        raise_azure_status
      end

      def check_token_validity(token_details)
        unless is_token_valid?(token_details)
          token_details = refresh_token
          raise_azure_status unless is_token_valid?(token_details)
        end
        token_details
      end

      def validate_azure_login
        if Chef::Platform.windows? && (is_old_xplat? || is_WCM_env_var_set?)
          # cmdkey command is used for accessing windows credential manager
          xplat_creds_cmd = Mixlib::ShellOut.new("cmdkey /list | findstr AzureXplatCli")
          result = xplat_creds_cmd.run_command
          raise login_message if result.stdout.nil? || result.stdout.empty?
        else
          home_dir = File.expand_path("~")
          if !File.exist?(home_dir + "/.azure/accessTokens.json") || ( File.size?(home_dir + "/.azure/accessTokens.json") <= 2 )
            raise login_message
          end
        end
      end

      def parse_publish_settings_file(filename)
        require "nokogiri" unless defined?(Nokogiri)
        require "base64" unless defined?(Base64)
        require "openssl" unless defined?(OpenSSL)
        require "uri" unless defined?(URI)
        retried_with_legacy_provider = false
        begin
          # Use the block form of File.open so the file handle is always closed
          # after parsing, rather than left open for the GC to close later. This
          # matters on Windows, where an open handle prevents a Tempfile-based
          # fixture (used in specs) from being unlinked.
          doc = File.open(find_file(filename)) { |file| Nokogiri::XML(file) }
          profile = doc.at_css("PublishProfile")
          subscription = profile.at_css("Subscription")
          # check given PublishSettings XML file format.Currently PublishSettings file have two different XML format
          if profile.attribute("SchemaVersion").nil?
            management_cert = OpenSSL::PKCS12.new(Base64.decode64(profile.attribute("ManagementCertificate").value))
            config[:azure_api_host_name] = URI(profile.attribute("Url").value).host
          elsif profile.attribute("SchemaVersion").value == "2.0"
            management_cert = OpenSSL::PKCS12.new(Base64.decode64(subscription.attribute("ManagementCertificate").value))
            config[:azure_api_host_name] = URI(subscription.attribute("ServiceManagementUrl").value).host
          else
            ui.error("Publish settings file Schema not supported - " + filename)
          end
          config[:azure_mgmt_cert] = management_cert.certificate.to_pem + management_cert.key.to_pem
          config[:azure_subscription_id] = doc.at_css("Subscription").attribute("Id").value
        rescue OpenSSL::PKCS12::PKCS12Error => error
          # Older Azure publish settings files use PKCS12 certificates encrypted with
          # the legacy RC2-40-CBC cipher, which OpenSSL 3.x disables by default. On
          # OpenSSL 3.x the raised error usually doesn't mention "RC2-40-CBC" at all -
          # it's typically the generic "PKCS12_parse: unsupported" - so treat any
          # "unsupported"-style PKCS12Error as a candidate for the legacy-cipher retry,
          # not just messages that explicitly say RC2-40-CBC. Only load OpenSSL's
          # "legacy" provider (widening the process-wide crypto surface) if we
          # actually hit one of these failures, and only retry once.
          if !retried_with_legacy_provider && legacy_cipher_error?(error) && load_openssl_legacy_provider
            retried_with_legacy_provider = true
            retry
          end

          if legacy_cipher_error?(error)
            ui.error("Cannot parse certificate: #{error.message}")
            if retried_with_legacy_provider
              # We already successfully loaded OpenSSL's legacy provider and retried,
              # but parsing still failed with what looks like a legacy-cipher error.
              # The cipher isn't "unavailable" in this case -- something else about
              # the certificate is unparseable -- so don't tell the user to
              # regenerate it with a "more recent cipher" as if the provider were
              # still missing.
              ui.error("The PKCS12 certificate could not be parsed even after enabling OpenSSL's " \
                "legacy provider (used for ciphers such as RC2-40-CBC). The file may be corrupt " \
                "or use a cipher that isn't supported even by the legacy provider.")
            else
              ui.error("The PKCS12 certificate may use the legacy RC2-40-CBC cipher, which is unavailable " \
                "in the current OpenSSL configuration. Please regenerate the publish settings file " \
                "with a more recent cipher.")
            end
          else
            ui.error("Error parsing PKCS12 certificate: #{error.message}")
          end
          exit 1
        rescue => error
          puts "#{error.class} and #{error.message}"
          exit 1
        end
      end

      # Returns true if the given OpenSSL::PKCS12::PKCS12Error looks like it was
      # caused by a legacy/deprecated cipher (such as RC2-40-CBC) being disabled by
      # default on OpenSSL 3.x. On OpenSSL 3.x this commonly surfaces as a generic
      # "unsupported" error rather than one that names RC2-40-CBC explicitly.
      def legacy_cipher_error?(error)
        error.message =~ /RC2-40-CBC/i || error.message =~ /unsupported/i
      end

      # Attempts to load OpenSSL's "legacy" provider (needed to decrypt PKCS12 files
      # using deprecated ciphers such as RC2-40-CBC). Returns true if the provider was
      # loaded successfully, false otherwise (e.g. it isn't available on this system).
      def load_openssl_legacy_provider
        if defined?(OpenSSL::Provider)
          OpenSSL::Provider.load("legacy")
          OpenSSL::Provider.load("default")
          return true
        end

        # `OpenSSL::Provider` was only added to the "openssl" Ruby gem in version 3.0,
        # which ships as a default gem starting with Ruby 3.2. On supported Ruby 3.1
        # installations (bundled openssl gem < 3.0) there's no Ruby API to load an
        # OpenSSL 3.x provider, even though the underlying libcrypto may itself be
        # OpenSSL 3.x and support providers. Fall back to calling libcrypto's
        # OSSL_PROVIDER_load directly via FFI (already a runtime dependency of this
        # gem) so legacy PKCS12 files can still be decrypted on Ruby 3.1.
        load_openssl_legacy_provider_via_ffi
      rescue StandardError, LoadError
        false
      end

      # Loads the OpenSSL "legacy" and "default" providers by calling libcrypto's
      # OSSL_PROVIDER_load function directly through FFI. This only works when the
      # linked libcrypto is OpenSSL 3.x (the function doesn't exist on OpenSSL 1.1.1
      # or LibreSSL); any failure to locate the library/symbol is treated as the
      # provider simply being unavailable.
      def load_openssl_legacy_provider_via_ffi
        require "ffi" unless defined?(FFI)

        # Bind to OSSL_PROVIDER_load in the *current process's* already-loaded
        # symbol table (FFI::Library::CURRENT_PROCESS) rather than dlopen-ing "ssl"/"crypto"
        # again. Re-loading libcrypto as a second, separate mapping alongside the
        # one Ruby's own "openssl" extension already loaded can make OpenSSL 3.x
        # detect what it considers an unsafe double-load and abort the whole
        # process (observed as "libcrypto in an unsafe way" on macOS); attaching to
        # the existing in-process symbols avoids that entirely.
        provider_loader = Module.new do
          extend FFI::Library
          ffi_lib FFI::Library::CURRENT_PROCESS
          attach_function :OSSL_PROVIDER_load, %i{pointer string}, :pointer
        end

        legacy = provider_loader.OSSL_PROVIDER_load(nil, "legacy")
        default = provider_loader.OSSL_PROVIDER_load(nil, "default")
        !legacy.null? && !default.null?
      rescue StandardError, LoadError
        false
      end

      def find_file(name)
        name = ::File.expand_path(name)
        config_dir = Chef::Knife.chef_config_dir
        if File.exist? name
          file = name
        elsif config_dir && File.exist?(File.join(config_dir, name))
          file = File.join(config_dir, name)
        elsif File.exist?(File.join(ENV["HOME"], ".chef", name))
          file = File.join(ENV["HOME"], ".chef", name)
        else
          ui.error("Unable to find file - " + name)
          exit 1
        end
        file
      end

      def msg_server_summary(server)
        puts "\n\n"
        if server.provisioningstate == "Succeeded"
          Chef::Log.info("Server creation went successful.")
          puts "\nServer Details are:\n"

          msg_pair("Server ID", server.id)
          msg_pair("Server Name", server.name)
          msg_pair("Server Public IP Address", server.publicipaddress)
          if is_image_windows?
            msg_pair("Server RDP Port", server.rdpport)
          else
            msg_pair("Server SSH Port", server.sshport)
          end
          msg_pair("Server Location", server.locationname)
          msg_pair("Server OS Type", server.ostype)
          msg_pair("Server Provisioning State", server.provisioningstate)
        else
          Chef::Log.info("Server Creation Failed.")
        end

        puts "\n\n"

        if server.resources.provisioning_state == "Succeeded"
          Chef::Log.info("Server Extension creation went successful.")
          puts "\nServer Extension Details are:\n"

          msg_pair("Server Extension ID", server.resources.id)
          msg_pair("Server Extension Name", server.resources.name)
          msg_pair("Server Extension Publisher", server.resources.publisher)
          msg_pair("Server Extension Type", server.resources.type)
          msg_pair("Server Extension Type Handler Version", server.resources.type_handler_version)
          msg_pair("Server Extension Provisioning State", server.resources.provisioning_state)
        else
          Chef::Log.info("Server Extension Creation Failed.")
        end
        puts "\n"
      end

      def validate_params!
        if config[:connection_user].nil?
          raise ArgumentError, "Please provide --connection-user option for authentication."
        end

        unless config[:connection_password].nil? ^ config[:ssh_public_key].nil?
          raise ArgumentError, "Please specify either --connection-password or --ssh-public-key option for authentication."
        end

        if config[:azure_vnet_subnet_name] && !config[:azure_vnet_name]
          raise ArgumentError, "When --azure-vnet-subnet-name is specified, the --azure-vnet-name must also be specified."
        end

        if config[:azure_vnet_subnet_name] == "GatewaySubnet"
          raise ArgumentError, "GatewaySubnet cannot be used as the name for --azure-vnet-subnet-name option. GatewaySubnet can only be used for virtual network gateways."
        end

        if config[:node_ssl_verify_mode] && !%w{none peer}.include?(config[:node_ssl_verify_mode])
          raise ArgumentError, "Invalid value '#{config[:node_ssl_verify_mode]}' for --node-ssl-verify-mode. Use Valid values i.e 'none', 'peer'."
        end

        if !is_image_windows?
          if (config[:azure_vm_name].match(/^(?=.*[a-zA-Z-])([a-zA-z0-9-]{1,64})$/)).nil?
            raise ArgumentError, "VM name can only contain alphanumeric and hyphen(-) characters and maximum length cannot exceed 64 characters."
          end
        elsif (config[:azure_vm_name].match(/^(?=.*[a-zA-Z-])([a-zA-z0-9-]{1,15})$/)).nil?
          raise ArgumentError, "VM name can only contain alphanumeric and hyphen(-) characters and maximum length cannot exceed 15 characters."
        end

        if config[:server_count].to_i > 5
          raise ArgumentError, "Maximum allowed value of --server-count is 5."
        end

        if config[:daemon]
          unless is_image_windows?
            raise ArgumentError, "The daemon option is only support for Windows nodes."
          end

          unless %w{none service task}.include?(config[:daemon])
            raise ArgumentError, "Invalid value for --daemon option. Use valid daemon values i.e 'none', 'service' and 'task'."
          end
        end

        if config[:azure_image_os_type]
          unless %w{ubuntu centos rhel debian windows}.include?(config[:azure_image_os_type])
            raise ArgumentError, "Invalid value of --azure-image-os-type. Accepted values ubuntu|centos|rhel|debian|windows"
          end
        end

        if config[:azure_storage_account_type]
          # --azure-storage-account-type now sets the managed OS disk's SKU rather than a
          # storage account's replication type; the old storage-account-only replication
          # values (Standard_ZRS, Standard_GRS, Standard_RAGRS) are not valid managed disk
          # SKUs and would otherwise be sent through to Azure and fail remotely.
          legacy_storage_account_types = %w{Standard_ZRS Standard_GRS Standard_RAGRS}
          valid_managed_disk_types = %w{Standard_LRS StandardSSD_LRS Premium_LRS StandardSSD_ZRS Premium_ZRS}
          if legacy_storage_account_types.include?(config[:azure_storage_account_type])
            raise ArgumentError, "'#{config[:azure_storage_account_type]}' is a storage-account replication type " \
              "that is no longer valid for --azure-storage-account-type, since VMs now use managed disks. " \
              "Please use one of the managed disk SKUs instead: #{valid_managed_disk_types.join(", ")}."
          elsif !valid_managed_disk_types.include?(config[:azure_storage_account_type])
            raise ArgumentError, "Invalid value '#{config[:azure_storage_account_type]}' for --azure-storage-account-type. " \
              "Use one of the following managed disk SKUs: #{valid_managed_disk_types.join(", ")}."
          end
        end

        config[:ohai_hints] = format_ohai_hints(config[:ohai_hints])
        validate_ohai_hints unless config[:ohai_hints].casecmp("default").zero?
      end

      private

      def msg_pair(label, value, color = :cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def pretty_key(key)
        key.to_s.tr("_", " ").gsub(/\w+/) { |w| (w =~ /(ssh)|(aws)/i) ? w.upcase : w.capitalize }
      end

      def is_image_windows?
        config[:azure_image_reference_offer] =~ /WindowsServer.*/
      end

      def is_azure_cred?
        config[:azure_tenant_id] && config[:azure_client_id] && config[:azure_client_secret]
      end

      def azure_cred?
        config[:azure_tenant_id].nil? || config[:azure_client_id].nil? || config[:azure_client_secret].nil?
      end

      def is_old_xplat?
        return true unless @azure_version

        Gem::Version.new(@azure_version) < Gem::Version.new(XPLAT_VERSION_WITH_WCM_DEPRECATED)
      end

      def is_WCM_env_var_set?
        ENV["AZURE_USE_SECURE_TOKEN_STORAGE"].nil? ? false : true
      end

      def raise_azure_status
        raise "Token has expired. Please run '#{@azure_prefix} login' command"
      end

      def login_message
        ## Older versions of the Azure CLI on Windows stored credentials in a unique way
        ## in Windows Credentails Manager (WCM).
        ## Newer versions use the same pattern across platforms where credentials gets
        ## stored in ~/.azure/accessTokens.json file.
        "Please run XPLAT's '#{@azure_prefix} login' command OR specify azure_tenant_id, azure_subscription_id, azure_client_id, azure_client_secret in your config.rb (knife.rb)."
      end
    end
  end
end
