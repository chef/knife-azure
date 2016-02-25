require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureServerList do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @server_instance = create_instance(Chef::Knife::AzureServerList)
    @arm_server_instance = create_arm_instance(Chef::Knife::AzureServerList)
  end

  it "should display DNS Name, VM Name, Status, IP Address, SSH Port and Winrm Port for ASM command." do
    Chef::Config[:knife][:azure_api_mode] = "asm"
    stub_query_azure(@server_instance.service.connection)
    allow(@server_instance).to receive(:puts)
    expect(@server_instance.ui).to receive(:list).
      with(["DNS Name", "VM Name", "Status", "IP Address", "SSH Port", "WinRM Port",
        "service001.cloudapp.net", "vm002", "ready", "65.52.251.57", "22", "",
        "service001.cloudapp.net", "role002", "ready", "65.52.249.191", "23", "",
        "service001.cloudapp.net", "role001", "ready", "65.52.249.191", "22", "",
        "service002.cloudapp.net", "vm01", "ready", "65.52.251.144", "54047", "",
        "service004.cloudapp.net", "ssh-vm", "ready", "65.52.251.57", "22", "",
        "service004.cloudapp.net", "winrm-vm", "ready", "65.52.249.191", "", "5985",
        "vmname.cloudapp.net", "vmname", "ready", "65.52.251.57", "22", ""], :uneven_columns_across, 6)
    @server_instance.run
  end

  it "should display VM Name, Location, Provisioning State and OS Type for ARM command." do
    Chef::Config[:knife][:azure_api_mode] = "arm"
    compute_client = double("ComputeClient")
    expect(@arm_server_instance.service).to receive(:get_compute_client).and_return(compute_client)
    expect(compute_client).to receive_message_chain(:virtual_machines, :list_all, :value!, :body, :value).and_return([])
    expect(@arm_server_instance.service).to receive(:display_list).with(@arm_server_instance.service.ui, ["VM Name", "Location", "Provisioning State", "OS Type"],[])
    @arm_server_instance.run
  end
end