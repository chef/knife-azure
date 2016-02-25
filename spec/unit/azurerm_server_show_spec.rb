require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureRmServerShow do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    @arm_server_instance = create_arm_instance(Chef::Knife::AzureRmServerShow)
    
    #stub_query_azure(@server_instance.service.connection)
    #allow(@server_instance).to receive(:puts)
  end

  it "should display Server Name, Size, Provisioning State, Location, Publisher, Offer, Sku, Version and Operating System Type." do
  	Chef::Config[:knife][:resource_group] = "resource_group"
  	
  end
  
end    
