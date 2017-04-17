#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
# Copyright:: Copyright (c) 2015 Opscode, Inc.
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

class Chef
  class Knife
    class AzureExtensionBase

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :cert_path,
        :long => "--cert-path PATH",
        :description => "SSL Certificate Path"

      option :auto_update_client,
        :long => "--auto-update-client",
        :boolean => true,
        :default => false,
        :description => "Set this flag to enable auto chef client update in azure chef extension. This flag should be used with cloud-api bootstrap protocol only"

      option :delete_chef_extension_config,
        :long => "--delete-chef-extension-config",
        :boolean => true,
        :default => false,
        :description => "Determines whether Chef configuration files removed when Azure removes the Chef resource extension from the VM. This option is only valid for the 'cloud-api' bootstrap protocol. The default is false."

      option :azure_extension_client_config,
        :long => "--azure-extension-client-config CLIENT_PATH",
        :description => "Optional. Path to a client.rb file for use by the bootstrapped node. Only honored when --bootstrap-protocol is set to `cloud-api`."

      
      def get_chef_extension_public_params
      	pub_config = Hash.new
      	if(locate_config_value(:azure_extension_client_config))
          pub_config[:client_rb] = File.read(locate_config_value(:azure_extension_client_config))
        else
          pub_config[:client_rb] = "chef_server_url \t #{Chef::Config[:chef_server_url].to_json}\nvalidation_client_name\t#{Chef::Config[:validation_client_name].to_json}"
        end

        pub_config[:runlist] = locate_config_value(:run_list).empty? ? "" : locate_config_value(:run_list).join(",").to_json
        pub_config[:autoUpdateClient] = locate_config_value(:auto_update_client) ? "true" : "false"
        pub_config[:deleteChefConfig] = locate_config_value(:delete_chef_extension_config) ? "true" : "false"
        pub_config[:custom_json_attr] = locate_config_value(:json_attributes) || {}

        # bootstrap attributes
        pub_config[:bootstrap_options] = {}
        pub_config[:bootstrap_options][:environment] = locate_config_value(:environment) if locate_config_value(:environment)
        pub_config[:bootstrap_options][:chef_node_name] = config[:chef_node_name] if config[:chef_node_name]
        pub_config[:bootstrap_options][:encrypted_data_bag_secret] = locate_config_value(:encrypted_data_bag_secret) if locate_config_value(:encrypted_data_bag_secret)
        pub_config[:bootstrap_options][:chef_server_url] = Chef::Config[:chef_server_url] if Chef::Config[:chef_server_url]
        pub_config[:bootstrap_options][:validation_client_name] = Chef::Config[:validation_client_name] if Chef::Config[:validation_client_name]
        pub_config[:bootstrap_options][:node_verify_api_cert] = locate_config_value(:node_verify_api_cert) ? "true" : "false" if config.key?(:node_verify_api_cert)
        pub_config[:bootstrap_options][:bootstrap_version] = locate_config_value(:bootstrap_version) if locate_config_value(:bootstrap_version)
        pub_config[:bootstrap_options][:node_ssl_verify_mode] = locate_config_value(:node_ssl_verify_mode) if locate_config_value(:node_ssl_verify_mode)
        pub_config[:bootstrap_options][:bootstrap_proxy] = locate_config_value(:bootstrap_proxy) if locate_config_value(:bootstrap_proxy)
        Base64.encode64(pub_config.to_json)
      end

      def get_chef_extension_private_params
        pri_config = Hash.new

        # validator less bootstrap support for bootstrap protocol cloud-api
        if (Chef::Config[:validation_key] && !File.exist?(File.expand_path(Chef::Config[:validation_key])))

          if Chef::VERSION.split('.').first.to_i == 11
            ui.error('Unable to find validation key. Please verify your configuration file for validation_key config value.')
            exit 1
          end

          client_builder = Chef::Knife::Bootstrap::ClientBuilder.new(
            chef_config: Chef::Config,
            knife_config: config,
            ui: ui,
          )

          client_builder.run
          key_path = client_builder.client_path
          pri_config[:client_pem] = File.read(key_path)
        else
          pri_config[:validation_key] = File.read(Chef::Config[:validation_key])
        end

        # SSL cert bootstrap support
        if locate_config_value(:cert_path)
          if File.exist?(File.expand_path(locate_config_value(:cert_path)))
            pri_config[:chef_server_crt] = File.read(locate_config_value(:cert_path))
          else
            ui.error('Specified SSL certificate does not exist.')
            exit 1
          end
        end
        Base64.encode64(pri_config.to_json)
      end

    end
  end
end