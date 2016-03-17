require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'pry'

module QueryAzureMock
  include AzureUtility
  def create_service
    @service = Azure::ServiceManagement::ASMInterface.new(TEST_PARAMS)
  end

  def create_instance(object)
    @server_instance = object.new
      {
        azure_subscription_id: 'azure_subscription_id',
        azure_mgmt_cert: @cert_file,
        azure_api_host_name: 'preview.core.windows-int.net',
      }.each do |key, value|
          Chef::Config[:knife][key] = value
        end

    @server_instance
  end

  def create_arm_instance(object)
    @server_instance = object.new
      {
        azure_subscription_id: 'azure_subscription_id',
        azure_tenant_id: 'azure_tenant_id',
        azure_client_id: 'azure_client_id',
        azure_client_secret: 'azure_client_secret',
        azure_resource_group_name: 'test-rgrp',
        azure_vm_name: 'test-vm',
        azure_service_location: 'West Europe',
        azure_image_reference_publisher: 'azure_image_reference_publisher',
        azure_image_reference_offer: 'azure_image_reference_offer',
        azure_image_reference_sku: 'azure_image_reference_sku',
        azure_image_reference_version: 'azure_image_reference_version',
        ssh_user: 'test-user',
        validation_key: '/tmp/validation_key'
      }.each do |key, value|
          Chef::Config[:knife][key] = value
        end

    @server_instance
  end

  def stub_resource_group_create_response
    resource_group = OpenStruct.new
    resource_group.name = 'test-rgrp'
    resource_group.id = 'myrgrp'
    resource_group.location = 'West Europe'
    resource_group
  end

  def stub_resource_management_client
    resource_management_client = double("ResourceManagementClient",
      :resource_groups => double)
    allow(resource_management_client.resource_groups).to receive_message_chain(
      :create_or_update => 'create_or_update',
      :value! => nil,
      :body => nil
    ).and_return(stub_resource_group_create_response)
    resource_management_client
  end

  def stub_compute_management_client(user_supplied_value)
    compute_management_client = double("ComputeManagementClient",
      :virtual_machines => double,
      :virtual_machine_extensions => double,
      :virtual_machine_extension_images => double)
    allow(compute_management_client.virtual_machines).to receive_message_chain(
      :create_or_update => 'create_or_update',
      :value! => nil,
      :body => nil
    ).and_return(stub_virtual_machine_create_response)
    allow(compute_management_client.virtual_machine_extensions).to receive_message_chain(
      :create_or_update => 'create_or_update',
      :value! => nil,
      :body => nil
    ).and_return(stub_vm_extension_create_response(user_supplied_value))
    allow(compute_management_client.virtual_machine_extension_images).to receive_message_chain(
      :list_versions,
      :value!,
      :body,
      :last,
      :name
    ).and_return('1210.12.10.100')
    compute_management_client
  end

  def stub_storage_management_client
    storage_management_client = double("StorageManagementClient",
      :storage_accounts => double)
    allow(storage_management_client.storage_accounts).to receive_message_chain(
      :create => 'create',
      :value! => nil,
      :body => nil).and_return(stub_storage_account_create_response)
    storage_management_client
  end

  def stub_network_resource_client(platform)
    network_resource_client = double("NetworkResourceClient",
      :public_ipaddresses => double,
      :network_security_groups => double,
      :virtual_networks => double,
      :subnets => double,
      :network_interfaces => double,
      :security_rules => double)
    allow(network_resource_client.public_ipaddresses).to receive_message_chain(
      :get => 'get',
      :value! => nil,
      :body => nil,
      :properties => nil,
      :ip_address => nil).and_return(stub_vm_public_ip_get_response)
    allow(network_resource_client.network_security_groups).to receive_message_chain(
      :get,
      :value!,
      :body,
      :properties,
      :security_rules).and_return(['default_security_rule'])
    if platform == 'Windows'
      allow(network_resource_client.network_security_groups.get.value!.body.properties.security_rules[0]).to receive_message_chain(
        :properties,
        :destination_port_range).and_return('3389')
    else
      allow(network_resource_client.network_security_groups.get.value!.body.properties.security_rules[0]).to receive_message_chain(
        :properties,
        :destination_port_range).and_return('22')
    end
    allow(network_resource_client.virtual_networks).to receive_message_chain(
      :create_or_update => 'create_or_update',
      :value! => nil,
      :body => nil).and_return(stub_virtual_network_create_response)
    allow(network_resource_client.subnets).to receive_message_chain(
      :create_or_update => 'create_or_update',
      :value! => nil,
      :body => nil).and_return(stub_subnet_create_response)
    allow(network_resource_client.network_interfaces).to receive_message_chain(
      :create_or_update => 'create_or_update',
      :value! => nil,
      :body => nil).and_return(stub_network_interface_create_response)
    allow(network_resource_client.public_ipaddresses).to receive_message_chain(
      :create_or_update => 'create_or_update',
      :value! => nil,
      :body => nil).and_return(stub_public_ip_config_create_response)
    allow(network_resource_client.network_security_groups).to receive_message_chain(
      :create_or_update => 'create_or_update',
      :value! => nil,
      :body => nil).and_return(stub_network_security_group_create_response)
    allow(network_resource_client.security_rules).to receive_message_chain(
      :create_or_update => 'create_or_update',
      :value! => nil,
      :body => nil).and_return(stub_default_security_rule_add_response(platform))

    network_resource_client
  end

  def stub_virtual_machine_create_response
    virtual_machine = double("VirtualMachine",
      :name => 'test-vm',
      :id => 'myvm',
      :type => 'Microsoft.Compute/virtualMachines',
      :properties => double,
      :location => 'West Europe')
    allow(virtual_machine.properties).to receive_message_chain(
      :storage_profile,
      :os_disk,
      :os_type).and_return('Test_OS_Type')
    allow(virtual_machine.properties).to receive(
      :provisioning_state).and_return('Succeeded')
    virtual_machine
  end

  def stub_vm_details
    vm_details = OpenStruct.new
    vm_details.id = 'test-vm-id'
    vm_details.name = 'test-vm'
    vm_details.locationname = 'test-vm-loc'
    vm_details.ostype = 'test-vm-os'
    vm_details.publicipaddress = '1.2.3.4'
    vm_details.rdpport = '3389'
    vm_details.sshport = '22'
    vm_details.provisioningstate = 'Succeeded'
    vm_details
  end

  def stub_vm_extension_create_response(user_supplied_value)
    vm_extension = double("VMExtension",
      :name => 'test-vm-ext',
      :id => 'myvmextid',
      :type => 'Microsoft.Compute/virtualMachines/extensions',
      :properties => double,
      :location => 'West Europe')
    allow(vm_extension.properties).to receive(
      :publisher).and_return('Ext_Publisher')
    allow(vm_extension.properties).to receive(
      :type).and_return('Ext_Type')
    if user_supplied_value == 'yes'
      allow(vm_extension.properties).to receive(
        :type_handler_version).and_return('11.10.1')
    elsif user_supplied_value == 'no'
      allow(vm_extension.properties).to receive(
        :type_handler_version).and_return('1210.12')
    else
      allow(vm_extension.properties).to receive(
        :type_handler_version).and_return('')
    end
    allow(vm_extension.properties).to receive(
      :provisioning_state).and_return('Succeeded')
    vm_extension
  end

  def stub_storage_profile_response
    storage_profile = OpenStruct.new
    storage_profile.image_reference = 'image_reference'
    storage_profile.os_disk = 'osdisk'
    storage_profile
  end

  def stub_storage_account_create_response
    storage_account = OpenStruct.new
    storage_account.location = 'West Europe'
    storage_account.properties = OpenStruct.new
    storage_account.properties.account_type = 'azure_storage_account_type'
    storage_account
  end

  def stub_vhd_get_response
    vhd = OpenStruct.new
    vhd.uri = 'vhd_uri'
    vhd
  end

  def stub_image_reference_response
    image_reference = OpenStruct.new
    image_reference.publisher = 'publisher'
    image_reference.offer = 'offer'
    image_reference.sku = 'sku'
    image_reference.version = 'version'
    image_reference
  end

  def stub_os_disk_get_response
    os_disk = OpenStruct.new
    os_disk.name = 'osdisk_name'
    os_disk.vhd = stub_vhd_get_response
    os_disk.caching = 'osdisk_caching'
    os_disk.create_option = 'osdisk_create_option'
    os_disk
  end

  def stub_vm_public_ip_get_response
    '1.2.3.4'
  end

  def stub_vm_default_port_get_response(platform)
    if platform == 'Windows'
      '3389'
    else
      '22'
    end
  end

  def stub_virtual_network_create_response
    virtual_network = OpenStruct.new
    virtual_network.name = 'virtual_network'
    virtual_network.id = 'virtual_network_id'
    virtual_network.location = 'virtual_network_location'
    virtual_network.properties = OpenStruct.new
    virtual_network.properties.address_space = 'vnet_address_space'
    virtual_network
  end

  def stub_subnet_create_response
    subnet = OpenStruct.new
    subnet.name = 'subnet_name'
    subnet.id = 'subnet_id'
    subnet.location = 'subnet_location'
    subnet.properties = OpenStruct.new
    subnet.properties.address_prefix = 'sbn_address_prefix'
    subnet
  end

  def stub_network_interface_create_response
    network_interface = OpenStruct.new
    network_interface.name = 'network_interface_name'
    network_interface.id = 'network_interface_id'
    network_interface.location = 'network_interface_location'
    network_interface.properties = OpenStruct.new
    network_interface.properties.ip_configurations = ['nic_ip_configurations']
    network_interface.properties.network_security_group = 'nic_network_security_group'
    network_interface
  end

  def stub_public_ip_config_create_response
    public_ip_config = OpenStruct.new
    public_ip_config.name = 'public_ip_config_name'
    public_ip_config.id = 'public_ip_config_id'
    public_ip_config.location = 'public_ip_config_location'
    public_ip_config.properties = OpenStruct.new
    public_ip_config.properties.public_ipallocation_method = 'Dynamic'
    public_ip_config
  end

  def stub_network_security_group_create_response
    network_security_group = OpenStruct.new
    network_security_group.name = 'network_security_group_name'
    network_security_group.id = 'network_security_group_id'
    network_security_group.location = 'network_security_group_location'
    network_security_group.properties = OpenStruct.new
    network_security_group.properties.default_security_rules = ['nsg_default_security_rules']
    network_security_group
  end

  def stub_default_security_rule_add_response(platform)
    security_rule = OpenStruct.new
    security_rule.name = 'security_rule_name'
    security_rule.id = 'security_rule_id'
    security_rule.location = 'security_rule_location'
    security_rule.properties = 'security_rule_properties'
    security_rule.properties = OpenStruct.new
    if platform == 'Windows'
      security_rule.properties.description = "Windows port."
      security_rule.properties.destination_port_range = '3389'
    else
      security_rule.properties.description = "Linux port."
      security_rule.properties.destination_port_range = '22'
    end
    security_rule.properties.protocol = "Tcp"
    security_rule.properties.source_port_range = "*"
    security_rule.properties.source_address_prefix = "*"
    security_rule.properties.destination_address_prefix = "*"
    security_rule.properties.access = "Allow"
    security_rule.properties.priority = 1000
    security_rule.properties.direction = "Inbound"
    security_rule
  end

  def lookup_resource_in_test_xml(lookup_name, lookup_pty, tag, in_file)
    dataXML = Nokogiri::XML readFile(in_file)
    itemsXML = dataXML.css(tag)
    not_found = true
    retval = ''
    itemsXML.each do |itemXML|
      if xml_content(itemXML, lookup_pty) == lookup_name
        not_found = false
        retval = itemXML
        break
      end
    end
    retval = Nokogiri::XML readFile('error_404.xml') if not_found
    retval
  end

  def stub_query_azure(connection)
    @getname = ''
    @getverb = ''
    @getbody = ''

    @postname = ''
    @postverb = ''
    @postbody = ''

    @deletename = ''
    @deleteverb = ''
    @deletebody = ''
    @deleteparams= ''
    @deletecount = 0

    @receivedXML = Nokogiri::XML ''
    allow(connection).to receive(:query_azure) do |name, verb, body, params, wait, services|
      Chef::Log.info 'calling web service:' + name
      if verb == 'get' || verb == nil
        retval = ''
        if name == 'affinitygroups' && services == false
          retval = Nokogiri::XML readFile('list_affinitygroups.xml')
        elsif name == 'networking/virtualnetwork'
          retval = Nokogiri::XML readFile('list_vnets.xml')
        elsif name == 'networking/media'
          retval = Nokogiri::XML readFile('get_network.xml')
        elsif name == 'images'
          retval = Nokogiri::XML readFile('list_images.xml')
        elsif name == 'disks'
          retval = Nokogiri::XML readFile('list_disks.xml')
        elsif name == 'disks/deployment001-role002-0-201241722728'
          retval = Nokogiri::XML readFile('list_disks_for_role002.xml')
        elsif name == 'hostedservices'
          retval = Nokogiri::XML readFile('list_hosts.xml')
        elsif name =~ /hostedservices\/([-\w]*)$/ && params == "embed-detail=true"
          retval = Nokogiri::XML readFile('list_deployments_for_service001.xml')
        elsif name =~ /hostedservices\/([-\w]*)$/
          service_name = /hostedservices\/([-\w]*)/.match(name)[1]
          retval = lookup_resource_in_test_xml(service_name, 'ServiceName', 'HostedServices HostedService', 'list_hosts.xml')
        elsif name == 'hostedservices/service001/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_service001.xml')
        elsif name == 'hostedservices/service001/deployments/deployment001/roles/role001'
          retval = Nokogiri::XML readFile('list_deployments_for_service001.xml')
        elsif name =~ /hostedservices\/[-\w]*\/deployments\/[-\w]*\/roles\/[-\w]*/
          retval = Nokogiri::XML readFile('list_deployments_for_service005.xml')
        elsif name == 'hostedservices/service002/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_service002.xml')
        elsif name == 'hostedservices/service002/deployments/testrequest'
          retval = Nokogiri::XML readFile('list_deployments_for_service002.xml')
        elsif name == 'hostedservices/service003/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_service003.xml')
        elsif name == 'hostedservices/vmname/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_vmname.xml')
        elsif name == 'hostedservices/service004/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_service004.xml')
        elsif name == 'storageservices'
          retval = Nokogiri::XML readFile('list_storageaccounts.xml')
        elsif name =~ /storageservices\/[-\w]*$/
          service_name = /storageservices\/([-\w]*)/.match(name)[1]
          retval = lookup_resource_in_test_xml(service_name, 'ServiceName', 'StorageServices StorageService', 'list_storageaccounts.xml')
        else
          Chef::Log.warn 'unknown get value:' + name
        end
        @getname = name
        @getverb = verb
        @getbody = body
      elsif verb == 'post'
        if name == 'affinitygroups' && services == false
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        elsif name == 'hostedservices'
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        elsif name == 'hostedservices/unknown_yet/deployments'
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        elsif name == 'hostedservices/service001/deployments/deployment001/roles'
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        elsif name == 'hostedservices/service004/deployments/deployment004/roles'
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        elsif name =~ /hostedservices\/vm01.*\/deployments/
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        elsif name =~ /hostedservices\/vmname\/deployments/
          # Case when vm name and service name are same.
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        else
          Chef::Log.warn 'unknown post value:' + name
        end
        @postname = name
        @postverb = verb
        @postbody = body
      elsif verb == 'delete'
        @deletename = name
        @deleteverb = verb
        @deletebody = body
        @deleteparams = params
        @deletecount += 1
      elsif verb == 'put'
        if name == 'networking/media'
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        end
        @postname = name
        @postverb = verb
        @postbody = body
      else
        Chef::Log.warn 'unknown verb:' + verb
      end
      retval
    end

  end
end
