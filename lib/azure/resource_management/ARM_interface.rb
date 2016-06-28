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

require 'azure/azure_interface'
require 'azure/resource_management/ARM_base'
require 'azure/resource_management/ARM_deployment_template'
require 'azure_mgmt_resources'
require 'azure_mgmt_compute'
require 'azure_mgmt_storage'
require 'azure_mgmt_network'

module Azure
  class ResourceManagement
    class ARMInterface < AzureInterface
      include Azure::ARM::ARMBase
      include Azure::ARM::ARMDeploymentTemplate

      include Azure::ARM::Resources
      include Azure::ARM::Resources::Models

      include Azure::ARM::Compute
      include Azure::ARM::Compute::Models

      include Azure::ARM::Storage
      include Azure::ARM::Storage::Models

      include Azure::ARM::Network
      include Azure::ARM::Network::Models

      attr_accessor :connection

      def initialize(params = {})
        if params[:azure_client_secret]
          token_provider = MsRestAzure::ApplicationTokenProvider.new(params[:azure_tenant_id], params[:azure_client_id], params[:azure_client_secret])
        else
          token_provider = MsRest::StringTokenProvider.new(params[:token],params[:tokentype])
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

      def list_images
      end

      def list_servers(resource_group_name = nil)
        if resource_group_name.nil?
          promise = compute_management_client.virtual_machines.list_all
        else
          promise = compute_management_client.virtual_machines.list(resource_group_name)
        end

        result = promise.value!
        servers = result.body.value

        cols = ['VM Name', 'Resource Group Name', 'Location', 'Provisioning State', 'OS Type']
        rows =  []

        servers.each do |server|
          rows << server.name.to_s
          rows << server.id.split('/')[4].downcase
          rows << server.location.to_s
          rows << begin
                           state = server.properties.provisioning_state.to_s.downcase
                           case state
                           when 'failed'
                             ui.color(state, :red)
                           when 'succeeded'
                             ui.color(state, :green)
                           else
                             ui.color(state, :yellow)
                           end
                         end
          rows << server.properties.storage_profile.os_disk.os_type.to_s
        end
        display_list(ui, cols, rows)
      end

      def delete_server(resource_group_name, vm_name)
        promise = compute_management_client.virtual_machines.get(resource_group_name, vm_name)
        if promise.value! && promise.value!.body.name == vm_name
          puts "\n\n"
          msg_pair(ui, 'VM Name', promise.value!.body.name)
          msg_pair(ui, 'VM Size', promise.value!.body.properties.hardware_profile.vm_size)
          msg_pair(ui, 'VM OS', promise.value!.body.properties.storage_profile.os_disk.os_type)
          puts "\n"

          begin
            ui.confirm('Do you really want to delete this server')
          rescue SystemExit   # Need to handle this as confirming with N/n raises SystemExit exception
            server = nil      # Cleanup is implicitly performed in other cloud plugins
            exit!
          end

          ui.info 'Deleting ..'

          begin
            print '.'
            promise = compute_management_client.virtual_machines.delete(resource_group_name, vm_name)
          end until promise.value!.body.nil?

          puts "\n"
          ui.warn "Deleted server #{vm_name}"
        end
      end

      def show_server(name, resource_group)
        begin
          server = find_server(resource_group, name)
          if server
            network_interface_name = server.properties.network_profile.network_interfaces[0].id.split('/')[-1]
            network_interface_data = network_resource_client.network_interfaces.get(resource_group, network_interface_name)
            public_ip_id_data = network_interface_data.properties.ip_configurations[0].properties.public_ipaddress
            unless public_ip_id_data.nil?
              public_ip_name = public_ip_id_data.id.split('/')[-1]
              public_ip_data = network_resource_client.public_ipaddresses.get(resource_group, public_ip_name)
            else
              public_ip_data = nil
            end

            details = Array.new
            details << ui.color('Server Name', :bold, :cyan)
            details << server.name

            details << ui.color('Size', :bold, :cyan)
            details << server.properties.hardware_profile.vm_size

            details << ui.color('Provisioning State', :bold, :cyan)
            details << server.properties.provisioning_state

            details << ui.color('Location', :bold, :cyan)
            details << server.location

            details << ui.color('Publisher', :bold, :cyan)
            details << server.properties.storage_profile.image_reference.publisher

            details << ui.color('Offer', :bold, :cyan)
            details << server.properties.storage_profile.image_reference.offer

            details << ui.color('Sku', :bold, :cyan)
            details << server.properties.storage_profile.image_reference.sku

            details << ui.color('Version', :bold, :cyan)
            details << server.properties.storage_profile.image_reference.version

            details << ui.color('OS Type', :bold, :cyan)
            details << server.properties.storage_profile.os_disk.os_type

            details << ui.color('Public IP address', :bold, :cyan)
            unless public_ip_data.nil?
              details << public_ip_data.properties.ip_address
            else
              details << ' -- '
            end

            details << ui.color('FQDN', :bold, :cyan)
            unless public_ip_data.nil? or public_ip_data.properties.dns_settings.nil?
              details << public_ip_data.properties.dns_settings.fqdn
            else
              details << ' -- '
            end

            puts ui.list(details, :columns_across, 2)
          end
        end
      end

      def find_server(resource_group, name)
        begin
          server = compute_management_client.virtual_machines.get(resource_group, name)
          server
        rescue => error
          ui.error("#{error.body["error"]["message"]}")
        end
      end

      def virtual_machine_exist?(resource_group_name, vm_name)
        begin
          compute_management_client.virtual_machines.get(resource_group_name, vm_name)
          return true
        rescue
          return false
        end
      end

      def resource_group_exist?(resource_group_name)
        resource_management_client.resource_groups.check_existence(resource_group_name)
      end

      def platform(image_reference)
        @platform ||= begin
          if image_reference =~ /WindowsServer.*/
            platform = 'Windows'
          else
            platform = 'Linux'
          end
          platform
        end
      end

      def parse_substatus_code(code, index)
        code.split('/')[index]
      end

      def fetch_substatus(resource_group_name, virtual_machine_name, chef_extension_name)
        substatuses = compute_management_client.virtual_machine_extensions.get(
          resource_group_name,
          virtual_machine_name,
          chef_extension_name,
          'instanceView'
        ).value!.body.properties.instance_view.substatuses

        return nil if substatuses.nil?

        substatuses.each do |substatus|
          if parse_substatus_code(substatus.code, 1) == 'Chef Client run logs'
            return substatus
          end
        end

        return nil
      end

      def fetch_chef_client_logs(resource_group_name, virtual_machine_name, chef_extension_name, fetch_process_start_time, fetch_process_wait_timeout = 30)
        ## fetch substatus field which contains the chef-client run logs ##
        substatus = fetch_substatus(resource_group_name, virtual_machine_name, chef_extension_name)

        unless substatus.nil?
          ## chef-client run logs becomes available ##
          status = parse_substatus_code(substatus.code, 2)
          message = substatus.message

          puts "\n\n******** Please find the chef-client run details below ********\n\n"
          print "----> chef-client run status: "
          case status
            when 'succeeded'
              ## chef-client run succeeded ##
              color = :green
            when 'failed'
              ## chef-client run failed ##
              color = :red
            when 'transitioning'
              ## chef-client run did not complete within maximum timeout of 30 minutes ##
              ## fetch whatever logs available under the chef-client.log file ##
              color = :yellow
            end
            puts "#{ui.color(status, color, :bold)}"
            puts "----> chef-client run logs: "
            puts "\n#{message}\n"  ## message field of substatus contains the chef-client run logs ##
        else
          ## unavailability of the substatus field indicates that chef-client run is not completed yet on the server ##
          fetch_process_wait_time = ((Time.now - fetch_process_start_time) / 60).round
          if fetch_process_wait_time <= fetch_process_wait_timeout
            print "#{ui.color('.', :bold)}"
            sleep 30
            fetch_chef_client_logs(resource_group_name, virtual_machine_name, chef_extension_name, fetch_process_start_time, fetch_process_wait_timeout)
          else
            ## wait time exceeded 30 minutes timeout ##
            ui.error "\nchef-client run logs could not be fetched since fetch process exceeded wait timeout of #{fetch_process_wait_timeout} minutes.\n"
          end
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
          params[:vm_size] = get_vm_size(params[:azure_vm_size])
          ui.log("Creating Virtual Machine....")
          deployment = create_virtual_machine_using_template(params)
          ui.log("Virtual Machine creation successfull.") unless deployment.nil?

          unless deployment.nil?
            ui.log("Deployment name is: #{deployment.name}")
            ui.log("Deployment ID is: #{deployment.id}")
            deployment.properties.dependencies.each do |deploy|
              if deploy.resource_type == "Microsoft.Compute/virtualMachines"
                if params[:chef_extension_public_param][:extendedLogs] == "true"
                  print "\n\nWaiting for the first chef-client run on virtual machine #{deploy.resource_name}"
                  fetch_chef_client_logs(params[:azure_resource_group_name],
                    deploy.resource_name,
                    params[:chef_extension],
                    Time.now
                  )
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
        resource_group = ResourceGroup.new()
        resource_group.name = params[:azure_resource_group_name]
        resource_group.location = params[:azure_service_location]

        begin
          resource_group = resource_management_client.resource_groups.create_or_update(resource_group.name, resource_group)
        rescue Exception => e
          Chef::Log.error("Failed to create the Resource Group -- exception being rescued: #{e.to_s}")
          common_arm_rescue_block(e)
        end

        resource_group
      end

      def create_virtual_machine_using_template(params)
        template = create_deployment_template(params)
        parameters = create_deployment_parameters(params, @platform)

        deploy_prop = DeploymentProperties.new
        deploy_prop.template = template
        deploy_prop.parameters = parameters
        deploy_prop.mode = 'Incremental'

        deploy_params = Deployment.new
        deploy_params.properties = deploy_prop

        deployment = resource_management_client.deployments.create_or_update(params[:azure_resource_group_name], "#{params[:azure_vm_name]}_deploy", deploy_params).value!.body
        deployment
      end

      def vnet_exist?(resource_group_name, vnet_name)
        begin
          network_resource_client.virtual_networks.get(resource_group_name, vnet_name).value!.body
        rescue
          return false
        end
      end

      def subnet_exist?(resource_group_name, vnet_name, subnet_name)
        begin
          network_resource_client.subnets.get(resource_group_name, vnet_name, subnet_name).value!.body
        rescue
          return false
        end
      end

      def create_network_security_group(resource_group_name, vm_name, service_location)
        network_security_group_prop_format = NetworkSecurityGroupPropertiesFormat.new
        network_security_group = NetworkSecurityGroup.new
        network_security_group.name = vm_name
        network_security_group.location = service_location
        network_security_group.properties = network_security_group_prop_format

        begin
          nsg = network_resource_client.network_security_groups.create_or_update(
            resource_group_name,
            network_security_group.name,
            network_security_group
          ).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Network Security Group -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end

        security_rules = []
        if @platform == 'Windows'
          security_rules << add_security_rule('3389', "RDP", 1000, resource_group_name, vm_name, network_security_group)
        else
          security_rules << add_security_rule("22", "SSH", 1000, resource_group_name, vm_name, network_security_group)
        end
        network_security_group_prop_format.default_security_rules = security_rules

        nsg
      end

      def add_security_rule(port, description, priority, resource_group_name, vm_name, network_security_group)
        security_rule_props = SecurityRulePropertiesFormat.new
        security_rule_props.description = description
        security_rule_props.destination_port_range = port
        security_rule_props.protocol = "Tcp"
        security_rule_props.source_port_range = "*"
        security_rule_props.source_address_prefix = "*"
        security_rule_props.destination_address_prefix = "*"
        security_rule_props.access = "Allow"
        security_rule_props.priority = priority
        security_rule_props.direction = "Inbound"

        security_rule = SecurityRule.new
        security_rule.name = vm_name
        security_rule.properties = security_rule_props

        begin
          security_rule = network_resource_client.security_rules.create_or_update(
            resource_group_name,
            network_security_group.name,
            security_rule.name,
            security_rule
          ).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Security Rule -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end

        security_rule
      end

      def create_vm_extension(params)
        vm_ext_props = VirtualMachineExtensionProperties.new
        vm_ext_props.publisher = params[:chef_extension_publisher]
        vm_ext_props.type = params[:chef_extension]
        vm_ext_props.type_handler_version = params[:chef_extension_version].nil? ? get_latest_chef_extension_version(params) : params[:chef_extension_version]
        vm_ext_props.auto_upgrade_minor_version = false
        vm_ext_props.settings = params[:chef_extension_public_param]
        vm_ext_props.protected_settings = params[:chef_extension_private_param]

        vm_ext = VirtualMachineExtension.new
        vm_ext.name = params[:chef_extension]
        vm_ext.location = params[:azure_service_location]
        vm_ext.properties = vm_ext_props

        begin
          vm_extension = compute_management_client.virtual_machine_extensions.create_or_update(
            params[:azure_resource_group_name],
            params[:azure_vm_name],
            vm_ext.name,
            vm_ext
          ).value!.body
        rescue Exception => error
          Chef::Log.error("Failed to create the Virtual Machine Extension -- exception being rescued.")
          common_arm_rescue_block(error)
        end

        vm_extension
      end

      def extension_already_installed?(server)
        server.resources.each do |extension|
          return true if (extension.properties.type == "ChefClient" || extension.properties.type == "LinuxChefClient")
        end if server.resources
        false
      end

      def get_latest_chef_extension_version(params)
        ext_version = compute_management_client.virtual_machine_extension_images.list_versions(
          params[:azure_service_location],
          params[:chef_extension_publisher],
          params[:chef_extension]).last.name
        ext_version_split_values = ext_version.split(".")
        ext_version = ext_version_split_values[0] + "." + ext_version_split_values[1]
        ext_version
      end

      def delete_resource_group(resource_group_name)
        ui.info 'Resource group deletion takes some time. Please wait ...'
        begin
          print '.'
          promise = resource_management_client.resource_groups.delete(resource_group_name)
        end until promise.value!.body.nil?
        puts "\n"
      end

      def common_arm_rescue_block(error)
        if error.class == MsRestAzure::AzureOperationError && error.body
          err_json = JSON.parse(error.response.body)
          err_details = err_json["error"]["details"] if err_json["error"]
          if err_details
            err_details.each do |err|
              ui.error(JSON.parse(err["message"])["error"]["message"])
            end
          else
            ui.error(err_json["error"]["message"])
          end
          Chef::Log.debug(error.response.body)
        else
          begin
            JSON.parse(error.message)
            Chef::Log.debug("#{error.message}")
          rescue JSON::ParserError => e
            ui.error("#{error.message}")
          end
          ui.error("Something went wrong. Please use -VV option for more details.")
          Chef::Log.debug("#{error.backtrace.join("\n")}")
        end
      end
    end
  end
end
