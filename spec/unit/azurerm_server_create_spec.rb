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

      allow(@arm_server_instance.service).to receive(
        :resource_management_client).and_return(
          @resource_client)
      allow(@arm_server_instance.service).to receive(
        :compute_management_client).and_return(
          @compute_client)
      allow(@arm_server_instance.service).to receive(
        :storage_management_client).and_return(
          @storage_client)
      allow(@arm_server_instance.service).to receive(
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
        expect(@arm_server_instance.service).to receive(
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
          allow(@arm_server_instance.service).to receive(
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
          expect(@arm_server_instance.service).to receive(
            :create_virtual_machine).exactly(1).and_return(
              stub_virtual_machine_create_response)
          expect(@arm_server_instance.service).to receive(
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
          allow(@arm_server_instance.service).to receive(
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
          expect(@arm_server_instance.service).to receive(
            :create_virtual_machine).exactly(1).and_return(
              stub_virtual_machine_create_response)
          expect(@arm_server_instance.service).to receive(
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
  end
end
