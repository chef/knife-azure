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
        ssh_user: 'test-user'
      }.each do |key, value|
          Chef::Config[:knife][key] = value
        end

    @server_instance
  end

  def stub_resource_group_create_response
    resource_group = OpenStruct.new
    resource_group.name = 'test-rgrp'
    resource_group.id = 'myrgrp'
    resource_group
  end

  def stub_virtual_machine_create_response
    virtual_machine = double("VirtualMachine",
      :name => 'test-vm',
      :id => 'myvm',
      :properties => double)
    allow(virtual_machine.properties).to receive(
      :provisioning_state).and_return('Succeeded')
    virtual_machine
  end

  def stub_vm_details
    vm_details = OpenStruct.new
    vm_details.publicipaddress = '1.2.3.4'
    vm_details.sshport = '22'
    vm_details.winrmport = '5985'
    vm_details.name = 'test-vm'
    vm_details.hostedservicename = "test-vm.westeurope.cloudapp.azure.com"
    vm_details.provisioningstate = "Succeeded"
    vm_details
  end

  def stub_storage_account_create_response
    storage_account = OpenStruct.new
    storage_account.name = 'test-storage'
    storage_account.id = 'mystorage'
    storage_account
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
