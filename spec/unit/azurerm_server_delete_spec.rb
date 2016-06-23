require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzurermServerDelete do
  include AzureSpecHelper
  include QueryAzureMock

  describe 'delete server without deleting resource group' do
    before do
      @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerDelete)
      allow(@arm_server_instance.service.ui).to receive(:confirm).and_return (true)
      @compute_client = double("ComputeManagementClient")

      @service = @arm_server_instance.service

      Chef::Config[:knife][:azure_resource_group_name] = 'test-rg-group'
      @arm_server_instance.name_args = ['VM001']

      @server_detail = double('server', :name => "VM001", :properties => double)
      allow(@server_detail.properties).to receive_message_chain(:hardware_profile, :vm_size).and_return("10")
      allow(@server_detail.properties).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("Linux")
    end

    it "deletes server" do
      server = double('server')
      delete_server = double('delete')
      allow(delete_server).to receive_message_chain(:value!, :body)

      expect(@arm_server_instance).to receive(:validate_arm_keys!).with(:azure_resource_group_name)
      allow(@arm_server_instance.service).to receive(:compute_management_client).and_return(@compute_client)
      allow(@compute_client).to receive_message_chain(:virtual_machines, :get).with('test-rg-group', 'VM001').and_return(@server_detail)

      expect(@service).to receive(:msg_pair).with(@service.ui, 'VM Name', 'VM001')
      expect(@service).to receive(:msg_pair).with(@service.ui, 'VM Size', '10')
      expect(@service).to receive(:msg_pair).with(@service.ui, 'VM OS', 'Linux')
      allow(@compute_client).to receive_message_chain(:virtual_machines, :delete).with('test-rg-group', 'VM001').and_return(delete_server)
      expect(@service.ui).to receive(:info).once
      expect(@service.ui).to receive(:warn).twice
      @arm_server_instance.run
    end

    it "does nothing if the server is not found" do
      server = double('server', :name => 'VM002')
      expect(@arm_server_instance).to receive(:validate_arm_keys!).with(:azure_resource_group_name)
      expect(@arm_server_instance.service).to receive(:compute_management_client).and_return(@compute_client)
      expect(@compute_client).to receive_message_chain(:virtual_machines, :get).with('test-rg-group', 'VM001').and_return(server)
      expect(@service.ui).to receive(:warn).once
      @arm_server_instance.run
    end

    it "destroys the corresponding node and client if --purge is given" do
      expect(@arm_server_instance).to receive(:validate_arm_keys!).with(:azure_resource_group_name)
      allow(@service).to receive(:delete_server)
      @arm_server_instance.config[:purge] = true
      expect(@arm_server_instance).to receive(:destroy_item).twice
      @arm_server_instance.run
    end

    it "rescues exception if the delete process fails" do
      expect(@arm_server_instance).to receive(:validate_arm_keys!).with(:azure_resource_group_name)
      allow(@service).to receive(:delete_server).and_raise(MsRestAzure::AzureOperationError, "ResourceNotFound")
      allow(@service.ui).to receive(:error).twice
      @arm_server_instance.run
    end
  end

  describe "delete respective resource group along with server" do
    before do
      @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerDelete)
      allow(@arm_server_instance.service.ui).to receive(:confirm).and_return (true)
      @resource_client = double("ResourceManagementClient")
      @service = @arm_server_instance.service

      Chef::Config[:knife][:azure_resource_group_name] = 'test-rg-group'
      Chef::Config[:knife][:delete_resource_group] = true
      @arm_server_instance.name_args = ['VM001']
    end

    it "destroys the corresponding resource group if --delete-resource-group option is given" do
      server = double('server')
      allow(server).to receive_message_chain(:value!, :body).and_return(nil)
      Chef::Config[:knife][:delete_resource_group] = true
      allow(@arm_server_instance.service.ui).to receive(:confirm).and_return (true)

      expect(@arm_server_instance).to receive(:validate_arm_keys!).with(:azure_resource_group_name)
      expect(@arm_server_instance.service).to receive(:resource_management_client).and_return(@resource_client)
      expect(@resource_client).to receive_message_chain(:resource_groups, :delete).with('test-rg-group').and_return(server)
      expect(@service.ui).to receive(:warn).thrice
      expect(@service.ui).to receive(:info).twice

      @arm_server_instance.run
    end
  end
end
