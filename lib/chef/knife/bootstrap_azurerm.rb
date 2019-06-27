#
# Author:: Nimisha Sharad (nimisha.sharad@clogeny.com)
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

require "chef/knife/azurerm_base"
require "chef/knife/bootstrap"
require "chef/knife/bootstrap/common_bootstrap_options"
require "chef/knife/bootstrap/bootstrapper"
require "azure/resource_management/ARM_interface"
require "time"

class Chef
  class Knife
    class BootstrapAzurerm < Knife::Bootstrap
      include Knife::AzurermBase
      include Knife::Bootstrap::CommonBootstrapOptions
      include Knife::Bootstrap::Bootstrapper

      banner "knife bootstrap azurerm SERVER (options)"

      # run() would be executing from parent class
      # Chef::Knife::Bootstrap, defined in core.
      # Required methods have been overridden here
      #### run() execution begins ####

      def plugin_setup!; end

      def validate_name_args!; end

      def plugin_validate_options!
        ui.log("Validating...")
        validate_arm_keys!(:azure_resource_group_name, :azure_service_location)
      end

      def plugin_create_instance!
        if @name_args.length == 1
          ui.log("Creating VirtualMachineExtension....")
          ext_params = set_ext_params
          vm_extension = service.create_vm_extension(ext_params)
          if vm_extension
            if ext_params[:chef_extension_public_param][:extendedLogs] == "true"
              service.fetch_chef_client_logs(ext_params[:azure_resource_group_name], ext_params[:azure_vm_name], ext_params[:chef_extension], Time.now)
            end
            ui.log("VirtualMachineExtension creation successfull.")
            ui.log("Virtual Machine Extension name is: #{vm_extension.name}")
            ui.log("Virtual Machine Extension ID is: #{vm_extension.id}")
          end
        else
          raise ArgumentError, "Please specify the SERVER name which needs to be bootstrapped via the Chef Extension." if @name_args.empty?
          raise ArgumentError, "Please specify only one SERVER name which needs to be bootstrapped via the Chef Extension." if @name_args.length > 1
        end
      rescue StandardError => error
        service.common_arm_rescue_block(error)
      end

      def plugin_finalize; end

      # Following methods are not required
      #
      def connect!; end

      def register_client; end

      def render_template; end

      def upload_bootstrap(content); end

      def perform_bootstrap(bootstrap_path); end

      #### run() execution ends ####

      def set_ext_params
        server = service.find_server(locate_config_value(:azure_resource_group_name), name_args[0])

        if server
          if service.extension_already_installed?(server)
            raise "Virtual machine #{server.name} already has Chef extension installed on it."
          else
            ext_params = {}
            case server.storage_profile.os_disk.os_type.downcase
            when "windows"
              ext_params[:chef_extension] = "ChefClient"
            when "linux"
              if %w{ubuntu debian rhel centos}.any? { |platform| server.storage_profile.image_reference.offer.downcase.include? platform }
                ext_params[:chef_extension] = "LinuxChefClient"
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
