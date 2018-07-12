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
require 'chef/knife/bootstrap/common_bootstrap_options'
require 'chef/knife/bootstrap/bootstrapper'
require 'azure/resource_management/ARM_interface'

class Chef
  class Knife
    class BootstrapAzurerm < Knife
      include Knife::AzurermBase
      include Knife::Bootstrap::CommonBootstrapOptions
      include Knife::Bootstrap::Bootstrapper

      banner "knife bootstrap azurerm SERVER (options)"

      deps do
        require 'time'
      end

      option :azure_service_location,
        :short => "-m LOCATION",
        :long => "--azure-service-location LOCATION",
        :description => "Required if not using an Affinity Group. Specifies the geographic location - the name of the data center location that is valid for your subscription.
                                      Eg: westus, eastus, eastasia, southeastasia, northeurope, westeurope",
        :proc        => Proc.new { |lo| Chef::Config[:knife][:azure_service_location] = lo }

      def run
        ui.log("Validating...")
        validate_arm_keys!(:azure_resource_group_name, :azure_service_location)

        begin
          if @name_args.length == 1
            ui.log("Creating VirtualMachineExtension....")
            ext_params = set_ext_params
            vm_extension = service.create_vm_extension(ext_params)
            if vm_extension
              if ext_params[:chef_extension_public_param][:extendedLogs] == 'true'
                service.fetch_chef_client_logs(ext_params[:azure_resource_group_name], ext_params[:azure_vm_name], ext_params[:chef_extension], Time.now)
              end
              ui.log("VirtualMachineExtension creation successfull.")
              ui.log("Virtual Machine Extension name is: #{vm_extension.name}")
              ui.log("Virtual Machine Extension ID is: #{vm_extension.id}")
            end
          else
            raise ArgumentError, 'Please specify the SERVER name which needs to be bootstrapped via the Chef Extension.' if @name_args.length == 0
            raise ArgumentError, 'Please specify only one SERVER name which needs to be bootstrapped via the Chef Extension.' if @name_args.length > 1
          end
        rescue => error
          service.common_arm_rescue_block(error)
        end
      end

      def set_ext_params
        server = service.find_server(locate_config_value(:azure_resource_group_name), name_args[0])

        if server
          if service.extension_already_installed?(server)
            raise "Virtual machine #{server.name} already has Chef extension installed on it."
          else
            ext_params = Hash.new
            case server.storage_profile.os_disk.os_type.downcase
            when 'windows'
              ext_params[:chef_extension] = 'ChefClient'
            when 'linux'
              if ['ubuntu', 'debian', 'rhel', 'centos'].any? { |platform| server.storage_profile.image_reference.offer.downcase.include? platform }
                ext_params[:chef_extension] = 'LinuxChefClient'
              else
                raise "Offer #{server.storage_profile.image_reference.offer} is not supported in the extension."
              end
            else
              raise "OS type #{server.storage_profile.os_disk.os_type} is not supported."
            end

            ext_params[:azure_resource_group_name] = locate_config_value(:azure_resource_group_name)
            ext_params[:azure_vm_name] = @name_args[0]
            ext_params[:azure_service_location] = locate_config_value(:azure_service_location)
            ext_params[:chef_extension_publisher] = get_chef_extension_publisher
            ext_params[:chef_extension_version] = get_chef_extension_version(ext_params[:chef_extension])
            ext_params[:chef_extension_public_param] = get_chef_extension_public_params
            ext_params[:chef_extension_private_param] = get_chef_extension_private_params
          end
        else
          raise "The given server '#{@name_args[0]}' does not exist under resource group '#{locate_config_value(:azure_resource_group_name)}'"
        end

        ext_params
      end

    end
  end
end
