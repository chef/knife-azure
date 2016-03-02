require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzurermServerShow do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerShow)
    Chef::Config[:knife][:azure_resource_group_name] = "RESOURCE_GROUP"
    @arm_server_instance.name_args = %w(vmname)
    @compute_client = double("ComputeManagementClient")
    expect(@arm_server_instance.service).to receive(:compute_management_client).and_return(@compute_client)    
  end

  it "should give error if there is no server with the given name" do
    expect(@compute_client).to receive_message_chain(:virtual_machines, :get, :value!)
    expect(@arm_server_instance.service).to receive(:puts).with("There is no server with name vmname or resource_group RESOURCE_GROUP. Please provide correct details.")
    @arm_server_instance.run
  end
  
  it "should give display Server Name, Size, Provisioning State, Location, Publisher, Offer, Sku, Version & OS Type" do
    @server = double("Promise", :name => "vmname", :location => "westus", :properties => double)
    allow(@server.properties).to receive_message_chain(:hardware_profile, :vm_size).and_return("Standard_A1")
    allow(@server.properties).to receive(:provisioning_state).and_return("Succeeded")
    allow(@server.properties).to receive_message_chain(:storage_profile, :image_reference, :publisher).and_return("Canonical")
    allow(@server.properties).to receive_message_chain(:storage_profile, :image_reference, :offer).and_return("UbuntuServer")
    allow(@server.properties).to receive_message_chain(:storage_profile, :image_reference, :sku).and_return("12.04.5-LTS")
    allow(@server.properties).to receive_message_chain(:storage_profile, :image_reference, :version).and_return("latest")
    allow(@server.properties).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("Linux")
    
    expect(@compute_client).to receive_message_chain(:virtual_machines, :get, :value!, :body).and_return(@server)
  
    details = [ "Server Name", @server.name, 
                "Size", @server.properties.hardware_profile.vm_size, 
                "Provisioning State", @server.properties.provisioning_state, 
                "Location", @server.location, 
                "Publisher",  @server.properties.storage_profile.image_reference.publisher, 
                "Offer", @server.properties.storage_profile.image_reference.offer, 
                "Sku", @server.properties.storage_profile.image_reference.sku, 
                "Version", @server.properties.storage_profile.image_reference.version, 
                "OS Type", @server.properties.storage_profile.os_disk.os_type]

    expect(@arm_server_instance.service.ui).to receive(:list).with(details, :columns_across, 2)
    @arm_server_instance.run  
  end 

end