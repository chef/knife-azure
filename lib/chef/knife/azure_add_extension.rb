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

require 'chef/knife/azure_base'
require 'chef/knife/azure_extension_base'
require 'chef/knife/knife_windows_base'

class Chef
  class Knife
    class AzureAddExtension < Knife

      include Chef::Knife::AzureBase
      include Chef::Knife::AzureExtensionBase
      include Chef::Knife::KnifeWindowsBase

      banner "knife azure chef extension (options)"

      option :azure_dns_name,
        :short => "-d DNS_NAME",
        :long => "--azure-dns-name DNS_NAME",
        :description => "The DNS prefix name that is used to access the cloud service to execute particular Chef Extension operation under an existing virtual machine of that cloud service/deployment.",
        :required => true

      option :azure_vm_name,
        :long => "--azure-vm-name NAME",
        :description => "The virtual machine name on which the particular Chef Extension operation needs to be executed.",
        :required => true

      option :operation,
        :short => "-op",
        :long => "--operation EXTENSION_OPERATION",
        :description => "The extension operation to be performed on the existing node. Valid choices are [add, remove, enable, disable]",
        :default => "add"


      def run
      	Chef::Log.info("Validating...")
      	validate!

      	case locate_config_value(:operation)
      	when "add"
      	  add_extension
      	when "remove"
      	  ##TODO Remove_Extension
      	when "enable"
      	  ##TODO Enable_Extension
      	when "disable"
      	  ##TODO Disable_Extension
      	else
      	  puts "Invalid option...Try again !!"
      	  exit 1
      	end
      end

      def validate!
        super([
          :azure_subscription_id,
          :azure_mgmt_cert,
          :azure_api_host_name,
          :azure_source_image,
          :azure_vm_size,
        ])
      end

      def add_extension
        params[:pub_config] = get_chef_extension_public_params
      	params[:pri_config] = get_chef_extension_private_params
      	deployment_name = connection.deploys.get_deploy_name_for_hostedservice(locate_config_value(:azure_dns_name))
      	update_role(params, deployment_name, locate_config_value(:azure_vm_name))
      end

      def update_role(params, deployment_name, role_name)
        role = Role.new
        role.find_in_hosted_service(role_name, deployment_name)
        ##TODO
      end

    end
  end
end
