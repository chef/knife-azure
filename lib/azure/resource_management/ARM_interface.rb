#
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

require "azure/azure_interface"
require "azure/resource_management/ARM_deployment_template"
require "azure/resource_management/vnet_config"
require "azure_mgmt_resources"
require "azure_mgmt_compute"
require "azure_mgmt_storage"
require "azure_mgmt_network"

module Azure
  class ResourceManagement
    class ARMInterface < AzureInterface
      include Azure::ARM::ARMDeploymentTemplate
      include Azure::ARM::VnetConfig

      include Azure::Resources::Mgmt::V2018_05_01
      include Azure::Resources::Mgmt::V2018_05_01::Models

      include Azure::Compute::Mgmt::V2018_06_01
      include Azure::Compute::Mgmt::V2018_06_01::Models

      include Azure::Storage::Mgmt::V2018_07_01
      include Azure::Storage::Mgmt::V2018_07_01::Models

      include Azure::Network::Mgmt::V2018_08_01
      include Azure::Network::Mgmt::V2018_08_01::Models

      attr_accessor :connection

      def initialize(params = {})
        if params[:azure_client_secret]
          token_provider = MsRestAzure::ApplicationTokenProvider.new(params[:azure_tenant_id], params[:azure_client_id], params[:azure_client_secret])
        else
          token_provider = MsRest::StringTokenProvider.new(params[:token], params[:tokentype])
        end
        @credentials = MsRest::TokenCredentials.new(token_provider)
        @azure_subscription_id = params[:azure_subscription_id]
        super
      end

      def resource_management_client
        @resource_management_client ||= begin
          resource_management_client = ResourceManagementClient.new(@credentials)
          resource_management_client.subscription_id = @azure_subscription_id
          resource_management_client
        end
      end

      def compute_management_client
        @compute_management_client ||= begin
          compute_management_client = ComputeManagementClient.new(@credentials)
          compute_management_client.subscription_id = @azure_subscription_id
          compute_management_client
        end
      end

      def storage_management_client
        @storage_management_client ||= begin
          storage_management_client = StorageManagementClient.new(@credentials)
          storage_management_client.subscription_id = @azure_subscription_id
          storage_management_client
        end
      end

      def network_resource_client
        @network_resource_client ||= begin
          network_resource_client = NetworkManagementClient.new(@credentials)
          network_resource_client.subscription_id = @azure_subscription_id
          network_resource_client
        end
      end

      def list_images; end

      def list_servers(resource_group_name = nil)
        servers = if resource_group_name.nil?
                    compute_management_client.virtual_machines.list_all
                  else
                    compute_management_client.virtual_machines.list(resource_group_name)
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
        server = compute_management_client.virtual_machines.get(resource_group_name, vm_name)
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

          begin
            server_detail = compute_management_client.virtual_machines.delete(resource_group_name, vm_name)
          end until server_detail.nil?

          puts "\n"
          ui.warn "Deleted server #{vm_name}"
        end
      end

      def show_server(name, resource_group)
        server = find_server(resource_group, name)
        if server
          network_interface_name = server.network_profile.network_interfaces[0].id.split("/")[-1]
          network_interface_data = network_resource_client.network_interfaces.get(resource_group, network_interface_name)
          public_ip_id_data = network_interface_data.ip_configurations[0].public_ipaddress
          if public_ip_id_data.nil?
            public_ip_data = nil
          else
            public_ip_name = public_ip_id_data.id.split("/")[-1]
            public_ip_data = network_resource_client.public_ipaddresses.get(resource_group, public_ip_name)
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
        compute_management_client.virtual_machines.get(resource_group, name)
      end

      def virtual_machine_exist?(resource_group_name, vm_name)
        compute_management_client.virtual_machines.get(resource_group_name, vm_name)
        true
      rescue MsRestAzure::AzureOperationError => e
        if e.body
          err_json = JSON.parse(e.response.body)
          if err_json["error"]["code"] == "ResourceNotFound"
            return false
          else
            raise e
          end
        end
      end

      def security_group_exist?(resource_group_name, security_group_name)
        network_resource_client.network_security_groups.get(resource_group_name, security_group_name)
        true
      rescue MsRestAzure::AzureOperationError => e
        if e.body
          err_json = JSON.parse(e.response.body)
          if err_json["error"]["code"] == "ResourceNotFound"
            return false
          else
            raise e
          end
        end
      end

      def resource_group_exist?(resource_group_name)
        resource_management_client.resource_groups.check_existence(resource_group_name)
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
        substatuses = compute_management_client.virtual_machine_extensions.get(
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
          Chef::Log.info("ResourceGroup creation successfull.")
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
          ui.log("Virtual Machine creation successfull.") unless deployment.nil?

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

      def vm_public_ip(params = {})
        network_resource_client.public_ipaddresses.get(
          params[:azure_resource_group_name],
          params[:azure_vm_name]
        ).value!.body.properties.ip_address
      end

      def vm_default_port(params = {})
        network_resource_client.network_security_groups.get(
          params[:azure_resource_group_name],
          params[:azure_vm_name]
        ).value!.body.properties.security_rules[0].properties.destination_port_range
      end

      def create_resource_group(params = {})
        resource_group = ResourceGroup.new
        resource_group.name = params[:azure_resource_group_name]
        resource_group.location = params[:azure_service_location]

        begin
          resource_group = resource_management_client.resource_groups.create_or_update(resource_group.name, resource_group)
        rescue Exception => e
          Chef::Log.error("Failed to create the Resource Group -- exception being rescued: #{e}")
          common_arm_rescue_block(e)
        end

        resource_group
      end

      def create_virtual_machine_using_template(params)
        template = create_deployment_template(params)
        parameters = create_deployment_parameters(params)

        deploy_prop = DeploymentProperties.new
        deploy_prop.template = template
        deploy_prop.parameters = parameters
        deploy_prop.mode = "Incremental"

        deploy_params = Deployment.new
        deploy_params.properties = deploy_prop

        deployment = resource_management_client.deployments.create_or_update(params[:azure_resource_group_name], "#{params[:azure_vm_name]}_deploy", deploy_params)
        deployment
      end

      def create_vm_extension(params)
        vm_ext = VirtualMachineExtension.new
        vm_ext.name = params[:chef_extension]
        vm_ext.location = params[:azure_service_location]
        vm_ext.publisher = params[:chef_extension_publisher]
        vm_ext.virtual_machine_extension_type = params[:chef_extension]
        vm_ext.type_handler_version = params[:chef_extension_version].nil? ? get_latest_chef_extension_version(params) : params[:chef_extension_version]
        vm_ext.auto_upgrade_minor_version = false
        vm_ext.settings = params[:chef_extension_public_param]
        vm_ext.protected_settings = params[:chef_extension_private_param]
        begin
          vm_extension = compute_management_client.virtual_machine_extensions.create_or_update(
            params[:azure_resource_group_name],
            params[:azure_vm_name],
            vm_ext.name,
            vm_ext
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
        ext_version = compute_management_client.virtual_machine_extension_images.list_versions(
          params[:azure_service_location],
          params[:chef_extension_publisher],
          params[:chef_extension]
        ).last.name
        ext_version_split_values = ext_version.split(".")
        ext_version = ext_version_split_values[0] + "." + ext_version_split_values[1]
        ext_version
      end

      def delete_resource_group(resource_group_name)
        ui.info "Resource group deletion takes some time. Please wait ..."

        begin
          server = resource_management_client.resource_groups.delete(resource_group_name)
        end until server.nil?
        puts "\n"
      end

      def common_arm_rescue_block(error)
        if error.class == MsRestAzure::AzureOperationError && error.body
          err_json = JSON.parse(error.response.body)
          err_details = err_json["error"]["details"] if err_json["error"]
          if err_details
            err_details.each do |err|
              begin
                ui.error(JSON.parse(err["message"])["error"]["message"])
              rescue JSON::ParserError => e
                ui.error(err["message"])
              end
            end
          else
            ui.error(err_json["error"]["message"])
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
