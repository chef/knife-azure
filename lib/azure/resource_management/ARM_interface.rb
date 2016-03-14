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

require 'azure_mgmt_resources'
require 'azure_mgmt_compute'
require 'azure_mgmt_storage'
require 'azure_mgmt_network'

module Azure
  class ResourceManagement
    class ARMInterface < AzureInterface
      include Azure::ARM::ARMBase

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
          resource_client = ResourceManagementClient.new(@credentials)
          resource_client.subscription_id = @azure_subscription_id
          resource_client
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
          storage_client = StorageManagementClient.new(@credentials)
          storage_client.subscription_id = @azure_subscription_id
          storage_client
        end
      end

      def network_resource_client
        @network_resource_client ||= begin
          network_client = NetworkResourceProviderClient.new(@credentials)
          network_client.subscription_id = @azure_subscription_id
          network_client
        end
      end

      def list_images
      end

      def list_servers
        begin
          promise = compute_management_client.virtual_machines.list_all
          result = promise.value!
          servers = result.body.value

          cols = ['VM Name', 'Location', 'Provisioning State', 'OS Type']
          rows =  []

          servers.each do |server|
            rows << server.name.to_s
            rows << server.location.to_s
            rows << begin
                             state = server.properties.provisioning_state.to_s.downcase
                             case state
                             when 'shutting-down','terminated','stopping','stopped'
                               ui.color(state, :red)
                             when 'pending'
                               ui.color(state, :yellow)
                             else
                               ui.color('ready', :green)
                             end
                           end
            rows << server.properties.storage_profile.os_disk.os_type.to_s
          end
          display_list(ui, cols, rows)
        rescue => error
          ui.error "#{error.class} and #{error.message}"
        end
      end

       def delete_server(resource_group_name, vm_name, custom_headers=nil)
        promise = compute_management_client.virtual_machines.get(resource_group_name, vm_name, expand=nil, custom_headers)
        if promise.value! && promise.value!.body.name == vm_name
          puts "\n"
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
            promise = compute_management_client.virtual_machines.delete(resource_group_name, vm_name, custom_headers = nil)
          end until promise.value!.body.nil?

          puts "\n"
          ui.warn "Deleted server #{vm_name}"
        end
      end

      def show_server(name, resource_group)
        begin
          promise = compute_management_client.virtual_machines.get(resource_group, name)
          result = promise.value!

          unless result.nil?
            server = result.body

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

            puts ui.list(details, :columns_across, 2)

         else
           puts "There is no server with name #{name} or resource_group #{resource_group}. Please provide correct details."
         end

        rescue => error
          puts "#{error.body["error"]["message"]}"
        end

      end

      def create_server(params = {})
        platform = ""
        if params[:azure_image_reference_offer] =~ /WindowsServer.*/
          platform = "Windows"
        else
          platform = "Linux"
        end

        ## resource group creation
        if not resource_management_client.resource_groups.check_existence(params[:azure_resource_group_name]).value!.body
          Chef::Log.info("Creating ResourceGroup....")
          resource_group = create_resource_group(resource_management_client, params)
          Chef::Log.info("ResourceGroup creation successfull.")
          Chef::Log.info("Resource Group name is: #{resource_group.name}")
          Chef::Log.info("Resource Group ID is: #{resource_group.id}")
        else
          Chef::Log.info("Resource Group #{params[:azure_resource_group_name]} already exist. Skipping its creation.")
          Chef::Log.info("Adding new VM #{params[:azure_vm_name]} to this resource group.")
        end

        ## virtual machine creation
        if compute_management_client.virtual_machines.get(params[:azure_resource_group_name], params[:azure_vm_name]).value.nil?
          Chef::Log.info("Creating VirtualMachine....")
          virtual_machine = create_virtual_machine(compute_management_client, params, platform)
          Chef::Log.info("VirtualMachine creation successfull.")
          Chef::Log.info("Virtual Machine name is: #{virtual_machine.name}")
          Chef::Log.info("Virtual Machine ID is: #{virtual_machine.id}")

          Chef::Log.info("Creating VirtualMachineExtension....")
          vm_extension = create_vm_extension(compute_management_client, params)
          Chef::Log.info("VirtualMachineExtension creation successfull.")
          Chef::Log.info("Virtual Machine Extension name is: #{vm_extension.name}")
          Chef::Log.info("Virtual Machine Extension ID is: #{vm_extension.id}")

          vm_details = get_vm_details(params, platform)
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
        else
          Chef::Log.info("Virtual Machine #{params[:azure_vm_name]} already exist under the Resource Group #{params[:azure_resource_group_name]}. Exiting for now.")
        end
      end

      def get_vm_details(params, platform)
        vm_details = OpenStruct.new
        vm_details.publicipaddress = get_vm_public_ip(network_resource_client, params)

        if platform == "Windows"
          vm_details.rdpport = get_vm_default_port(network_resource_client, params)
        else
          vm_details.sshport = get_vm_default_port(network_resource_client, params)
        end

        vm_details
      end

      def get_vm_public_ip(network_client, params)
        network_client.public_ip_addresses.get(
          params[:azure_resource_group_name],
          params[:azure_vm_name]
        ).value!.body.properties.ip_address
      end

      def get_vm_default_port(network_client, params)
        network_client.network_security_groups.get(
          params[:azure_resource_group_name],
          params[:azure_vm_name]
        ).value!.body.properties.security_rules[0].properties.destination_port_range
      end

      def create_resource_group(resource_client, params = {})
        resource_group = ResourceGroup.new()
        resource_group.name = params[:azure_resource_group_name]
        resource_group.location = params[:azure_service_location]

        begin
          resource_group = resource_client.resource_groups.create_or_update(resource_group.name, resource_group).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Resource Group -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end

        resource_group
      end

      def create_virtual_machine(compute_client, params, platform)
        vm_props = VirtualMachineProperties.new

        os_profile = OSProfile.new
        os_profile.computer_name = params[:azure_vm_name]
        os_profile.secrets = []

        if platform == "Windows"
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

        vm_props.os_profile = os_profile

        hardware_profile = HardwareProfile.new
        hardware_profile.vm_size = get_vm_size(params[:azure_vm_size])
        vm_props.hardware_profile = hardware_profile

        vm_props.storage_profile = create_storage_profile(storage_management_client, params)

        vm_props.network_profile = create_network_profile(network_resource_client, params, platform)

        vm_params = VirtualMachine.new
        vm_params.name = params[:azure_vm_name]
        vm_params.type = 'Microsoft.Compute/virtualMachines'
        vm_params.properties = vm_props
        vm_params.location = params[:azure_service_location]

        begin
          virtual_machine = compute_client.virtual_machines.create_or_update(params[:azure_resource_group_name], vm_params.name, vm_params).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Virtual Machine -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end

        virtual_machine
      end

      def create_storage_profile(storage_client, params)
        Chef::Log.info("Creating StorageAccount....")
        storage_account = create_storage_account(
          storage_client,
          params[:azure_storage_account],
          params[:azure_service_location],
          params[:azure_storage_account_type],
          params[:azure_resource_group_name]
        )
        Chef::Log.info("StorageAccount creation successfull.")
        Chef::Log.info("Storage Account name is: #{storage_account.name}")
        Chef::Log.info("Storage Account ID is: #{storage_account.id}")
        virtual_hard_disk = get_vhd(storage_account, params[:azure_os_disk_name])

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

      def create_storage_account(storage_client, storage_account_name, location, storage_account_type, resource_group_name)
        storage_params = Azure::ARM::Storage::Models::StorageAccountCreateParameters.new
        storage_params.name = storage_account_name
        storage_params.location = location
        storage_props = Azure::ARM::Storage::Models::StorageAccountPropertiesCreateParameters.new
        storage_params.properties = storage_props
        storage_props.account_type = storage_account_type

        storage = storage_client.storage_accounts.create(resource_group_name, storage_params.name, storage_params).value!.body

        storage.name = storage_account_name    ## response for storage creation does not contain name in it ##

        storage
      end

      def get_vhd(storage, os_disk_name)
        storage_account_name = storage.name
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

      def create_network_profile(network_client, params, platform)
        Chef::Log.info("Creating VirtualNetwork....")
        vnet = create_virtual_network(
          network_client,
          params[:azure_resource_group_name],
          params[:azure_network_name],
          params[:azure_service_location]
        )
        Chef::Log.info("VirtualNetwork creation successfull.")
        Chef::Log.info("Virtual Network name is: #{vnet.name}")
        Chef::Log.info("Virtual Network ID is: #{vnet.id}")

        Chef::Log.info("Creating Subnet....")
        sbn = create_subnet(
          network_client,
          params[:azure_resource_group_name],
          params[:azure_subnet_name],
          vnet
        )
        Chef::Log.info("Subnet creation successfull.")
        Chef::Log.info("Subnet name is: #{sbn.name}")
        Chef::Log.info("Subnet ID is: #{sbn.id}")

        Chef::Log.info("Creating NetworkInterface....")
        nic = create_network_interface(
          network_client,
          params[:azure_resource_group_name],
          params[:azure_vm_name],
          params[:azure_service_location],
          sbn,
          platform
        )
        Chef::Log.info("NetworkInterface creation successfull.")
        Chef::Log.info("Network Interface name is: #{nic.name}")
        Chef::Log.info("Network Interface ID is: #{nic.id}")

        network_profile = NetworkProfile.new
        network_profile.network_interfaces = [nic]
        network_profile
      end

      def create_virtual_network(network_client, resource_group_name, virtual_network_name, service_location)
        vnet_params = VirtualNetwork.new
        vnet_params.name = virtual_network_name
        vnet_props = VirtualNetworkPropertiesFormat.new
        vnet_params.location = service_location
        address_space = AddressSpace.new
        address_space.address_prefixes = ['10.0.0.0/16']
        vnet_props.address_space = address_space
        vnet_params.properties = vnet_props

        begin
          vnet = network_client.virtual_networks.create_or_update(resource_group_name, vnet_params.name, vnet_params).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Virtual Network -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end

        vnet
      end

      def create_subnet(network_client, resource_group_name, subnet_name, virtual_network)
        sbn_params = Subnet.new
        sbn_params.name = subnet_name
        sbn_prop = SubnetPropertiesFormat.new
        sbn_params.properties = sbn_prop
        sbn_prop.address_prefix = '10.0.1.0/24'

        begin
          sbn = network_client.subnets.create_or_update(resource_group_name, virtual_network.name, sbn_params.name, sbn_params).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Subnet -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end

        sbn
      end

      def create_network_interface(network_client, resource_group_name, vm_name, service_location, subnet, platform)
        network_ip_configuration_properties = NetworkInterfaceIpConfigurationPropertiesFormat.new
        network_ip_configuration_properties.private_ipallocation_method = 'Dynamic'

        network_ip_configuration_properties.public_ipaddress = create_public_ip_config(
          network_client,
          resource_group_name,
          vm_name,
          service_location
        )

        network_ip_configuration_properties.subnet = subnet

        network_interface_ip_configuration = NetworkInterfaceIpConfiguration.new
        network_interface_ip_configuration.properties = network_ip_configuration_properties
        network_interface_ip_configuration.name = vm_name

        network_interface_props_format = NetworkInterfacePropertiesFormat.new
        network_interface_props_format.ip_configurations = [network_interface_ip_configuration]
        network_interface_props_format.network_security_group = create_network_security_group(
          network_client,
          resource_group_name,
          vm_name,
          service_location,
          platform
        )

        network_interface = NetworkInterface.new
        network_interface.location = service_location
        network_interface.name = vm_name
        network_interface.properties = network_interface_props_format

        begin
          nic = network_client.network_interfaces.create_or_update(resource_group_name, network_interface.name, network_interface).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Network Interface -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end

        nic
      end

      def create_public_ip_config(network_client, resource_group_name, vm_name, service_location)
        public_ip_props = PublicIpAddressPropertiesFormat.new
        public_ip_props.public_ipallocation_method = 'Dynamic'

        public_ip = PublicIpAddress.new
        public_ip.name = vm_name
        public_ip.location = service_location
        public_ip.properties = public_ip_props

        begin
          public_ip_address = network_client.public_ip_addresses.create_or_update(
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

      def create_network_security_group(network_client, resource_group_name, vm_name, service_location, platform)
        network_security_group_prop_format = NetworkSecurityGroupPropertiesFormat.new
        network_security_group = NetworkSecurityGroup.new
        network_security_group.name = vm_name
        network_security_group.location = service_location
        network_security_group.properties = network_security_group_prop_format

        begin
          nsg = network_client.network_security_groups.create_or_update(
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
        if platform == "Windows"
          security_rules << add_security_rule('3389', "RDP", 1000, network_client, resource_group_name, vm_name, network_security_group)
        else
          security_rules << add_security_rule("22", "SSH", 1000, network_client, resource_group_name, vm_name, network_security_group)
        end
        network_security_group_prop_format.default_security_rules = security_rules

        nsg
      end

      def add_security_rule(port, description, priority, network_client, resource_group_name, vm_name, network_security_group)
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
          security_rule = network_client.security_rules.create_or_update(
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

      def create_vm_extension(compute_client, params)
        vm_ext_props = VirtualMachineExtensionProperties.new
        vm_ext_props.publisher = params[:chef_extension_publisher]
        vm_ext_props.type = params[:chef_extension]
        vm_ext_props.type_handler_version = params[:chef_extension_version].nil? ? get_latest_chef_extension_version(compute_client, params) : params[:chef_extension_version]
        vm_ext_props.auto_upgrade_minor_version = false
        vm_ext_props.settings = params[:chef_extension_public_param]
        vm_ext_props.protected_settings = params[:chef_extension_private_param]

        vm_ext = VirtualMachineExtension.new
        vm_ext.name = params[:azure_vm_name]
        vm_ext.location = params[:azure_service_location]
        vm_ext.properties = vm_ext_props

        begin
          vm_extension = compute_client.virtual_machine_extensions.create_or_update(
            params[:azure_resource_group_name],
            params[:azure_vm_name],
            vm_ext.name,
            vm_ext
          ).value!.body
        rescue Exception => e
          Chef::Log.error("Failed to create the Virtual Machine Extension -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
        end

        vm_extension
      end

      def get_latest_chef_extension_version(compute_client, params)
        ext_version = compute_client.virtual_machine_extension_images.list_versions(
          params[:azure_service_location],
          params[:chef_extension_publisher],
          params[:chef_extension]).value!.body.last.name
        ext_version = ext_version.split(".").first + ".*"
        ext_version
      end
    end
  end
end

