#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2009-2011 Opscode, Inc.
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

require File.expand_path('../azure_base', __FILE__)

# These two are needed for the '--purge' deletion case
require 'chef/node'
require 'chef/api_client'

class Chef
  class Knife
    class AzurermServerDelete < Knife

      include Knife::AzureBase

      banner "knife azurerm server delete SERVER [SERVER] (options)"

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the Windows Azure node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."

      # Extracted from Chef::Knife.delete_object, because it has a
      # confirmation step built in... By specifying the '--purge'
      # flag (and also explicitly confirming the server destruction!)
      # the user is already making their intent known.  It is not
      # necessary to make them confirm two more times.

      def run
        begin
          $stdout.sync = true
          validate_arm_keys!(:azure_resource_group_name)

          vm_name = @name_args[0]
          service_arm.delete_server(locate_config_value(:azure_resource_group_name), vm_name, custom_headers = nil)

          if config[:purge]
            node_to_delete = config[:chef_node_name] || vm_name
            if node_to_delete
              destroy_item(Chef::Node, node_to_delete, 'node')
              destroy_item(Chef::ApiClient, node_to_delete, 'client')
            else
              ui.warn("Node name to purge not provided. Corresponding client node will remain on Chef Server.")
            end
          else
            ui.warn("Corresponding node and client for the #{vm_name} server were not deleted and remain registered with the Chef Server")
          end
        rescue => error
          if error.class == MsRestAzure::AzureOperationError && error.body
            if error.body['error']['code'] == 'ResourceNotFound'
              ui.error("#{error.body['error']['message']}")
            else
              ui.error(error.body)
            end
          else
            ui.error("#{error.message}")
            ui.error("#{error.backtrace.join("\n")}")
          end
        end
      end
    end
  end
end
