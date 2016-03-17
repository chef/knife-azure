#
# Author:: Aliasgar Batterywala (<aliasgar.batterywala@clogeny.com>)
# Copyright:: Copyright (c) 2016 Opscode, Inc.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')
require 'chef/knife/bootstrap'

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
      :rdp_port => '3389',
      :ssh_port => '22',
      :chef_extension_publisher => 'chef_extension_publisher',
      :chef_extension => 'chef_extension',
      :chef_extension_version => '11.10.1',
      :chef_extension_public_param => 'chef_extension_public_param',
      :chef_extension_private_param => 'chef_extension_private_param',
      :latest_chef_extension_version => '1210.12'
    }

    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:read).and_return('foo')
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
      allow(@arm_server_instance).to receive(
            :msg_server_summary)
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
        expect(@service).to_not receive(:create_resource_group)
        @arm_server_instance.run
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
            :ssh_user => 'ssh_user'
          }.each do |key, value|
              Chef::Config[:knife][key] = value
            end

          expect(@arm_server_instance).to receive(
            :is_image_windows?).at_least(3).and_return(false)

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
            :create_vm_extension).exactly(1).and_return(
              stub_vm_extension_create_response('NA'))
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
            :winrm_user => 'winrm_user'
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

        it "create virtual machine when it does not exist already and also installs extension on it" do
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
            :create_vm_extension).exactly(1).and_return(
              stub_vm_extension_create_response('NA'))
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
          stub_compute_client('NA'), @params, 'Linux')
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
          expect(response.rdpport).to be == '3389'
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
        expect(response.location).to_not be nil
        expect(response.properties).to_not be nil
        expect(response.properties.account_type).to be == 'azure_storage_account_type'
      end
    end

    describe "get_vhd" do
      it "successfully returns virtual hard disk response" do
        response = @service.get_vhd(
          @params[:azure_storage_account], @params[:azure_os_disk_name])
        expect(response.uri).to be == 'http://azurestorageaccount.blob.core.windows.net/vhds/azureosdiskname.vhd'
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
            @params[:ssh_port],
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
            @params[:rdp_port],
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

    describe "create_vm_extension" do
      context "when user has supplied chef extension version value" do
        it "successfully creates virtual machine extension with the user supplied version value" do
          expect(@service).to_not receive(:get_latest_chef_extension_version)
          response = @service.create_vm_extension(
            stub_compute_client('yes'),
            @params)
          expect(response.name).to be == 'test-vm-ext'
          expect(response.id).to_not be nil
          expect(response.type).to be == 'Microsoft.Compute/virtualMachines/extensions'
          expect(response.location).to_not be nil
          expect(response.properties).to_not be nil
          expect(response.properties.publisher).to be == 'Ext_Publisher'
          expect(response.properties.type).to be == 'Ext_Type'
          expect(response.properties.type_handler_version).to be == '11.10.1'
          expect(response.properties.provisioning_state).to be == 'Succeeded'
        end
      end

      context "when user has not supplied chef extension version value" do
        before do
          @params.delete(:chef_extension_version)
        end

        it "successfully creates virtual machine extension with the latest version" do
          expect(@service).to receive(:get_latest_chef_extension_version)
          response = @service.create_vm_extension(
            stub_compute_client('no'),
            @params)
          expect(response.name).to be == 'test-vm-ext'
          expect(response.id).to_not be nil
          expect(response.type).to be == 'Microsoft.Compute/virtualMachines/extensions'
          expect(response.location).to_not be nil
          expect(response.properties).to_not be nil
          expect(response.properties.publisher).to be == 'Ext_Publisher'
          expect(response.properties.type).to be == 'Ext_Type'
          expect(response.properties.type_handler_version).to be == '1210.12'
          expect(response.properties.provisioning_state).to be == 'Succeeded'
        end
      end
    end

    describe "get_latest_chef_extension_version" do
      it "successfully returns latest Chef Extension version" do
        response = @service.get_latest_chef_extension_version(
          stub_compute_client('NA'), @params)
        expect(response).to be == '1210.*'
      end
    end

    describe "bootstrap protocol cloud-api" do
      before do
        allow(@arm_server_instance).to receive(:msg_server_summary)
        Chef::Config[:knife][:run_list] = ["getting-started"]
        Chef::Config[:knife][:validation_client_name] = "testorg-validator"
        Chef::Config[:knife][:chef_server_url] = "https://api.opscode.com/organizations/testorg"
      end

      after do
        Chef::Config[:knife].delete(:run_list)
        Chef::Config[:knife].delete(:validation_client_name)
        Chef::Config[:knife].delete(:chef_server_url)
      end

      context "parameters test" do
        context "for chef_extension parameter" do
          before do
            allow(@arm_server_instance).to receive(
              :is_image_windows?).and_return(false)
          end

          it "sets correct value for Linux platform" do
            allow(@arm_server_instance).to receive(
              :is_image_windows?).and_return(false)
            @server_params = @arm_server_instance.create_server_def
            expect(@server_params[:chef_extension]).to be == 'LinuxChefClient'
          end

          it "sets correct value for Windows platform" do
            allow(@arm_server_instance).to receive(
              :is_image_windows?).and_return(true)
            @server_params = @arm_server_instance.create_server_def
            expect(@server_params[:chef_extension]).to be == 'ChefClient'
          end
        end

        it "sets correct value for chef_extension_publisher parameter" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:chef_extension_publisher]).to be == 'Chef.Bootstrap.WindowsAzure'
        end

        it "sets user supplied value for chef_extension_version parameter" do
          Chef::Config[:knife][:azure_chef_extension_version] = '1210.12'
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:chef_extension_version]).to be == '1210.12'
        end

        it "sets nil value for chef_extension_version parameter when user has not supplied any value for it" do
          Chef::Config[:knife].delete(:azure_chef_extension_version)
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:chef_extension_version]).to be nil
        end

        it "sets correct config for chef_extension_public_param parameter" do
          allow(@arm_server_instance).to receive(
            :get_chef_extension_public_params).and_return(
              'public_params')
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:chef_extension_public_param]).to be == 'public_params'
        end

        it "sets correct config for chef_extension_private_param parameter" do
          allow(@arm_server_instance).to receive(
            :get_chef_extension_private_params).and_return(
              'private_params')
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:chef_extension_private_param]).to be == 'private_params'
        end
      end

      describe "get_chef_extension_name" do
        context "for Linux" do
          it "successfully returns chef extension name for Linux platform" do
            allow(@arm_server_instance).to receive(
              :is_image_windows?).and_return(false)
            response = @arm_server_instance.get_chef_extension_name
            expect(response).to be == 'LinuxChefClient'
          end
        end

        context "for Windows" do
          it "successfully returns chef extension name for Windows platform" do
            allow(@arm_server_instance).to receive(
              :is_image_windows?).and_return(true)
            response = @arm_server_instance.get_chef_extension_name
            expect(response).to be == 'ChefClient'
          end
        end
      end

      describe "get_chef_extension_publisher" do
        it "successfully returns chef extension publisher" do
          response = @arm_server_instance.get_chef_extension_publisher
          expect(response).to be == 'Chef.Bootstrap.WindowsAzure'
        end
      end

      context "get_chef_extension_public_params" do
        it "should set autoUpdateClient flag to true" do
          @arm_server_instance.config[:auto_update_client] = true
          public_config = "{\"client_rb\":\"chef_server_url \\t \\\"https://localhost:443\\\"\\nvalidation_client_name\\t\\\"chef-validator\\\"\",\"runlist\":\"\\\"getting-started\\\"\",\"autoUpdateClient\":\"true\",\"deleteChefConfig\":\"false\",\"uninstallChefClient\":\"false\",\"custom_json_attr\":{},\"bootstrap_options\":{\"chef_server_url\":\"https://localhost:443\",\"validation_client_name\":\"chef-validator\"}}"

          @arm_server_instance.get_chef_extension_public_params
        end

        it "should set autoUpdateClient flag to false" do
          @arm_server_instance.config[:auto_update_client] = false
          public_config = "{\"client_rb\":\"chef_server_url \\t \\\"https://localhost:443\\\"\\nvalidation_client_name\\t\\\"chef-validator\\\"\",\"runlist\":\"\\\"getting-started\\\"\",\"autoUpdateClient\":\"false\",\"deleteChefConfig\":\"false\",\"uninstallChefClient\":\"false\",\"custom_json_attr\":{},\"bootstrap_options\":{\"chef_server_url\":\"https://localhost:443\",\"validation_client_name\":\"chef-validator\"}}"

          @arm_server_instance.get_chef_extension_public_params
        end

        it "sets deleteChefConfig flag to true" do
          @arm_server_instance.config[:delete_chef_extension_config] = true
          public_config = "{\"client_rb\":\"chef_server_url \\t \\\"https://localhost:443\\\"\\nvalidation_client_name\\t\\\"chef-validator\\\"\",\"runlist\":\"\\\"getting-started\\\"\",\"autoUpdateClient\":\"false\",\"deleteChefConfig\":\"true\",\"uninstallChefClient\":\"false\",\"custom_json_attr\":{},\"bootstrap_options\":{\"chef_server_url\":\"https://localhost:443\",\"validation_client_name\":\"chef-validator\"}}"

          @arm_server_instance.get_chef_extension_public_params
        end

        it "sets deleteChefConfig flag to false" do
          @arm_server_instance.config[:delete_chef_extension_config] = false
          public_config = "{\"client_rb\":\"chef_server_url \\t \\\"https://localhost:443\\\"\\nvalidation_client_name\\t\\\"chef-validator\\\"\",\"runlist\":\"\\\"getting-started\\\"\",\"autoUpdateClient\":\"false\",\"deleteChefConfig\":\"false\",\"uninstallChefClient\":\"false\",\"custom_json_attr\":{},\"bootstrap_options\":{\"chef_server_url\":\"https://localhost:443\",\"validation_client_name\":\"chef-validator\"}}"

          @arm_server_instance.get_chef_extension_public_params
        end

        it "sets bootstrapVersion variable in public_config" do
          @arm_server_instance.config[:bootstrap_version] = '12.4.2'
          public_config = "{\"client_rb\":\"chef_server_url \\t \\\"https://localhost:443\\\"\\nvalidation_client_name\\t\\\"chef-validator\\\"\",\"runlist\":\"\\\"getting-started\\\"\",\"autoUpdateClient\":\"false\",\"deleteChefConfig\":\"false\",\"uninstallChefClient\":\"false\",\"custom_json_attr\":{},\"bootstrap_options\":{\"chef_server_url\":\"https://localhost:443\",\"validation_client_name\":\"chef-validator\",\"bootstrap_version\":\"12.4.2\"}}"

          @arm_server_instance.get_chef_extension_public_params
        end

        it "sets uninstallChefClient flag to false" do
          @arm_server_instance.config[:uninstall_chef_client] = false
          public_config = "{\"client_rb\":\"chef_server_url \\t \\\"https://localhost:443\\\"\\nvalidation_client_name\\t\\\"chef-validator\\\"\",\"runlist\":\"\\\"getting-started\\\"\",\"autoUpdateClient\":\"false\",\"deleteChefConfig\":\"false\",\"uninstallChefClient\":\"false\",\"custom_json_attr\":{},\"bootstrap_options\":{\"chef_server_url\":\"https://localhost:443\",\"validation_client_name\":\"chef-validator\"}}"

          @arm_server_instance.get_chef_extension_public_params
        end

        it "sets uninstallChefClient flag to true" do
          @arm_server_instance.config[:uninstall_chef_client] = true
          public_config = "{\"client_rb\":\"chef_server_url \\t \\\"https://localhost:443\\\"\\nvalidation_client_name\\t\\\"chef-validator\\\"\",\"runlist\":\"\\\"getting-started\\\"\",\"autoUpdateClient\":\"false\",\"deleteChefConfig\":\"false\",\"uninstallChefClient\":\"true\",\"custom_json_attr\":{},\"bootstrap_options\":{\"chef_server_url\":\"https://localhost:443\",\"validation_client_name\":\"chef-validator\"}}"

          @arm_server_instance.get_chef_extension_public_params
        end
      end

      context 'when validation key is not present', :chef_gte_12_only do
        before do
          allow(File).to receive(:exist?).and_return(false)
          Chef::Config[:knife] = { chef_node_name: 'foo.example.com' }
        end

        it 'calls get chef extension private params and adds client pem in json object' do
          allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:run)
          allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:client_path)
          allow(File).to receive(:read).and_return('foo')
          pri_config = { client_pem: 'foo' }
          @arm_server_instance.get_chef_extension_private_params
        end
      end

      context 'when SSL certificate file option is passed but file does not exist physically' do
        before do
          allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:run)
          allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:client_path)
          allow(File).to receive(:exist?).and_return(false)
          allow(File).to receive(:read).and_return('foo')
          @arm_server_instance.config[:cert_path] = '~/my_cert.crt'
        end

        it 'raises an error and exits' do
          expect(@arm_server_instance.ui).to receive(:error).with('Specified SSL certificate does not exist.')
          expect { @arm_server_instance.get_chef_extension_private_params }.to raise_error(SystemExit)
        end
      end

      context 'when SSL certificate file option is passed and file exist physically' do
        before do
          allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:run)
          allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:client_path)
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:read).and_return('foo')
          @arm_server_instance.config[:cert_path] = '~/my_cert.crt'
        end

        it "copies SSL certificate contents into chef_server_crt attribute of extension's private params" do
          pri_config = { validation_key: 'foo', chef_server_crt: 'foo' }
          @arm_server_instance.get_chef_extension_private_params
        end
      end

      context "when validation key is not present, using chef 11", :chef_lt_12_only do
        before do
          allow(File).to receive(:exist?).and_return(false)
        end

        it 'raises an exception if validation_key is not present in chef 11' do
          expect(@arm_server_instance.ui).to receive(:error)
          expect { @arm_server_instance.run }.to raise_error(SystemExit)
        end
      end
    end

    describe "set_default_image_reference" do
      it "raises error if both azure_image_os_type and image reference parameters are specified" do
        @arm_server_instance.config[:azure_image_os_type] = "ubuntu"
        @arm_server_instance.config[:azure_image_reference_publisher] = "publisher"
        expect(@arm_server_instance.ui).to receive(:error)
        expect{@arm_server_instance.send(:set_default_image_reference)}.to raise_error(SystemExit)
      end

      it "calls validation for azure_image_os_type if azure_image_os_type and image reference parameters are not given" do
        Chef::Config[:knife].delete(:azure_image_reference_publisher)
        Chef::Config[:knife].delete(:azure_image_reference_offer)
        Chef::Config[:knife].delete(:azure_image_reference_sku)
        expect(@arm_server_instance).to receive(:validate_arm_keys!).with(:azure_image_os_type)
        expect(@arm_server_instance).to receive(:validate_arm_keys!).with(:azure_image_reference_publisher, :azure_image_reference_offer, :azure_image_reference_sku, :azure_image_reference_version)
        @arm_server_instance.send(:set_default_image_reference)
      end

      it "sets default image reference parameters for azure_image_os_type=ubuntu" do
        @arm_server_instance.config[:azure_image_os_type] = "ubuntu"
        Chef::Config[:knife].delete(:azure_image_reference_publisher)
        Chef::Config[:knife].delete(:azure_image_reference_offer)
        Chef::Config[:knife].delete(:azure_image_reference_sku)
        @arm_server_instance.send(:set_default_image_reference)
        expect(@arm_server_instance.config[:azure_image_reference_publisher]).to be == "Canonical"
        expect(@arm_server_instance.config[:azure_image_reference_offer]).to be == "UbuntuServer"
        expect(@arm_server_instance.config[:azure_image_reference_sku]).to be == "14.04.2-LTS"
      end

      it "sets default image reference parameters for azure_image_os_type=centos" do
        @arm_server_instance.config[:azure_image_os_type] = "centos"
        Chef::Config[:knife].delete(:azure_image_reference_publisher)
        Chef::Config[:knife].delete(:azure_image_reference_offer)
        Chef::Config[:knife].delete(:azure_image_reference_sku)
        @arm_server_instance.send(:set_default_image_reference)
        expect(@arm_server_instance.config[:azure_image_reference_publisher]).to be == "OpenLogic"
        expect(@arm_server_instance.config[:azure_image_reference_offer]).to be == "CentOS"
        expect(@arm_server_instance.config[:azure_image_reference_sku]).to be == "7.1"
      end

      it "sets default image reference parameters for azure_image_os_type=windows" do
        @arm_server_instance.config[:azure_image_os_type] = "windows"
        Chef::Config[:knife].delete(:azure_image_reference_publisher)
        Chef::Config[:knife].delete(:azure_image_reference_offer)
        Chef::Config[:knife].delete(:azure_image_reference_sku)
        @arm_server_instance.send(:set_default_image_reference)
        expect(@arm_server_instance.config[:azure_image_reference_publisher]).to be == "MicrosoftWindowsServer"
        expect(@arm_server_instance.config[:azure_image_reference_offer]).to be == "WindowsServer"
        expect(@arm_server_instance.config[:azure_image_reference_sku]).to be == "2012-R2-Datacenter"
      end

      it "throws error if invalid azure_image_os_type is given" do
        @arm_server_instance.config[:azure_image_os_type] = "abc"
        Chef::Config[:knife].delete(:azure_image_reference_publisher)
        Chef::Config[:knife].delete(:azure_image_reference_offer)
        Chef::Config[:knife].delete(:azure_image_reference_sku)
        expect(@arm_server_instance.ui).to receive(:error).with("Invalid value of --azure-image-os-type. Accepted values ubuntu|centos|windows")
        expect{@arm_server_instance.send(:set_default_image_reference)}.to raise_error(SystemExit)
      end
    end
  end
end
