#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
# Copyright:: Copyright (c) Chef Software Inc.
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
            if @service.instance_of? Azure::ResourceManagement::ARMInterface
              service.get_latest_chef_extension_version(
                azure_service_location: config[:azure_service_location],
                chef_extension_publisher: get_chef_extension_publisher,
                chef_extension: chef_extension_name
              )
            elsif @service.instance_of? Azure::ServiceManagement::ASMInterface
              extensions = service.get_extension(chef_extension_name, get_chef_extension_publisher)
              extensions.css("Version").max.text.split(".").first + ".*"
            end
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
            pub_config[:client_rb] = "chef_server_url \t #{Chef::Config[:chef_server_url].to_json}\nvalidation_client_name\t#{Chef::Config[:validation_client_name].to_json}"
          end

          pub_config[:runlist] = config[:run_list].empty? ? "" : config[:run_list].join(",").to_json
          pub_config[:custom_json_attr] = config[:json_attributes] || {}
          pub_config[:extendedLogs] = config[:extended_logs] ? "true" : "false"
          pub_config[:hints] = ohai_hints if @service.instance_of?(Azure::ResourceManagement::ARMInterface) && !config[:ohai_hints].nil?
          pub_config[:chef_daemon_interval] = config[:chef_daemon_interval] if config[:chef_daemon_interval]
          pub_config[:daemon] = config[:daemon] if config[:daemon]

          # bootstrap attributes
          pub_config[:bootstrap_options] = {}
          pub_config[:bootstrap_options][:environment] = config[:environment] if config[:environment]
          pub_config[:bootstrap_options][:chef_node_name] = config[:chef_node_name] if config[:chef_node_name]
          pub_config[:bootstrap_options][:chef_server_url] = Chef::Config[:chef_server_url] if Chef::Config[:chef_server_url]
          pub_config[:bootstrap_options][:validation_client_name] = Chef::Config[:validation_client_name] if Chef::Config[:validation_client_name]
          pub_config[:bootstrap_options][:node_verify_api_cert] = config[:node_verify_api_cert] ? "true" : "false" if config.key?(:node_verify_api_cert)
          pub_config[:bootstrap_options][:bootstrap_version] = config[:bootstrap_version] if config[:bootstrap_version]
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

          pri_config
        end

      end
    end
  end
end
