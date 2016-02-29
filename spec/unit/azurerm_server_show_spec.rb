require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')
require 'ostruct'

describe Chef::Knife::AzurermServerShow do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerShow)
    Chef::Config[:knife][:azure_resource_group_name] = "RESOURCE_GROUP"
    @arm_server_instance.name_args = %w(vmname)
  end

  it "should give error if there is no server with the given name" do
    compute_client = double("ComputeManagementClient")

    expect(@arm_server_instance.service).to receive(:compute_management_client).and_return(compute_client)
    expect(compute_client).to receive_message_chain(:virtual_machines, :get, :value!)
    expect(@arm_server_instance.service).to receive(:puts).with("There is no server with name vmname or resource_group RESOURCE_GROUP. Please provide correct details.")
    @arm_server_instance.run
  end
end