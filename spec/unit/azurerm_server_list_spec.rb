require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzurermServerList do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerList)
  end

  it "should display VM Name, Location, Provisioning State and OS Type for ARM command." do
    compute_client = double("ComputeManagementClient")
    expect(@arm_server_instance.service).to receive(:compute_management_client).and_return(compute_client)
    expect(compute_client).to receive_message_chain(:virtual_machines, :list_all, :value!, :body, :value).and_return([])
    expect(@arm_server_instance.service).to receive(:display_list).with(@arm_server_instance.service.ui, ["VM Name", "Location", "Provisioning State", "OS Type"],[])
    @arm_server_instance.run
  end
end