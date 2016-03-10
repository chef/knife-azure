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
    @network_client = double("NetworkManagementClient")
    allow(@arm_server_instance.service).to receive(:compute_management_client).and_return(@compute_client)    
    allow(@arm_server_instance.service).to receive(:network_resource_client).and_return(@network_client)
  end

  it "should give error if there is no server with the given name" do
    expect(@compute_client).to receive_message_chain(:virtual_machines, :get, :value!)
    expect(@arm_server_instance.service).to receive(:puts).with("There is no server with name vmname or resource_group RESOURCE_GROUP. Please provide correct details.")
    @arm_server_instance.run
  end
  
  it "should give display Server Name, Size, Provisioning State, Location, Publisher, Offer, Sku, Version, OS Type, Public IP address & FQDN" do
    @server = double("Promise", :name => "vmname", :location => "westus", :properties => double)
    @network_interface_data = double("Promise", :properties => double)
    @public_ip_data =  double("Promise", :properties => double)
    @public_ip_id_data = double(:id => double)
    network_interface_id ="/subscriptions/xxx-xx-xxx-xxxxx/resourceGroups/xxxxxxx/providers/Microsoft.Network/networkInterfaces/myVMNic"
    network_interface_name = "myVMNIC"
    public_ip_id = "/subscriptions/xxx-xx-xxx-xxxxx/resourceGroups/xxxxxxx/providers/Microsoft.Network/publicIPAddresses/myPublicIP"
    public_ip_name = "mypublicip"
    allow(@server.properties).to receive_message_chain(:hardware_profile, :vm_size).and_return("Standard_A1")
    allow(@server.properties).to receive(:provisioning_state).and_return("Succeeded")
    allow(@server.properties).to receive_message_chain(:storage_profile, :image_reference, :publisher).and_return("Canonical")
    allow(@server.properties).to receive_message_chain(:storage_profile, :image_reference, :offer).and_return("UbuntuServer")
    allow(@server.properties).to receive_message_chain(:storage_profile, :image_reference, :sku).and_return("12.04.5-LTS")
    allow(@server.properties).to receive_message_chain(:storage_profile, :image_reference, :version).and_return("latest")
    allow(@server.properties).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("Linux")
    allow(@public_ip_data.properties).to receive_message_chain(:ip_address).and_return("23.3.4.1")
    allow(@public_ip_data.properties).to receive_message_chain(:dns_settings, :fqdn).and_return("test.westus.cloudapp.azure.com")
    allow(@server.properties).to receive_message_chain(:network_profile, :network_interfaces).and_return(['network_interfaces'])
    allow(@server.properties.network_profile.network_interfaces[0]).to receive_message_chain(:id).and_return(network_interface_id)
    expect(network_interface_id).to receive(:split).with("/").and_return(network_interface_name)
    allow(@network_interface_data.properties).to receive_message_chain(:ip_configurations).and_return(['ip_configurations'])
    allow(@network_interface_data.properties.ip_configurations[0]).to receive_message_chain(:properties, :public_ipaddress).and_return(@public_ip_id_data)
    allow(@public_ip_id_data).to receive_message_chain(:id).and_return(public_ip_id)
    expect(public_ip_id).to receive(:split).with("/").and_return(public_ip_name)
    expect(@compute_client).to receive_message_chain(:virtual_machines, :get, :value!, :body).and_return(@server)
    expect(@network_client).to receive_message_chain(:network_interfaces, :get, :value!, :body).and_return(@network_interface_data)
    expect(@network_client).to receive_message_chain(:public_ipaddresses, :get, :value!, :body).and_return(@public_ip_data)  

    details = [ "Server Name", @server.name, 
                "Size", @server.properties.hardware_profile.vm_size, 
                "Provisioning State", @server.properties.provisioning_state, 
                "Location", @server.location, 
                "Publisher",  @server.properties.storage_profile.image_reference.publisher, 
                "Offer", @server.properties.storage_profile.image_reference.offer, 
                "Sku", @server.properties.storage_profile.image_reference.sku, 
                "Version", @server.properties.storage_profile.image_reference.version, 
                "OS Type", @server.properties.storage_profile.os_disk.os_type,
                "Public IP address", @public_ip_data.properties.ip_address,
                "FQDN", @public_ip_data.properties.dns_settings.fqdn]

    expect(@arm_server_instance.service.ui).to receive(:list).with(details, :columns_across, 2)
    @arm_server_instance.run  
  end 

  it "should give display Server Name, Size, Provisioning State, Location, Publisher, Offer, Sku, Version, OS Type. Public IP address & FQDN value is empty as Public Ip address is not allocated to VM" do
    @server = double("Promise", :name => "vmname", :location => "westus", :properties => double)
    @network_interface_data = double("Promise", :properties => double)
    public_ip_data = nil
    public_ip_id_data = nil
    network_interface_id = "/subscriptions/xxx-xx-xxx-xxxxx/resourceGroups/xxxxxxx/providers/Microsoft.Network/networkInterfaces/myVMNic"
    network_interface_name = "myVMNIC"
    allow(@server.properties).to receive_message_chain(:hardware_profile, :vm_size).and_return("Standard_A1")
    allow(@server.properties).to receive(:provisioning_state).and_return("Succeeded")
    allow(@server.properties).to receive_message_chain(:storage_profile, :image_reference, :publisher).and_return("Canonical")
    allow(@server.properties).to receive_message_chain(:storage_profile, :image_reference, :offer).and_return("UbuntuServer")
    allow(@server.properties).to receive_message_chain(:storage_profile, :image_reference, :sku).and_return("12.04.5-LTS")
    allow(@server.properties).to receive_message_chain(:storage_profile, :image_reference, :version).and_return("latest")
    allow(@server.properties).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("Linux")
    allow(@server.properties).to receive_message_chain(:network_profile, :network_interfaces).and_return(['network_interfaces'])
    allow(@server.properties.network_profile.network_interfaces[0]).to receive_message_chain(:id).and_return(network_interface_id)
    expect(network_interface_id).to receive(:split).with("/").and_return(network_interface_name)
    allow(@network_interface_data.properties).to receive_message_chain(:ip_configurations).and_return(['ip_configurations'])
    allow(@network_interface_data.properties.ip_configurations[0]).to receive_message_chain(:properties, :public_ipaddress).and_return(public_ip_id_data)
    expect(@compute_client).to receive_message_chain(:virtual_machines, :get, :value!, :body).and_return(@server)
    expect(@network_client).to receive_message_chain(:network_interfaces, :get, :value!, :body).and_return(@network_interface_data)

    details = [ "Server Name", @server.name,
                "Size", @server.properties.hardware_profile.vm_size,
                "Provisioning State", @server.properties.provisioning_state,
                "Location", @server.location,
                "Publisher",  @server.properties.storage_profile.image_reference.publisher,
                "Offer", @server.properties.storage_profile.image_reference.offer,
                "Sku", @server.properties.storage_profile.image_reference.sku,
                "Version", @server.properties.storage_profile.image_reference.version,
                "OS Type", @server.properties.storage_profile.os_disk.os_type,
                "Public IP address", " -- ",
                "FQDN", " -- "]
    
    expect(@arm_server_instance.service.ui).to receive(:list).with(details, :columns_across, 2)
    @arm_server_instance.run
  end

end
