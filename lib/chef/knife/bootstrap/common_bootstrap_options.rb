#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
#
# Copyright:: Copyright (c) 2016 Opscode, Inc.
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
#
# Bootstrap options listed here are supported only for cloud-api protocol ARM mode.
#

class Chef
  class Knife
    class Bootstrap
      module CommonBootstrapOptions

        def self.included(includer)
          includer.class_eval do

            deps do
              require 'chef/knife/bootstrap'
              Chef::Knife::Bootstrap.load_deps
            end

            option :chef_node_name,
              :short => "-N NAME",
              :long => "--node-name NAME",
              :description => "The Chef node name for your new node"

            option :bootstrap_version,
              :long => "--bootstrap-version VERSION",
              :description => "The version of Chef to install",
              :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

            option :run_list,
              :short => "-r RUN_LIST",
              :long => "--run-list RUN_LIST",
              :description => "Comma separated list of roles/recipes to apply",
              :proc => lambda { |o| o.split(/[\s,]+/) },
              :default => []

            option :json_attributes,
              :short => "-j JSON",
              :long => "--json-attributes JSON",
              :description => "A JSON string to be added to the first run of chef-client",
              :proc => lambda { |o| JSON.parse(o) }

            option :bootstrap_proxy,
              :long => "--bootstrap-proxy PROXY_URL",
              :description => "The proxy server for the node being bootstrapped",
              :proc => Proc.new { |p| Chef::Config[:knife][:bootstrap_proxy] = p }

            option :cert_path,
              :long => "--cert-path PATH",
              :description => "SSL Certificate Path"

            option :node_ssl_verify_mode,
              :long        => "--node-ssl-verify-mode [peer|none]",
              :description => "Whether or not to verify the SSL cert for all HTTPS requests.",
              :proc        => Proc.new { |v|
                valid_values = ["none", "peer"]
                unless valid_values.include?(v)
                  raise "Invalid value '#{v}' for --node-ssl-verify-mode. Valid values are: #{valid_values.join(", ")}"
                end
              }

            option :node_verify_api_cert,
              :long        => "--[no-]node-verify-api-cert",
              :description => "Verify the SSL cert for HTTPS requests to the Chef server API.",
              :boolean     => true

            option :azure_extension_client_config,
              :long => "--azure-extension-client-config CLIENT_PATH",
              :description => "Optional. Path to a client.rb file for use by the bootstrapped node."

            option :encrypted_data_bag_secret,
              :short => "-s SECRET",
              :long  => "--secret ",
              :description => "The secret key to use to encrypt data bag item values.  Can also be defaulted in your config with the key 'secret'"

            option :encrypted_data_bag_secret_file,
              :long => "--secret-file SECRET_FILE",
              :description => "A file containing the secret key to use to encrypt data bag item values.  Can also be defaulted in your config with the key 'secret_file'"

            option :extended_logs,
              :long => "--extended-logs",
              :boolean => true,
              :default => false,
              :description => "Optional. It shows chef convergence logs in detail."

            option :chef_service_interval,
              :long => "--chef-service-interval INTERVAL",
              :description => "Optional. It specifies the frequency (in minutes) at which the chef-service runs.
                                Pass 0 if you don't want the chef-service to be installed on the target machine."

            option :daemon,
              :long => "--daemon DAEMON",
              :description => "Optional, Provide this option when --bootstrap-protocol is set to 'cloud-api'. Works only for Windows node.
                                Options: 'auto' or 'service' or 'task'.
                                auto - This will not run the chef-client as service or scheduled-task both on node.
                                service - This will install and run the chef-client as service on node.
                                task - This will install and run the chef-client as scheduled-task on node."

          end
        end
      end
    end
  end
end

