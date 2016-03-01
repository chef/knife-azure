require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzurermServerDelete do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerDelete)
    allow(@arm_server_instance.service.ui).to receive(:confirm).and_return (true)
  end

  it "delete server" do
    compute_client = double("ComputeManagementClient")
    @server_instance.name_args = ['role001']
    @service = @arm_server_instance.service
    Chef::Config[:knife][:azure_resource_group_name] = 'test-rg-group'
    promise = double('promise')

    @service = @arm_server_instance.service

    expect(@arm_server_instance.service).to receive(:compute_management_client).and_return(compute_client)
    allow(compute_client).to receive_message_chain(:virtual_machines, :get).with('test-rg-group', 'role001', nil, nil).and_return(promise)
    allow(promise).to receive_message_chain(:value!, :body, :name).and_return("role001")
    allow(promise).to receive_message_chain(:value!, :body, :properties, :hardware_profile, :vm_size).and_return("10")
    allow(promise).to receive_message_chain(:value!, :body, :properties, :storage_profile, :os_disk, :os_type).and_return("Linux")

    expect(@service).to receive(:msg_pair).thrice
    expect(@service.ui).to receive(:info).once

    delete_call = double('promise')
    allow(delete_call).to receive_message_chain(:value!, :body).and_return(nil)
    expect(@arm_server_instance.service).to receive(:compute_management_client).and_return(compute_client)
    allow(compute_client).to receive_message_chain(:virtual_machines, :delete).with('test-rg-group', 'role001', nil).and_return(delete_call)
    expect(@service.ui).to receive(:warn).twice
    @arm_server_instance.run
  end

  it "exit if server not found" do
    compute_client = double("ComputeManagementClient")
    @server_instance.name_args = ['role001']
    @service = @arm_server_instance.service
    Chef::Config[:knife][:azure_resource_group_name] = 'test-rg-group'
    promise = double('promise')

    expect(@arm_server_instance.service).to receive(:compute_management_client).and_return(compute_client)
    expect(compute_client).to receive_message_chain(:virtual_machines, :get).with('test-rg-group', 'role001', nil, nil).and_return(promise)
    allow(promise).to receive_message_chain(:value!).and_return(nil)
    expect(@service.ui).to receive(:warn).once
    @arm_server_instance.run
  end
end
