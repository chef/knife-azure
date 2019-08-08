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

require File.expand_path("../azure_base", __FILE__)

# These two are needed for the '--purge' deletion case
require "chef/node"
require "chef/api_client"

class Chef
  class Knife
    class AzureServerDelete < Knife

      include Knife::AzureBase

      banner "knife azure server delete SERVER [SERVER] (options)"

      option :preserve_azure_os_disk,
        long: "--preserve-azure-os-disk",
        boolean: true,
        default: false,
        description: "Preserve corresponding OS Disk"

      option :preserve_azure_vhd,
        long: "--preserve-azure-vhd",
        boolean: true,
        default: false,
        description: "Preserve underlying VHD"

      option :purge,
        short: "-P",
        long: "--purge",
        boolean: true,
        default: false,
        description: "Destroy corresponding node and client on the Chef Server, in addition to destroying the Windows Azure node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        short: "-N NAME",
        long: "--node-name NAME",
        description: "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."

      option :preserve_azure_dns_name,
        long: "--preserve-azure-dns-name",
        boolean: true,
        default: false,
        description: "Preserve corresponding cloud service (DNS). If the option is not set, it deletes the service not used by any VMs."

      option :delete_azure_storage_account,
        long: "--delete-azure-storage-account",
        boolean: true,
        default: false,
        description: "Delete corresponding storage account. If the option is set, it deletes the storage account not used by any VMs."

      option :azure_dns_name,
        long: "--azure-dns-name NAME",
        description: "specifies the DNS name (also known as hosted service name)"

      option :wait,
        long: "--wait",
        boolean: true,
        default: false,
        description: "Wait for server deletion. Default is false"

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
        ui.warn("Could not find a #{type_name} named #{name} to delete. Please provide --node-name option and it's value")
      end

      def validate_disk_and_storage
        if locate_config_value(:preserve_azure_os_disk) && locate_config_value(:delete_azure_storage_account)
          ui.warn("Cannot delete storage account while keeping OS Disk. Please set any one option.")
          exit
        else
          true
         end
      end

      def run
        validate_asm_keys!
        validate_disk_and_storage
        @name_args.each do |name|
          begin
            service.delete_server( { name: name, preserve_azure_os_disk: locate_config_value(:preserve_azure_os_disk),
                                     preserve_azure_vhd: locate_config_value(:preserve_azure_vhd),
                                     preserve_azure_dns_name: locate_config_value(:preserve_azure_dns_name),
                                     delete_azure_storage_account: locate_config_value(:delete_azure_storage_account),
                                     wait: locate_config_value(:wait) } )

            if config[:purge]
              node_to_delete = config[:chef_node_name] || name
              if node_to_delete
                destroy_item(Chef::Node, node_to_delete, "node")
                destroy_item(Chef::ApiClient, node_to_delete, "client")
              else
                ui.warn("Node name to purge not provided. Corresponding client node will remain on Chef Server.")
              end
            else
              ui.warn("Corresponding node and client for the #{name} server were not deleted and remain registered with the Chef Server")
            end

          rescue Exception => ex
            ui.error("#{ex.message}")
            ui.error("#{ex.backtrace.join("\n")}")
          end
        end
      end
    end
  end
end
