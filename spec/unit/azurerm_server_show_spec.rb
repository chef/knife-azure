#
# Copyright:: Cop#yright 2010-2019, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/../unit/query_azure_mock")

describe Chef::Knife::AzurermServerShow do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerShow)
    Chef::Config[:knife][:azure_resource_group_name] = "RESOURCE_GROUP"
    @arm_server_instance.name_args = %w{vmname}
    @compute_client = double("ComputeManagementClient")
    @network_client = double("NetworkManagementClient")
    allow(@arm_server_instance.service).to receive(:compute_management_client).and_return(@compute_client)
    allow(@arm_server_instance.service).to receive(:network_resource_client).and_return(@network_client)
    allow_any_instance_of(Chef::Knife::AzurermBase).to receive(:get_azure_cli_version).and_return("1.0.0")
  end

  it "raises error if there is no server with the given name" do
    expect(@compute_client).to receive_message_chain(:virtual_machines, :get).and_raise("ResourceNotFound")
    expect(@arm_server_instance.service).to receive(:common_arm_rescue_block)
    @arm_server_instance.run
  end

  it "displays Server Name, Size, Provisioning State, Location, Publisher, Offer, Sku, Version, OS Type, Public IP address & FQDN" do
    @server = double("Promise", name: "vmname", location: "westus")
    @network_interface_data = double
    @public_ip_data =  double
    @public_ip_id_data = double(id: double)
    network_interface_id = "/subscriptions/xxx-xx-xxx-xxxxx/resourceGroups/xxxxxxx/providers/Microsoft.Network/networkInterfaces/myVMNic"
    network_interface_name = "myVMNIC"
    public_ip_id = "/subscriptions/xxx-xx-xxx-xxxxx/resourceGroups/xxxxxxx/providers/Microsoft.Network/publicIPAddresses/myPublicIP"
    public_ip_name = "mypublicip"
    allow(@server).to receive_message_chain(:hardware_profile, :vm_size).and_return("Standard_A1_v2")
    allow(@server).to receive(:provisioning_state).and_return("Succeeded")
    allow(@server).to receive_message_chain(:storage_profile, :image_reference, :publisher).and_return("Canonical")
    allow(@server).to receive_message_chain(:storage_profile, :image_reference, :offer).and_return("UbuntuServer")
    allow(@server).to receive_message_chain(:storage_profile, :image_reference, :sku).and_return("12.04.5-LTS")
    allow(@server).to receive_message_chain(:storage_profile, :image_reference, :version).and_return("latest")
    allow(@server).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("Linux")
    allow(@public_ip_data).to receive(:ip_address).and_return("23.3.4.1")
    allow(@public_ip_data).to receive_message_chain(:dns_settings, :fqdn).and_return("test.westus.cloudapp.azure.com")
    allow(@server).to receive_message_chain(:network_profile, :network_interfaces).and_return(["network_interfaces"])
    allow(@server.network_profile.network_interfaces[0]).to receive_message_chain(:id).and_return(network_interface_id)
    expect(network_interface_id).to receive(:split).with("/").and_return(network_interface_name)
    allow(@network_interface_data).to receive(:ip_configurations).and_return(["ip_configurations"])
    allow(@network_interface_data.ip_configurations[0]).to receive(:public_ipaddress).and_return(@public_ip_id_data)
    allow(@public_ip_id_data).to receive(:id).and_return(public_ip_id)
    expect(public_ip_id).to receive(:split).with("/").and_return(public_ip_name)
    expect(@compute_client).to receive_message_chain(:virtual_machines, :get).and_return(@server)
    expect(@network_client).to receive_message_chain(:network_interfaces, :get).and_return(@network_interface_data)
    expect(@network_client).to receive_message_chain(:public_ipaddresses, :get).and_return(@public_ip_data)

    details = [ "Server Name", @server.name,
                "Size", @server.hardware_profile.vm_size,
                "Provisioning State", @server.provisioning_state,
                "Location", @server.location,
                "Publisher", @server.storage_profile.image_reference.publisher,
                "Offer", @server.storage_profile.image_reference.offer,
                "Sku", @server.storage_profile.image_reference.sku,
                "Version", @server.storage_profile.image_reference.version,
                "OS Type", @server.storage_profile.os_disk.os_type,
                "Public IP address", @public_ip_data.ip_address,
                "FQDN", @public_ip_data.dns_settings.fqdn]

    expect(@arm_server_instance.service.ui).to receive(:list).with(details, :columns_across, 2)
    @arm_server_instance.run
  end

  it "displays empty Public IP address and FQDN when Public IP address is not allocated to the VM" do
    @server = double("Promise", name: "vmname", location: "westus")
    @network_interface_data = double
    public_ip_data = nil
    public_ip_id_data = nil
    network_interface_id = "/subscriptions/xxx-xx-xxx-xxxxx/resourceGroups/xxxxxxx/providers/Microsoft.Network/networkInterfaces/myVMNic"
    network_interface_name = "myVMNIC"
    allow(@server).to receive_message_chain(:hardware_profile, :vm_size).and_return("Standard_A1_v2")
    allow(@server).to receive(:provisioning_state).and_return("Succeeded")
    allow(@server).to receive_message_chain(:storage_profile, :image_reference, :publisher).and_return("Canonical")
    allow(@server).to receive_message_chain(:storage_profile, :image_reference, :offer).and_return("UbuntuServer")
    allow(@server).to receive_message_chain(:storage_profile, :image_reference, :sku).and_return("12.04.5-LTS")
    allow(@server).to receive_message_chain(:storage_profile, :image_reference, :version).and_return("latest")
    allow(@server).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("Linux")
    allow(@server).to receive_message_chain(:network_profile, :network_interfaces).and_return(["network_interfaces"])
    allow(@server.network_profile.network_interfaces[0]).to receive_message_chain(:id).and_return(network_interface_id)
    expect(network_interface_id).to receive(:split).with("/").and_return(network_interface_name)
    allow(@network_interface_data).to receive(:ip_configurations).and_return(["ip_configurations"])
    allow(@network_interface_data.ip_configurations[0]).to receive(:public_ipaddress).and_return(public_ip_id_data)
    expect(@compute_client).to receive_message_chain(:virtual_machines, :get).and_return(@server)
    expect(@network_client).to receive_message_chain(:network_interfaces, :get).and_return(@network_interface_data)

    details = [ "Server Name", @server.name,
                "Size", @server.hardware_profile.vm_size,
                "Provisioning State", @server.provisioning_state,
                "Location", @server.location,
                "Publisher", @server.storage_profile.image_reference.publisher,
                "Offer", @server.storage_profile.image_reference.offer,
                "Sku", @server.storage_profile.image_reference.sku,
                "Version", @server.storage_profile.image_reference.version,
                "OS Type", @server.storage_profile.os_disk.os_type,
                "Public IP address", " -- ",
                "FQDN", " -- "]

    expect(@arm_server_instance.service.ui).to receive(:list).with(details, :columns_across, 2)
    @arm_server_instance.run
  end

  it "displays empty FQDN when DNS name is not defined for the VM" do
    @server = double("Promise", name: "vmname", location: "westus")
    @network_interface_data = double
    @public_ip_data =  double
    @public_ip_id_data = double(id: double)
    network_interface_id = "/subscriptions/xxx-xx-xxx-xxxxx/resourceGroups/xxxxxxx/providers/Microsoft.Network/networkInterfaces/myVMNic"
    network_interface_name = "myVMNIC"
    public_ip_id = "/subscriptions/xxx-xx-xxx-xxxxx/resourceGroups/xxxxxxx/providers/Microsoft.Network/publicIPAddresses/myPublicIP"
    public_ip_name = "mypublicip"
    allow(@server).to receive_message_chain(:hardware_profile, :vm_size).and_return("Standard_A1_v2")
    allow(@server).to receive(:provisioning_state).and_return("Succeeded")
    allow(@server).to receive_message_chain(:storage_profile, :image_reference, :publisher).and_return("Canonical")
    allow(@server).to receive_message_chain(:storage_profile, :image_reference, :offer).and_return("UbuntuServer")
    allow(@server).to receive_message_chain(:storage_profile, :image_reference, :sku).and_return("12.04.5-LTS")
    allow(@server).to receive_message_chain(:storage_profile, :image_reference, :version).and_return("latest")
    allow(@server).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("Linux")
    allow(@public_ip_data).to receive(:ip_address).and_return("23.3.4.1")
    allow(@public_ip_data).to receive(:dns_settings).and_return(nil)
    allow(@server).to receive_message_chain(:network_profile, :network_interfaces).and_return(["network_interfaces"])
    allow(@server.network_profile.network_interfaces[0]).to receive_message_chain(:id).and_return(network_interface_id)
    expect(network_interface_id).to receive(:split).with("/").and_return(network_interface_name)
    allow(@network_interface_data).to receive(:ip_configurations).and_return(["ip_configurations"])
    allow(@network_interface_data.ip_configurations[0]).to receive(:public_ipaddress).and_return(@public_ip_id_data)
    allow(@public_ip_id_data).to receive(:id).and_return(public_ip_id)
    expect(public_ip_id).to receive(:split).with("/").and_return(public_ip_name)
    expect(@compute_client).to receive_message_chain(:virtual_machines, :get).and_return(@server)
    expect(@network_client).to receive_message_chain(:network_interfaces, :get).and_return(@network_interface_data)
    expect(@network_client).to receive_message_chain(:public_ipaddresses, :get).and_return(@public_ip_data)

    details = [ "Server Name", @server.name,
                "Size", @server.hardware_profile.vm_size,
                "Provisioning State", @server.provisioning_state,
                "Location", @server.location,
                "Publisher", @server.storage_profile.image_reference.publisher,
                "Offer", @server.storage_profile.image_reference.offer,
                "Sku", @server.storage_profile.image_reference.sku,
                "Version", @server.storage_profile.image_reference.version,
                "OS Type", @server.storage_profile.os_disk.os_type,
                "Public IP address", @public_ip_data.ip_address,
                "FQDN", " -- "]

    expect(@arm_server_instance.service.ui).to receive(:list).with(details, :columns_across, 2)
    @arm_server_instance.run
  end

end
