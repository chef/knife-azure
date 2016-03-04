#
# Author:: Aliasgar Batterywala (<aliasgar.batterywala@clogeny.com>)
# Copyright:: Copyright (c) 2016 Opscode, Inc.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzurermServerCreate do
  include AzureSpecHelper
  include QueryAzureMock
  include AzureUtility

  before do
    @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerCreate)
    @service = @arm_server_instance.service

    @params = {
      :azure_resource_group_name => Chef::Config[:knife][:azure_resource_group_name],
      :azure_service_location => Chef::Config[:knife][:azure_service_location],
      :azure_vm_name => Chef::Config[:knife][:azure_vm_name],
      :winrm_user => 'winrm_user',
      :admin_password => 'admin_password',
      :ssh_user => Chef::Config[:knife][:ssh_user],
      :ssh_password => 'ssh_password',
      :azure_vm_size => 'azure_vm_size',
      :azure_storage_account => 'azurestorageaccount',
      :azure_storage_account_type => 'azure_storage_account_type',
      :azure_image_reference_publisher => Chef::Config[:knife][:azure_image_reference_publisher],
      :azure_image_reference_offer => Chef::Config[:knife][:azure_image_reference_offer],
      :azure_image_reference_sku => Chef::Config[:knife][:azure_image_reference_sku],
      :azure_image_reference_version => Chef::Config[:knife][:azure_image_reference_version],
      :azure_os_disk_name => 'azureosdiskname',
      :azure_os_disk_caching => 'azure_os_disk_caching',
      :azure_os_disk_create_option => 'azure_os_disk_create_option',
      :azure_virtual_network_name => 'azure_virtual_network_name',
      :azure_subnet_name => 'azure_subnet_name',
      :port => "5985"
    }
  end

  describe "parameter test:" do
    context "compulsory parameters" do

      it "azure_subscription_id" do
        Chef::Config[:knife].delete(:azure_subscription_id)
        expect(@arm_server_instance.ui).to receive(:error)
        expect {@arm_server_instance.run}.to raise_error(SystemExit)
      end

      it "azure_tenant_id" do
        Chef::Config[:knife].delete(:azure_tenant_id)
        expect(@arm_server_instance.ui).to receive(:error)
        expect {@arm_server_instance.run}.to raise_error(SystemExit)
      end

      it "azure_client_id" do
        Chef::Config[:knife].delete(:azure_client_id)
        expect(@arm_server_instance.ui).to receive(:error)
        expect {@arm_server_instance.run}.to raise_error(SystemExit)
      end

      it "azure_client_secret" do
        Chef::Config[:knife].delete(:azure_client_secret)
        expect(@arm_server_instance.ui).to receive(:error)
        expect {@arm_server_instance.run}.to raise_error(SystemExit)
      end

      it "azure_resource_group_name" do
        Chef::Config[:knife].delete(:azure_resource_group_name)
        expect(@arm_server_instance.ui).to receive(:error)
        expect {@arm_server_instance.run}.to raise_error(SystemExit)
      end

      it "azure_vm_name" do
        Chef::Config[:knife].delete(:azure_vm_name)
        expect(@arm_server_instance.ui).to receive(:error)
        expect {@arm_server_instance.run}.to raise_error(SystemExit)
      end

      it "azure_service_location" do
        Chef::Config[:knife].delete(:azure_service_location)
        expect(@arm_server_instance.ui).to receive(:error)
        expect {@arm_server_instance.run}.to raise_error(SystemExit)
      end

      it "azure_image_reference_publisher" do
        Chef::Config[:knife].delete(:azure_image_reference_publisher)
        expect(@arm_server_instance.ui).to receive(:error)
        expect {@arm_server_instance.run}.to raise_error(SystemExit)
      end

      it "azure_image_reference_offer" do
        Chef::Config[:knife].delete(:azure_image_reference_offer)
        expect(@arm_server_instance.ui).to receive(:error)
        expect {@arm_server_instance.run}.to raise_error(SystemExit)
      end

      it "azure_image_reference_sku" do
        Chef::Config[:knife].delete(:azure_image_reference_sku)
        expect(@arm_server_instance.ui).to receive(:error)
        expect {@arm_server_instance.run}.to raise_error(SystemExit)
      end

      it "azure_image_reference_version" do
        Chef::Config[:knife].delete(:azure_image_reference_version)
        expect(@arm_server_instance.ui).to receive(:error)
        expect {@arm_server_instance.run}.to raise_error(SystemExit)
      end
    end

    context "optional parameters" do
      context "not given by user" do
        before do
          @vm_name_with_no_special_chars = 'testvm'
          Chef::Config[:knife][:ssh_password] = 'ssh_password'
          @azure_vm_size_default_value = 'Small'
        end

        it "azure_storage_account not provided by user so vm_name gets assigned to it" do
          Chef::Config[:knife].delete(:azure_storage_account)
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_storage_account]).to be == @vm_name_with_no_special_chars
        end

        it "azure_os_disk_name not provided by user so vm_name gets assigned to it" do
          Chef::Config[:knife].delete(:azure_os_disk_name)
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_os_disk_name]).to be == @vm_name_with_no_special_chars
        end

        it "azure_network_name not provided by user so vm_name gets assigned to it" do
          Chef::Config[:knife].delete(:azure_network_name)
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_network_name]).to be == 'test-vm'
        end

        it "azure_subnet_name not provided by user so vm_name gets assigned to it" do
          Chef::Config[:knife].delete(:azure_subnet_name)
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_subnet_name]).to be == 'test-vm'
        end

        after do
          Chef::Config[:knife].delete(:ssh_password)
        end
      end

      context "given by user" do
        before do
          @vm_name_with_no_special_chars = 'testvm'
          Chef::Config[:knife][:ssh_password] = 'ssh_password'
          Chef::Config[:knife][:azure_storage_account] = 'azure_storage_account'
          @storage_account_name_with_no_special_chars = 'azurestorageaccount'
          Chef::Config[:knife][:azure_os_disk_name] = 'azure_os_disk_name'
          @os_disk_name_with_no_special_chars = 'azureosdiskname'
          Chef::Config[:knife][:azure_network_name] = 'azure_network_name'
          Chef::Config[:knife][:azure_subnet_name] = 'azure_subnet_name'
          Chef::Config[:knife][:azure_vm_size] = 'Medium'
        end

        it "azure_storage_account provided by user so vm_name does not get assigned to it" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_storage_account]).to be == @storage_account_name_with_no_special_chars
        end

        it "azure_os_disk_name provided by user so vm_name does not get assigned to it" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_os_disk_name]).to be == @os_disk_name_with_no_special_chars
        end

        it "azure_network_name provided by user so vm_name does not get assigned to it" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_network_name]).to be == 'azure_network_name'
        end

        it "azure_subnet_name provided by user so vm_name does not get assigned to it" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_subnet_name]).to be == 'azure_subnet_name'
        end

        it "azure_vm_size provided by user so default value does not get assigned to it" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_vm_size]).to be == 'Medium'
        end

        after do
          Chef::Config[:knife].delete(:ssh_password)
          Chef::Config[:knife].delete(:azure_storage_account)
          Chef::Config[:knife].delete(:azure_os_disk_name)
          Chef::Config[:knife].delete(:azure_network_name)
          Chef::Config[:knife].delete(:azure_subnet_name)
          Chef::Config[:knife].delete(:azure_vm_size)
        end
      end
    end
  end

  describe "server create" do
    before do
      Chef::Config[:knife][:ssh_password] = 'ssh_password'
      Chef::Config[:knife][:winrm_password] = 'winrm_password'

      @resource_client = double("ResourceManagementClient")
      @compute_client = double("ComputeManagementClient")
      @storage_client = double("StorageManagementClient")
      @network_client = double("NetworkResourceClient")

      @resource_promise = double("ResourcePromise")
      @compute_promise = double("ComputePromise")
      @storage_promise = double("StoragePromise")
      @network_promise = double("NetworkPromise")

      allow(@service).to receive(
        :resource_management_client).and_return(
          @resource_client)
      allow(@service).to receive(
        :compute_management_client).and_return(
          @compute_client)
      allow(@service).to receive(
        :storage_management_client).and_return(
          @storage_client)
      allow(@service).to receive(
        :network_resource_client).and_return(
          @network_client)

      allow(@arm_server_instance).to receive(:bootstrap_exec)
    end

    describe "resource group" do
      before do
        allow(@compute_client).to receive_message_chain(
          :virtual_machines, :get).and_return(
            @compute_promise)
        allow(@compute_promise).to receive_message_chain(
          :value, :nil?).and_return(
            false)
      end

      it "create resource group when it does not exist already" do
        expect(@resource_client).to receive_message_chain(
          :resource_groups, :check_existence).and_return(
            @resource_promise)
        expect(@resource_promise).to receive_message_chain(
          :value!, :body).and_return(
            false)
        expect(@service).to receive(
          :create_resource_group).exactly(1).and_return(
            stub_resource_group_create_response)
        @arm_server_instance.run
      end

      it "skip resource group creation when it does exist already" do
        expect(@resource_client).to receive_message_chain(
          :resource_groups, :check_existence).and_return(
            @resource_promise)
        expect(@resource_promise).to receive_message_chain(
          :value!, :body).and_return(
            true)
        expect {@arm_server_instance.run}.to raise_error(SystemExit)
      end
    end

    describe "virtual machine" do
      context "for Linux" do
        before do
          {
            :azure_image_reference_publisher => 'OpenLogic',
            :azure_image_reference_offer => 'CentOS',
            :azure_image_reference_sku => '6.5',
            :azure_image_reference_version => 'latest',
            :ssh_user => 'ssh_user',
            :bootstrap_protocol => 'ssh'
          }.each do |key, value|
              Chef::Config[:knife][key] = value
            end

          expect(@arm_server_instance).to receive(
            :is_image_windows?).at_least(4).and_return(false)

          allow(@resource_client).to receive_message_chain(
            :resource_groups, :check_existence).and_return(
              @resource_promise)
          allow(@resource_promise).to receive_message_chain(
            :value!, :body).and_return(
              false)
          allow(@service).to receive(
            :create_resource_group).and_return(
              stub_resource_group_create_response)
        end

        it "create virtual machine when it does not exist already" do
          expect(@compute_client).to receive_message_chain(
            :virtual_machines, :get).and_return(
              @compute_promise)
          expect(@compute_promise).to receive_message_chain(
            :value, :nil?).and_return(
              true)
          expect(@service).to receive(
            :create_virtual_machine).exactly(1).and_return(
              stub_virtual_machine_create_response)
          expect(@service).to receive(
            :get_vm_details).exactly(1).and_return(
              stub_vm_details)
          @arm_server_instance.run
        end

        it "skip virtual machine creation when it does exist already" do
          expect(@compute_client).to receive_message_chain(
            :virtual_machines, :get).and_return(
              @compute_promise)
          expect(@compute_promise).to receive_message_chain(
            :value, :nil?).and_return(
              false)
          @arm_server_instance.run
        end
      end

      context "for Windows" do
        before do
          {
            :azure_image_reference_publisher => 'MicrosoftWindowsServer',
            :azure_image_reference_offer => 'WindowsServer',
            :azure_image_reference_sku => '2012-R2-Datacenter',
            :azure_image_reference_version => 'latest',
            :winrm_user => 'winrm_user',
            :bootstrap_protocol => 'winrm'
          }.each do |key, value|
              Chef::Config[:knife][key] = value
            end

          expect(@arm_server_instance).to receive(
            :is_image_windows?).at_least(3).and_return(true)

          allow(@resource_client).to receive_message_chain(
            :resource_groups, :check_existence).and_return(
              @resource_promise)
          allow(@resource_promise).to receive_message_chain(
            :value!, :body).and_return(
              false)
          allow(@service).to receive(
            :create_resource_group).and_return(
              stub_resource_group_create_response)
        end

        it "create virtual machine when it does not exist already" do
          expect(@compute_client).to receive_message_chain(
            :virtual_machines, :get).and_return(
              @compute_promise)
          expect(@compute_promise).to receive_message_chain(
            :value, :nil?).and_return(
              true)
          expect(@service).to receive(
            :create_virtual_machine).exactly(1).and_return(
              stub_virtual_machine_create_response)
          expect(@service).to receive(
            :get_vm_details).exactly(1).and_return(
              stub_vm_details)
          @arm_server_instance.run
        end

        it "skip virtual machine creation when it does exist already" do
          expect(@compute_client).to receive_message_chain(
            :virtual_machines, :get).and_return(
              @compute_promise)
          expect(@compute_promise).to receive_message_chain(
            :value, :nil?).and_return(
              false)
          @arm_server_instance.run
        end
      end
    end

    describe "create_resource_group" do
      it "successfully returns resource group create response" do
        response = @service.create_resource_group(
          stub_resource_client, @params)
        expect(response.name).to_not be nil
        expect(response.id).to_not be nil
        expect(response.location).to_not be nil
      end
    end

    describe "create_virtual_machine" do
      before do
        allow(@service).to receive(:create_storage_profile)
        allow(@service).to receive(:create_network_profile)
      end

      it "successfully returns virtual machine create response" do
        response = @service.create_virtual_machine(
          stub_compute_client, @params, 'Linux')
        expect(response.name).to_not be nil
        expect(response.id).to_not be nil
        expect(response.type).to_not be nil
        expect(response.properties).to_not be nil
        expect(response.properties.provisioning_state).to_not be 'Succeeded'
        expect(response.location).to_not be nil
      end
    end

    describe "create_storage_profile" do
      it "successfully returns storage profile response" do
        expect(@service).to receive(
          :create_storage_account).and_return(
            stub_storage_account_create_response)
        expect(@service).to receive(
          :get_vhd).and_return(
            stub_vhd_get_response)
        expect(@service).to receive(
          :get_image_reference).and_return(
            stub_image_reference_response)
        expect(@service).to receive(
          :get_os_disk).and_return(
            stub_os_disk_get_response)
        response = @service.create_storage_profile(
          @storage_client, @params)
        expect(response.image_reference).to_not be nil
        expect(response.os_disk).to_not be nil
        expect(response.data_disks).to be nil
      end
    end

    describe "get_vm_details" do
      context 'for Linux' do
        before do
          @platform = 'Linux'
        end

        it "successfully returns vm details response" do
          expect(@service).to receive(
            :get_vm_public_ip).and_return(
              stub_vm_public_ip_get_response)
          expect(@service).to receive(
            :get_vm_default_port).and_return(
              stub_vm_default_port_get_response(@platform))
          response = @service.get_vm_details(@params, @platform)
          expect(response.publicipaddress).to_not be nil
          expect(response.sshport).to be == '22'
        end
      end

      context 'for Windows' do
        before do
          @platform = 'Windows'
        end

        it "successfully returns vm details response" do
          expect(@service).to receive(
            :get_vm_public_ip).and_return(
              stub_vm_public_ip_get_response)
          expect(@service).to receive(
            :get_vm_default_port).and_return(
              stub_vm_default_port_get_response(@platform))
          response = @service.get_vm_details(@params, @platform)
          expect(response.publicipaddress).to_not be nil
          expect(response.winrmport).to be == '3389'
        end
      end
    end

    describe "get_vm_public_ip" do
      it "successfully returns vm public ip response" do
        response = @service.get_vm_public_ip(stub_network_client('Windows'), @params)
        expect(response).to be == '1.2.3.4'
      end
    end

    describe "get_vm_default_port" do
      context "for Linux" do
        before do
          @platform = 'Linux'
        end

        it "successfully returns vm default port response" do
          response = @service.get_vm_default_port(stub_network_client(@platform), @params)
          expect(response).to be == '22'
        end
      end

      context "for Windows" do
        before do
          @platform = 'Windows'
        end

        it "successfully returns vm default port response" do
          response = @service.get_vm_default_port(stub_network_client(@platform), @params)
          expect(response).to be == '3389'
        end
      end
    end

    describe "create_storage_account" do
      it "successfully creates storage account" do
        response = @service.create_storage_account(
          stub_storage_client,
          @params[:azure_storage_account],
          @params[:azure_service_location],
          @params[:azure_storage_account_type],
          @params[:azure_resource_group_name])
        expect(response.name).to be == 'azurestorageaccount'
        expect(response.id).to_not be nil
        expect(response.location).to_not be nil
        expect(response.properties).to_not be nil
        expect(response.properties.account_type).to be == 'azure_storage_account_type'
      end
    end

    describe "get_vhd" do
      it "successfully returns virtual hard disk response" do
        response = @service.get_vhd(
          stub_storage_account_create_response, @params[:azure_os_disk_name])
        expect(response.uri).to be == 'http://teststorage.blob.core.windows.net/vhds/azureosdiskname.vhd'
      end
    end

    describe "get_image_reference" do
      it "successfully returns image reference response" do
        response = @service.get_image_reference(
          @params[:azure_image_reference_publisher],
          @params[:azure_image_reference_offer],
          @params[:azure_image_reference_sku],
          @params[:azure_image_reference_version])
        expect(response.publisher).to_not be nil
        expect(response.offer).to be == 'azure_image_reference_offer'
        expect(response.sku).to_not be nil
        expect(response.version).to_not be nil
      end
    end

    describe "get_os_disk" do
      it "successfully returns os disk response" do
        response = @service.get_os_disk(
          stub_vhd_get_response,
          @params[:azure_os_disk_name],
          @params[:azure_os_disk_caching],
          @params[:azure_os_disk_create_option])
        expect(response.name).to be == 'azureosdiskname'
        expect(response.vhd.uri).to be == 'vhd_uri'
        expect(response.caching).to_not be nil
        expect(response.create_option).to_not be nil
      end
    end

    describe "create_network_profile" do
      it "successfully returns network profile response" do
        expect(@service).to receive(
          :create_virtual_network).and_return(
            stub_virtual_network_create_response)
        expect(@service).to receive(
          :create_subnet).and_return(
            stub_subnet_create_response)
        expect(@service).to receive(
          :create_network_interface).and_return(
            stub_network_interface_create_response)
        response = @service.create_network_profile(
          @network_client,
          @params,
          'Linux')
        expect(response.network_interfaces).to_not be nil
        expect(response.network_interfaces).to be_a(Array)
      end
    end

    describe "create_virtual_network" do
      it "successfully creates virtual network" do
        response = @service.create_virtual_network(
          stub_network_client('NA'),
          @params[:azure_resource_group_name],
          @params[:azure_virtual_network_name],
          @params[:azure_service_location])
        expect(response.name).to_not be nil
        expect(response.id).to_not be nil
        expect(response.location).to_not be nil
        expect(response.properties).to_not be nil
        expect(response.properties.address_space).to be == 'vnet_address_space'
      end
    end

    describe "create_subnet" do
      it "successfully creates subnet" do
        response = @service.create_subnet(
          stub_network_client('NA'),
          @params[:azure_resource_group_name],
          @params[:azure_subnet_name],
          stub_virtual_network_create_response)
        expect(response.name).to_not be nil
        expect(response.id).to_not be nil
        expect(response.location).to_not be nil
        expect(response.properties).to_not be nil
        expect(response.properties.address_prefix).to be == 'sbn_address_prefix'
      end
    end

    describe "create_network_interface" do
      it "successfully creates network interface" do
        expect(@service).to receive(
          :create_public_ip_config).and_return(
            stub_public_ip_config_create_response)
        expect(@service).to receive(
          :create_network_security_group).and_return(
            stub_network_security_group_create_response)
        response = @service.create_network_interface(
          stub_network_client('NA'),
          @params[:azure_resource_group_name],
          @params[:azure_vm_name],
          @params[:azure_service_location],
          stub_subnet_create_response,
          @params[:port],
          'NA')
        expect(response.name).to_not be nil
        expect(response.id).to_not be nil
        expect(response.location).to_not be nil
        expect(response.properties).to_not be nil
        expect(response.properties.ip_configurations).to_not be nil
        expect(response.properties.ip_configurations).to be_a(Array)
        expect(response.properties.network_security_group).to_not be nil
      end
    end

    describe "create_public_ip_config" do
      it "successfully creates public ip configuration" do
        response = @service.create_public_ip_config(
          stub_network_client('NA'),
          @params[:azure_resource_group_name],
          @params[:azure_vm_name],
          @params[:azure_service_location])
        expect(response.name).to_not be nil
        expect(response.id).to_not be nil
        expect(response.location).to_not be nil
        expect(response.properties).to_not be nil
        expect(response.properties.public_ipallocation_method).to_not be nil
        expect(response.properties.public_ipallocation_method).to be == 'Dynamic'
      end
    end

    describe "create_network_security_group" do
      it "successfully creates network security group" do
        expect(@service).to receive(
          :add_security_rule).and_return(
            stub_default_security_rule_add_response('NA'))
        response = @service.create_network_security_group(
          stub_network_client('NA'),
          @params[:azure_resource_group_name],
          @params[:azure_vm_name],
          @params[:azure_service_location],
          @params[:port],
          'NA')
        expect(response.name).to_not be nil
        expect(response.id).to_not be nil
        expect(response.location).to_not be nil
        expect(response.properties).to_not be nil
        expect(response.properties.default_security_rules).to be_a(Array)
        expect(response.properties.default_security_rules).to be == ['nsg_default_security_rules']
        expect(response.properties.security_rules).to be nil
      end
    end

    describe "add_security_rule" do
      context "for Linux" do
        before do
          @platform = 'Linux'
        end

        it "successfully adds default security rule" do
          response = @service.add_security_rule(
            @params[:port],
            "Port desc",
            "1000",
            stub_network_client(@platform),
            @params[:azure_resource_group_name],
            @params[:azure_vm_name],
            stub_network_security_group_create_response)
          expect(response.name).to_not be nil
          expect(response.id).to_not be nil
          expect(response.location).to_not be nil
          expect(response.properties).to_not be nil
          expect(response.properties.description).to be == 'Linux port.'
          expect(response.properties.destination_port_range).to be == '22'
          expect(response.properties.protocol).to be == 'Tcp'
          expect(response.properties.source_port_range).to be == '*'
          expect(response.properties.source_address_prefix).to be == '*'
          expect(response.properties.destination_address_prefix).to be == '*'
          expect(response.properties.access).to be == 'Allow'
          expect(response.properties.priority).to be == 1000
          expect(response.properties.direction).to be == 'Inbound'
        end
      end

      context "for Windows" do
        before do
          @platform = 'Windows'
        end

        it "successfully adds default security rule" do
          response = @service.add_security_rule(
            @params[:port],
            "Port desc",
            "1000",
            stub_network_client(@platform),
            @params[:azure_resource_group_name],
            @params[:azure_vm_name],
            stub_network_security_group_create_response)
            expect(response.name).to_not be nil
            expect(response.id).to_not be nil
            expect(response.location).to_not be nil
            expect(response.properties).to_not be nil
            expect(response.properties.description).to be == 'Windows port.'
            expect(response.properties.destination_port_range).to be == '3389'
            expect(response.properties.protocol).to be == 'Tcp'
            expect(response.properties.source_port_range).to be == '*'
            expect(response.properties.source_address_prefix).to be == '*'
            expect(response.properties.destination_address_prefix).to be == '*'
            expect(response.properties.access).to be == 'Allow'
            expect(response.properties.priority).to be == 1000
            expect(response.properties.direction).to be == 'Inbound'
        end
      end
    end
  end
end
