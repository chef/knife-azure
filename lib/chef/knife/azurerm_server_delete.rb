#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright 2010-2019, Chef Software Inc.
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

require File.expand_path("../azurerm_base", __FILE__)

# These two are needed for the '--purge' deletion case
require "chef/node"
require "chef/api_client"

class Chef
  class Knife
    class AzurermServerDelete < Knife

      include Knife::AzurermBase

      banner "knife azurerm server delete SERVER [SERVER] (options)"

      option :purge,
        short: "-P",
        long: "--purge",
        boolean: true,
        default: false,
        description: "Destroy corresponding node and client on the Chef Server, in addition to destroying the Windows Azure node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        short: "-N NAME",
        long: "--node-name NAME",
        description: "The name of the node and client to delete, if it differs from the server name. Only has meaning when used with the '--purge' option."

      option :delete_resource_group,
        long: "--delete-resource-group",
        boolean: true,
        default: false,
        description: "Deletes corresponding resource group along with Vitual Machine."

      # Extracted from Chef::Knife.delete_object, because it has a
      # confirmation step built in... By specifying the '--purge'
      # flag (and also explicitly confirming the server destruction!)
      # the user is already making their intent known.  It is not
      # necessary to make them confirm two more times.

      def destroy_item(klass, name, type_name)
        object = klass.load(name)
        object.destroy
        ui.warn("Deleted #{type_name} #{name}")
      rescue Net::HTTPServerException
        ui.warn("Could not find a #{type_name} named #{name} to delete!")
      end

      def run
        $stdout.sync = true
        # check azure cli version due to azure changed `azure` to `az` in azure-cli2.0
        get_azure_cli_version
        validate_arm_keys!(:azure_resource_group_name)
        @vm_name = @name_args[0]

        if locate_config_value(:delete_resource_group)
          delete_resource_group
        else
          service.delete_server(locate_config_value(:azure_resource_group_name), @vm_name)
        end

        if config[:purge]
          purge_node
        else
          ui.warn("Corresponding node and client for the #{@vm_name} server were not deleted and remain registered with the Chef Server")
        end
      rescue => error
        service.common_arm_rescue_block(error)
      end

      def delete_resource_group
        resource_group_name = locate_config_value(:azure_resource_group_name)
        ui.warn "Deleting resource group will delete all the virtual_machines inside it."
        begin
          ui.confirm("Do you really want to delete resource group")
        rescue SystemExit   # Need to handle this as confirming with N/n raises SystemExit exception
          server = nil      # Cleanup is implicitly performed in other cloud plugins
          ui.warn "Resource group not deleted. Proceeding for server delete ..."
          service.delete_server(locate_config_value(:azure_resource_group_name), @vm_name)
          exit
        end
        ui.info "Deleting Resource Group " + resource_group_name + " and Virtual Machine " + @vm_name + " .."
        service.delete_resource_group(locate_config_value(:azure_resource_group_name))
        ui.warn "Deleted resource_group_name #{resource_group_name} and #{@vm_name}"
      end

      def purge_node
        node_to_delete = config[:chef_node_name] || @vm_name
        if node_to_delete
          destroy_item(Chef::Node, node_to_delete, "node")
          destroy_item(Chef::ApiClient, node_to_delete, "client")
        else
          ui.warn("Node name to purge not provided. Corresponding client node will remain on Chef Server.")
        end
      end
    end
  end
end
