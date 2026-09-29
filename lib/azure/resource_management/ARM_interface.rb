#
# Copyright:: Copyright (c) 2012-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../azure_interface"
require_relative "ARM_deployment_template"
require_relative "vnet_config"
require_relative "rest/environments"
require_relative "rest/errors"
require_relative "rest/token_provider"
require_relative "rest/http"
require_relative "rest/arm_client"

module Azure
  class ResourceManagement
    class ARMInterface < AzureInterface
      include Azure::ARM::ARMDeploymentTemplate
      include Azure::ARM::VnetConfig

      # Backwards-compatible alias so existing rescue clauses and consumers can
      # keep referring to a single error type for Azure API failures.
      OperationError = Azure::ResourceManagement::Rest::OperationError

      attr_accessor :connection

      def initialize(params = {})
        @environment = Azure::ResourceManagement::Rest::Environments.default
        @token_provider = Azure::ResourceManagement::Rest::TokenProvider.new(params, @environment)
        @azure_subscription_id = params[:azure_subscription_id]
        super
      end

      def arm_client
        @arm_client ||= begin
          http = Azure::ResourceManagement::Rest::Http.new(@token_provider)
          Azure::ResourceManagement::Rest::ArmClient.new(@azure_subscription_id, http, @environment)
        end
      end

      def list_images; end

      def list_servers(resource_group_name = nil)
        servers = if resource_group_name.nil?
                    arm_client.list_all_virtual_machines
                  else
                    arm_client.list_virtual_machines(resource_group_name)
                  end

        cols = ["VM Name", "Resource Group Name", "Location", "Provisioning State", "OS Type"]
        rows = []

        servers.each do |server|
          rows << server.name.to_s
          rows << server.id.split("/")[4].downcase
          rows << server.location.to_s
          rows << begin
                           state = server.provisioning_state.to_s.downcase
                           case state
                           when "failed"
                             ui.color(state, :red)
                           when "succeeded"
                             ui.color(state, :green)
                           else
                             ui.color(state, :yellow)
                           end
                         end
          rows << server.storage_profile.os_disk.os_type.to_s
        end
        display_list(ui, cols, rows)
      end

      def delete_server(resource_group_name, vm_name)
        server = arm_client.get_virtual_machine(resource_group_name, vm_name)
        if server && server.name == vm_name
          puts "\n\n"
          msg_pair(ui, "VM Name", server.name)
          msg_pair(ui, "VM Size", server.hardware_profile.vm_size)
          msg_pair(ui, "VM OS", server.storage_profile.os_disk.os_type)
          puts "\n"

          begin
            ui.confirm("Do you really want to delete this server")
          rescue SystemExit   # Need to handle this as confirming with N/n raises SystemExit exception
            server = nil      # Cleanup is implicitly performed in other cloud plugins
            exit!
          end

          ui.info "Deleting .."

          arm_client.delete_virtual_machine(resource_group_name, vm_name)

          puts "\n"
          ui.warn "Deleted server #{vm_name}"
        end
      end

      def show_server(name, resource_group)
        server = find_server(resource_group, name)
        if server
          network_interface_name = server.network_profile.network_interfaces[0].id.split("/")[-1]
          network_interface_data = arm_client.get_network_interface(resource_group, network_interface_name)
          public_ip_id_data = network_interface_data.ip_configurations[0].public_ipaddress
          if public_ip_id_data.nil?
            public_ip_data = nil
          else
            public_ip_name = public_ip_id_data.id.split("/")[-1]
            public_ip_data = arm_client.get_public_ip_address(resource_group, public_ip_name)
          end

          details = []
          details << ui.color("Server Name", :bold, :cyan)
          details << server.name

          details << ui.color("Size", :bold, :cyan)
          details << server.hardware_profile.vm_size

          details << ui.color("Provisioning State", :bold, :cyan)
          details << server.provisioning_state

          details << ui.color("Location", :bold, :cyan)
          details << server.location

          details << ui.color("Publisher", :bold, :cyan)
          details << server.storage_profile.image_reference.publisher

          details << ui.color("Offer", :bold, :cyan)
          details << server.storage_profile.image_reference.offer

          details << ui.color("Sku", :bold, :cyan)
          details << server.storage_profile.image_reference.sku

          details << ui.color("Version", :bold, :cyan)
          details << server.storage_profile.image_reference.version

          details << ui.color("OS Type", :bold, :cyan)
          details << server.storage_profile.os_disk.os_type

          details << ui.color("Public IP address", :bold, :cyan)
          details << if public_ip_data.nil?
                       " -- "
                     else
                       public_ip_data.ip_address
                     end

          details << ui.color("FQDN", :bold, :cyan)
          details << if public_ip_data.nil? || public_ip_data.dns_settings.nil?
                       " -- "
                     else
                       public_ip_data.dns_settings.fqdn
                     end

          puts ui.list(details, :columns_across, 2)
        end
      end

      def find_server(resource_group, name)
        arm_client.get_virtual_machine(resource_group, name)
      end

      def virtual_machine_exist?(resource_group_name, vm_name)
        arm_client.get_virtual_machine(resource_group_name, vm_name)
        true
      rescue OperationError => e
        if e.body
          err_json = JSON.parse(e.response.body)
          if err_json["error"]["code"] == "ResourceNotFound"
            false
          else
            raise e
          end
        end
      end

      def security_group_exist?(resource_group_name, security_group_name)
        arm_client.get_network_security_group(resource_group_name, security_group_name)
        true
      rescue OperationError => e
        if e.body
          err_json = JSON.parse(e.response.body)
          if err_json["error"]["code"] == "ResourceNotFound"
            false
          else
            raise e
          end
        end
      end

      # Returns the sku name (e.g. "Aligned") of an existing availability set, nil if it
      # exists but is a legacy "Classic" set (which has no sku property at all), or the
      # :not_found symbol if it doesn't exist yet. Used to detect the case where a caller
      # reuses an existing Classic availability set name: since Azure availability set
      # SKUs are immutable once created, redeploying it as "Aligned" (required for managed
      # disks) would fail remotely with a cryptic ARM error instead of the actionable one
      # raised in validate_params!.
      def existing_availability_set_sku(resource_group_name, availability_set_name)
        availability_set = arm_client.get_availability_set(resource_group_name, availability_set_name)
        availability_set.sku && availability_set.sku.name
      rescue OperationError => e
        if e.body
          err_json = JSON.parse(e.response.body)
          # ResourceNotFound: the resource group exists but the availability set doesn't.
          # ResourceGroupNotFound: the resource group itself doesn't exist yet (e.g. when
          # creating a VM + availability set together in a brand-new resource group).
          # Both mean "no existing availability set to conflict with".
          return :not_found if %w{ResourceNotFound ResourceGroupNotFound}.include?(err_json["error"]["code"])
        end
        raise e
      end

      def resource_group_exist?(resource_group_name)
        arm_client.resource_group_exist?(resource_group_name)
      end

      def platform(image_reference)
        @platform ||= begin
          platform = if image_reference =~ /WindowsServer.*/
                       "Windows"
                     else
                       "Linux"
                     end
          platform
        end
      end

      def parse_substatus_code(code, index)
        code.split("/")[index]
      end

      def fetch_substatus(resource_group_name, virtual_machine_name, chef_extension_name)
        substatuses = arm_client.get_vm_extension(
          resource_group_name,
          virtual_machine_name,
          chef_extension_name,
          expand: "instanceView"
        ).instance_view.substatuses

        return nil if substatuses.nil?

        substatuses.each do |substatus|
          if parse_substatus_code(substatus.code, 1) == "Chef Client run logs"
            return substatus
          end
        end

        nil
      end

      def fetch_chef_client_logs(resource_group_name, virtual_machine_name, chef_extension_name, fetch_process_start_time, fetch_process_wait_timeout = 30)
        ## fetch substatus field which contains the chef-client run logs ##
        substatus = fetch_substatus(resource_group_name, virtual_machine_name, chef_extension_name)

        if substatus.nil?
          ## unavailability of the substatus field indicates that chef-client run is not completed yet on the server ##
          fetch_process_wait_time = ((Time.now - fetch_process_start_time) / 60).round
          if fetch_process_wait_time <= fetch_process_wait_timeout
            print ui.color(".", :bold).to_s
            sleep 30
            fetch_chef_client_logs(resource_group_name, virtual_machine_name, chef_extension_name, fetch_process_start_time, fetch_process_wait_timeout)
          else
            ## wait time exceeded 30 minutes timeout ##
            ui.error "\nchef-client run logs could not be fetched since fetch process exceeded wait timeout of #{fetch_process_wait_timeout} minutes.\n"
          end
        else
          ## chef-client run logs becomes available ##
          status = parse_substatus_code(substatus.code, 2)
          message = substatus.message

          puts "\n\n******** Please find the chef-client run details below ********\n\n"
          print "----> chef-client run status: "
          case status
          when "succeeded"
            ## chef-client run succeeded ##
            color = :green
          when "failed"
            ## chef-client run failed ##
            color = :red
          when "transitioning"
            ## chef-client run did not complete within maximum timeout of 30 minutes ##
            ## fetch whatever logs available under the chef-client.log file ##
            color = :yellow
          end
          puts ui.color(status, color, :bold).to_s
          puts "----> chef-client run logs: "
          puts "\n#{message}\n" ## message field of substatus contains the chef-client run logs ##
        end
      end

      def create_server(params = {})
        platform(params[:azure_image_reference_offer])
        # resource group creation
        if resource_group_exist?(params[:azure_resource_group_name])
          ui.log("INFO:Resource Group #{params[:azure_resource_group_name]} already exist. Skipping its creation.")
          ui.log("INFO:Adding new VM #{params[:azure_vm_name]} to this resource group.")
        else
          ui.log("Creating ResourceGroup....\n\n")
          resource_group = create_resource_group(params)
          Chef::Log.info("ResourceGroup creation successful.")
          Chef::Log.info("Resource Group name is: #{resource_group.name}")
          Chef::Log.info("Resource Group ID is: #{resource_group.id}")
        end

        # virtual machine creation
        if virtual_machine_exist?(params[:azure_resource_group_name], params[:azure_vm_name])
          ui.log("INFO:Virtual Machine #{params[:azure_vm_name]} already exist under the Resource Group #{params[:azure_resource_group_name]}. Exiting for now.")
        else
          params[:chef_extension_version] = params[:chef_extension_version].nil? ? get_latest_chef_extension_version(params) : params[:chef_extension_version]
          params[:vm_size] = params[:azure_vm_size]
          params[:vnet_config] = create_vnet_config(
            params[:azure_resource_group_name],
            params[:azure_vnet_name],
            params[:azure_vnet_subnet_name]
          )
          if params[:tcp_endpoints]
            params[:tcp_endpoints] = if @platform == "Windows"
                                       params[:tcp_endpoints] + ",3389"
                                     else
                                       params[:tcp_endpoints] + ",22,16001"
                                     end
            random_no = rand(100..1000)
            params[:azure_sec_group_name] = params[:azure_vm_name] + "_sec_grp_" + random_no.to_s
            if security_group_exist?(params[:azure_resource_group_name], params[:azure_sec_group_name])
              random_no = rand(100..1000)
              params[:azure_sec_group_name] = params[:azure_vm_name] + "_sec_grp_" + random_no.to_s
            end
          end

          ui.log("Creating Virtual Machine....")
          deployment = create_virtual_machine_using_template(params)
          ui.log("Virtual Machine creation successful.") unless deployment.nil?

          unless deployment.nil?
            ui.log("Deployment name is: #{deployment.name}")
            ui.log("Deployment ID is: #{deployment.id}")
            deployment.properties.dependencies.each do |deploy|
              next unless deploy.resource_type == "Microsoft.Compute/virtualMachines"

              if params[:chef_extension_public_param][:extendedLogs] == "true"
                print "\n\nWaiting for the first chef-client run on virtual machine #{deploy.resource_name}"
                fetch_chef_client_logs(params[:azure_resource_group_name],
                  deploy.resource_name,
                  params[:chef_extension],
                  Time.now)
              end

              ui.log("VM Details ...")
              ui.log("-------------------------------")
              ui.log("Virtual Machine name is: #{deploy.resource_name}")
              ui.log("Virtual Machine ID is: #{deploy.id}")
              show_server(deploy.resource_name, params[:azure_resource_group_name])
            end
          end
        end
      end

      def create_resource_group(params = {})
        begin
          resource_group = arm_client.create_resource_group(
            params[:azure_resource_group_name],
            params[:azure_service_location]
          )
        rescue Exception => e
          Chef::Log.error("Failed to create the Resource Group -- exception being rescued: #{e}")
          common_arm_rescue_block(e)
        end

        resource_group
      end

      def create_virtual_machine_using_template(params)
        template = create_deployment_template(params)
        parameters = create_deployment_parameters(params)

        deployment_body = {
          "properties" => {
            "template" => template,
            "parameters" => parameters,
            "mode" => "Incremental",
          },
        }

        arm_client.create_deployment(params[:azure_resource_group_name], "#{params[:azure_vm_name]}_deploy", deployment_body)
      end

      def create_vm_extension(params)
        extension_name = params[:chef_extension]
        extension_body = {
          "name" => extension_name,
          "location" => params[:azure_service_location],
          "properties" => {
            "publisher" => params[:chef_extension_publisher],
            "type" => extension_name,
            "typeHandlerVersion" => params[:chef_extension_version].nil? ? get_latest_chef_extension_version(params) : params[:chef_extension_version],
            "autoUpgradeMinorVersion" => false,
            "settings" => params[:chef_extension_public_param],
            "protectedSettings" => params[:chef_extension_private_param],
          },
        }

        begin
          vm_extension = arm_client.create_vm_extension(
            params[:azure_resource_group_name],
            params[:azure_vm_name],
            extension_name,
            extension_body
          )
        rescue Exception => e
          Chef::Log.error("Failed to create the Virtual Machine Extension -- exception being rescued.")
          common_arm_rescue_block(e)
        end

        vm_extension
      end

      def extension_already_installed?(server)
        if server.resources
          server.resources.each do |extension|
            return true if extension.virtual_machine_extension_type == "ChefClient" || extension.virtual_machine_extension_type == "LinuxChefClient"
          end
        end
        false
      end

      def get_latest_chef_extension_version(params)
        ext_version = arm_client.list_vm_extension_versions(
          params[:azure_service_location],
          params[:chef_extension_publisher],
          params[:chef_extension]
        ).last.name
        ext_version_split_values = ext_version.split(".")
        ext_version_split_values[0] + "." + ext_version_split_values[1]
      end

      def delete_resource_group(resource_group_name)
        ui.info "Resource group deletion takes some time. Please wait ..."

        arm_client.delete_resource_group(resource_group_name)
        puts "\n"
      end

      def common_arm_rescue_block(error)
        if error.is_a?(OperationError) && error.body
          err_json = JSON.parse(error.response.body)
          arm_error = err_json["error"]
          if arm_error.is_a?(Hash)
            err_details = arm_error["details"]
            if err_details
              err_details.each do |err|
                ui.error(JSON.parse(err["message"])["error"]["message"])
              rescue JSON::ParserError => e
                ui.error(err["message"])
              end
            else
              ui.error(arm_error["message"])
            end
          else
            # OAuth token endpoint errors are flat: the "error" value is a
            # string code and the human-readable text is in "error_description".
            ui.error(err_json["error_description"] || arm_error || error.message)
          end
          Chef::Log.debug(error.response.body)
        else
          message = begin
                      JSON.parse(error.message)
                    rescue JSON::ParserError => e
                      error.message
                    end
          ui.error(message)
          Chef::Log.debug(message)
        end
      rescue Exception => e
        ui.error("Something went wrong. Please use -VV option for more details.")
        Chef::Log.debug(error.backtrace.join("\n").to_s)
      end
    end
  end
end
