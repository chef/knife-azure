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
        token_provider = MsRestAzure::ApplicationTokenProvider.new(params[:azure_tenant_id], params[:azure_client_id], params[:azure_client_secret])
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
        begin
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
        rescue => error
          if error.class == MsRestAzure::AzureOperationError && error.body
            if error.body['error']['code']
              ui.error("#{error.body['error']['message']}")
            else
              ui.error(error.body)
            end
          else
            ui.error("#{error.message}")
            Chef::Log.debug("#{error.backtrace.join("\n")}")
          end
          exit
        end
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
            network_interface_data = network_resource_client.network_interfaces.get(resource_group, network_interface_name).value!.body
            public_ip_id_data = network_interface_data.properties.ip_configurations[0].properties.public_ipaddress
            unless public_ip_id_data.nil?
              public_ip_name = public_ip_id_data.id.split('/')[-1]
              public_ip_data = network_resource_client.public_ipaddresses.get(resource_group, public_ip_name).value!.body
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
        rescue => error
          puts "#{error.body["error"]["message"]}"
        end
      end

      def find_server(resource_group, name)
        begin
          promise = compute_management_client.virtual_machines.get(resource_group, name)
          result = promise.value!

          unless result.nil?
            server = result.body
          else
            ui.error("There is no server with name #{name} or resource_group #{resource_group}. Please provide correct details.")
          end
        rescue => error
          ui.error("#{error.body["error"]["message"]}")
        end
        server
      end

      def virtual_machine_exist?(resource_group_name, vm_name)
        !compute_management_client.virtual_machines.get(resource_group_name, vm_name).value.nil?
      end

      def resource_group_exist?(resource_group_name)
        resource_management_client.resource_groups.check_existence(resource_group_name).value!.body
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
          ui.log("Creating Virtual Machine....")
          deployment = create_virtual_machine_using_template(params)
          ui.log("Virtual Machine creation successfull.") unless deployment.nil?

          unless deployment.nil?
            ui.log("Deployment name is: #{deployment.name}")
            ui.log("Deployment ID is: #{deployment.id}")
            deployment.properties.dependencies.each do |deploy|
              if deploy.resource_type == "Microsoft.Compute/virtualMachines"
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

      def vm_details(virtual_machine, vm_extension, params)
        vm_details = OpenStruct.new
        vm_details.publicipaddress = vm_public_ip(params)

        if @platform == 'Windows'
          vm_details.rdpport = vm_default_port(params)
        else
          vm_details.sshport = vm_default_port(params)
        end

        vm_details.id = virtual_machine.id
        vm_details.name = virtual_machine.name
        vm_details.locationname = params[:azure_service_location].gsub(/[ ]/,'').downcase
        vm_details.ostype = virtual_machine.properties.storage_profile.os_disk.os_type
        vm_details.provisioningstate = virtual_machine.properties.provisioning_state
        vm_details.resources = OpenStruct.new
        vm_details.resources.id = vm_extension.id
        vm_details.resources.name = vm_extension.name
        vm_details.resources.publisher = vm_extension.properties.publisher
        vm_details.resources.type = vm_extension.properties.type
        vm_details.resources.type_handler_version = vm_extension.properties.type_handler_version
        vm_details.resources.provisioning_state = vm_extension.properties.provisioning_state

        vm_details
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
          resource_group = resource_management_client.resource_groups.create_or_update(resource_group.name, resource_group).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Resource Group -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
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

      def create_virtual_machine(params)
        os_profile = OSProfile.new
        os_profile.computer_name = params[:azure_vm_name]
        os_profile.secrets = []

        if @platform == 'Windows'
          windows_config = WindowsConfiguration.new
          windows_config.provision_vmagent = true
          windows_config.enable_automatic_updates = true

          os_profile.admin_username = params[:winrm_user]
          os_profile.admin_password = params[:admin_password]
          os_profile.windows_configuration = windows_config
        else
          linux_config = LinuxConfiguration.new
          linux_config.disable_password_authentication = false

          os_profile.admin_username = params[:ssh_user]
          os_profile.admin_password = params[:ssh_password]
          os_profile.linux_configuration = linux_config
        end

        hardware_profile = HardwareProfile.new
        hardware_profile.vm_size = get_vm_size(params[:azure_vm_size])

        vm_props = VirtualMachineProperties.new
        vm_props.os_profile = os_profile
        vm_props.hardware_profile = hardware_profile
        vm_props.storage_profile = create_storage_profile(params)
        vm_props.network_profile = create_network_profile(params)

        vm_params = VirtualMachine.new
        vm_params.name = params[:azure_vm_name]
        vm_params.type = 'Microsoft.Compute/virtualMachines'
        vm_params.properties = vm_props
        vm_params.location = params[:azure_service_location]

        begin
          virtual_machine = compute_management_client.virtual_machines.create_or_update(params[:azure_resource_group_name], vm_params.name, vm_params).value!.body
        rescue Exception => e
          ui.log("Failed to create the virtual machine, use verbose mode for more details")
          Chef::Log.error("Failed to create the Virtual Machine -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end

        virtual_machine
      end

      def create_storage_profile(params)
        ui.log("Creating Storage Account.... \n\n ")
        storage_account = create_storage_account(
          params[:azure_storage_account],
          params[:azure_service_location],
          params[:azure_storage_account_type],
          params[:azure_resource_group_name]
        )

        virtual_hard_disk = get_vhd(
          params[:azure_storage_account],
          params[:azure_os_disk_name]
        )

        ui.log("StorageAccount creation successfull.")
        storage_profile = StorageProfile.new
        storage_profile.image_reference = get_image_reference(
          params[:azure_image_reference_publisher],
          params[:azure_image_reference_offer],
          params[:azure_image_reference_sku],
          params[:azure_image_reference_version]
        )
        storage_profile.os_disk = get_os_disk(
          virtual_hard_disk,
          params[:azure_os_disk_name],
          params[:azure_os_disk_caching],
          params[:azure_os_disk_create_option]
        )

        storage_profile
      end

      def create_storage_account(storage_account_name, location, storage_account_type, resource_group_name)
        storage_props = Azure::ARM::Storage::Models::StorageAccountPropertiesCreateParameters.new
        storage_props.account_type = storage_account_type

        storage_params = Azure::ARM::Storage::Models::StorageAccountCreateParameters.new
        storage_params.location = location
        storage_params.properties = storage_props

        storage = storage_management_client.storage_accounts.create(resource_group_name, storage_account_name, storage_params).value!.body
        storage
      end

      def get_vhd(storage_account_name, os_disk_name)
        virtual_hard_disk = VirtualHardDisk.new
        virtual_hard_disk.uri = "http://#{storage_account_name}.blob.core.windows.net/vhds/#{os_disk_name}.vhd"
        virtual_hard_disk
      end

      def get_image_reference(publisher, offer, sku, version)
        image_reference = ImageReference.new
        image_reference.publisher = publisher
        image_reference.offer = offer
        image_reference.sku = sku
        image_reference.version = version
        image_reference
      end

      def get_os_disk(virtual_hard_disk, os_disk_name, os_disk_caching, os_disk_create_option)
        os_disk = OSDisk.new
        os_disk.name = os_disk_name
        os_disk.vhd = virtual_hard_disk
        os_disk.caching = os_disk_caching
        os_disk.create_option = os_disk_create_option
        os_disk
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

      def create_network_profile(params)
        if vnet_exist?(params[:azure_resource_group_name], params[:azure_vnet_name])
          vnet = network_resource_client.virtual_networks.get(params[:azure_resource_group_name], params[:azure_vnet_name]).value!.body
          Chef::Log.info("Found existing vnet #{vnet.name}...")
        else
          ui.log("Creating VirtualNetwork....\n\n")
          vnet = create_virtual_network(
            params[:azure_resource_group_name],
            params[:azure_vnet_name],
            params[:azure_service_location]
          )
          Chef::Log.info("VirtualNetwork creation successfull.")
        end

        Chef::Log.info("Virtual Network name is: #{vnet.name}")

        Chef::Log.info("Virtual Network ID is: #{vnet.id}")

        if subnet_exist?(params[:azure_resource_group_name], vnet.name, params[:azure_vnet_subnet_name])
          sbn = network_resource_client.subnets.get(params[:azure_resource_group_name], vnet.name, params[:azure_vnet_subnet_name]).value!.body

          Chef::Log.info("Found subnet #{sbn.name} under virtual network #{vnet.name} ...")

       else
            ui.log("Creating Subnet....\n\n")
            sbn = create_subnet(
            params[:azure_resource_group_name],
            params[:azure_vnet_subnet_name],
            vnet
          )
          Chef::Log.info("Subnet creation successfull.")
        end

        Chef::Log.info("Subnet name is: #{sbn.name}")
        Chef::Log.info("Subnet ID is: #{sbn.id}")

        ui.log("Creating NetworkInterface....\n\n")
        nic = create_network_interface(
          params[:azure_resource_group_name],
          params[:azure_vm_name],
          params[:azure_service_location],
          sbn
        )
        Chef::Log.info("NetworkInterface creation successfull.")
        Chef::Log.info("Network Interface name is: #{nic.name}")
        Chef::Log.info("Network Interface ID is: #{nic.id}")

        network_profile = NetworkProfile.new
        network_profile.network_interfaces = [nic]
        network_profile
      end

      def create_virtual_network(resource_group_name, virtual_network_name, service_location)
        address_space = AddressSpace.new
        address_space.address_prefixes = ['10.0.0.0/16']

        vnet_props = VirtualNetworkPropertiesFormat.new
        vnet_props.address_space = address_space

        vnet_params = VirtualNetwork.new
        vnet_params.name = virtual_network_name
        vnet_params.location = service_location
        vnet_params.properties = vnet_props

        begin
          vnet = network_resource_client.virtual_networks.create_or_update(resource_group_name, vnet_params.name, vnet_params).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Virtual Network -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end
        vnet
      end

      def create_subnet(resource_group_name, subnet_name, virtual_network)
        sbn_prop = SubnetPropertiesFormat.new
        sbn_prop.address_prefix = '10.0.1.0/24'

        sbn_params = Subnet.new
        sbn_params.name = subnet_name
        sbn_params.properties = sbn_prop

        begin
          sbn = network_resource_client.subnets.create_or_update(resource_group_name, virtual_network.name, sbn_params.name, sbn_params).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Subnet -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end
        sbn
      end

      def create_network_interface(resource_group_name, vm_name, service_location, subnet)
        network_ip_configuration_properties = NetworkInterfaceIPConfigurationPropertiesFormat.new
        network_ip_configuration_properties.private_ipallocation_method = 'Dynamic'

        network_ip_configuration_properties.public_ipaddress = create_public_ip_config(
          resource_group_name,
          vm_name,
          service_location
        )

        network_ip_configuration_properties.subnet = subnet

        network_interface_ip_configuration = NetworkInterfaceIPConfiguration.new
        network_interface_ip_configuration.properties = network_ip_configuration_properties
        network_interface_ip_configuration.name = vm_name

        network_interface_props_format = NetworkInterfacePropertiesFormat.new
        network_interface_props_format.ip_configurations = [network_interface_ip_configuration]
        network_interface_props_format.network_security_group = create_network_security_group(
          resource_group_name,
          vm_name,
          service_location
        )

        network_interface = NetworkInterface.new
        network_interface.location = service_location
        network_interface.name = vm_name
        network_interface.properties = network_interface_props_format

        begin
          nic = network_resource_client.network_interfaces.create_or_update(resource_group_name, network_interface.name, network_interface).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Network Interface -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end

        nic
      end

      def create_public_ip_config(resource_group_name, vm_name, service_location)
        public_ip_props = PublicIPAddressPropertiesFormat.new
        public_ip_props.public_ipallocation_method = 'Dynamic'

        public_ip = PublicIPAddress.new
        public_ip.name = vm_name
        public_ip.location = service_location
        public_ip.properties = public_ip_props

        begin
          public_ip_address = network_resource_client.public_ipaddresses.create_or_update(
            resource_group_name,
            public_ip.name,
            public_ip
          ).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Public IP Address -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end

        public_ip_address
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
        rescue Exception => e
          Chef::Log.error("Failed to create the Virtual Machine Extension -- exception being rescued.")

          if e.class == MsRestAzure::AzureOperationError && e.body
            if e.body['error']['code'] == 'DeploymentFailed'
              ui.error("#{error.body['error']['message']}")
            else
              ui.error(e.body)
            end
          else
            ui.error("#{error.message}")
            Chef::Log.debug("#{error.backtrace.join("\n")}")
          end

          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
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
          params[:chef_extension]).value!.body.last.name
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
    end
  end
end
