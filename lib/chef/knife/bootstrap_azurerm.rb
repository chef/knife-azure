#
# Author:: Nimisha Sharad (nimisha.sharad@clogeny.com)
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

require 'chef/knife/azurerm_base'
require 'chef/knife/bootstrap/azurerm_bootstrap_options'
require 'chef/knife/bootstrap/bootstrapper'

class Chef
  class Knife
    class BootstrapAzurerm < Knife
      include Knife::AzurermBase
      include Knife::Bootstrap::AzurermBootstrapOptions
      include Knife::Bootstrap::Bootstrapper

      banner "knife bootstrap azurerm SERVER (options)"

      option :azure_vm_name,
        :long => "--azure-vm-name NAME",
        :description => "Required. Specifies the name for the virtual machine.
                        The name must be unique within the ResourceGroup.
                        The azure vm name cannot be more than 15 characters long"

      option :azure_service_location,
        :short => "-m LOCATION",
        :long => "--azure-service-location LOCATION",
        :description => "Required if not using an Affinity Group. Specifies the geographic location - the name of the data center location that is valid for your subscription.
                                      Eg: West US, East US, East Asia, Southeast Asia, North Europe, West Europe",
        :proc        => Proc.new { |lo| Chef::Config[:knife][:azure_service_location] = lo }

      def run
        Chef::Log.info("Validating...")
        validate_arm_keys!(:azure_resource_group_name, :azure_service_location)

        begin
           if @name_args.length == 1
            Chef::Log.info("Creating VirtualMachineExtension....")
            vm_extension = service.create_vm_extension(set_ext_params)
            Chef::Log.info("VirtualMachineExtension creation successfull.")
            Chef::Log.info("Virtual Machine Extension name is: #{vm_extension.name}")
            Chef::Log.info("Virtual Machine Extension ID is: #{vm_extension.id}")
           else
             raise ArgumentError, 'Please specify the SERVER name which needs to be bootstrapped via the Chef Extension.' if @name_args.length == 0
             raise ArgumentError, 'Please specify only one SERVER name which needs to be bootstrapped via the Chef Extension.' if @name_args.length > 1
           end
         rescue => error
           ui.error("#{error.message}")
           Chef::Log.debug("#{error.backtrace.join("\n")}")
           exit
         end
      end

      def set_ext_params
        begin
          server = service.find_server(locate_config_value(:azure_resource_group_name), name_args[0])

          ext_params = Hash.new
          case server.properties.storage_profile.os_disk.os_type.downcase
          when 'windows'
            ext_params[:chef_extension] = 'ChefClient'
          when 'linux'
            ext_params[:chef_extension] = 'LinuxChefClient'
          else
            raise "OS type #{server.os_type} is not supported."
          end

          ext_params[:azure_resource_group_name] = locate_config_value(:azure_resource_group_name)
          ext_params[:azure_vm_name] = @name_args[0]
          ext_params[:azure_service_location] = locate_config_value(:azure_service_location)
          ext_params[:chef_extension_publisher] = get_chef_extension_publisher
          ext_params[:chef_extension_version] = get_chef_extension_version(ext_params[:chef_extension])
          ext_params[:chef_extension_public_param] = get_chef_extension_public_params
          ext_params[:chef_extension_private_param] = get_chef_extension_private_params
        rescue => error
          ui.error("#{error.message}")
          Chef::Log.debug("#{error.backtrace.join("\n")}")
          exit
        end

        ext_params
      end

    end
  end
end