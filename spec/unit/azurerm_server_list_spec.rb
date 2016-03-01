require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzurermServerList do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerList)
    @compute_client = double("ComputeManagementClient")

    @server = double("server", :name => "MyVM", :location => "west-us", :properties => double)
    allow(@server.properties).to receive(:provisioning_state).and_return("running")
    allow(@server.properties).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("linux")
  end

  it "should display only labels if there are no servers" do
    expect(@arm_server_instance.service).to receive(:compute_management_client).and_return(@compute_client)
    expect(@compute_client).to receive_message_chain(:virtual_machines, :list_all, :value!, :body, :value).and_return([])
    expect(@arm_server_instance.service).to receive(:display_list).with(@arm_server_instance.service.ui, ["VM Name", "Location", "Provisioning State", "OS Type"],[])
    @arm_server_instance.run
  end

  it "should display VM Name, Location, Provisioning State and OS Type" do
    expect(@arm_server_instance.service).to receive(:compute_management_client).and_return(@compute_client)
    expect(@compute_client).to receive_message_chain(:virtual_machines, :list_all, :value!, :body, :value).and_return([@server])
    #output_row is based on the @server double object
    output_row = [@server.name, @server.location, "ready", @server.properties.storage_profile.os_disk.os_type]
    expect(@arm_server_instance.service).to receive(:display_list).with(@arm_server_instance.service.ui, ["VM Name", "Location", "Provisioning State", "OS Type"], output_row)
    @arm_server_instance.run
  end
end