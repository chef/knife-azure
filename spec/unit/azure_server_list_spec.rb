require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')
describe Chef::Knife::AzureServerList do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @server_instance = create_instance(Chef::Knife::AzureServerList)
  end
  it "should display DNS Name, VM Name, Status, IP Address, SSH Port, Winrm Port and RDP Port for ASM command." do
    stub_query_azure(@server_instance.service.connection)
    allow(@server_instance).to receive(:puts)
    expect(@server_instance.ui).to receive(:list).
      with(["DNS Name", "VM Name", "Status", "IP Address", "SSH Port", "WinRM Port", "RDP Port",
        "service001.cloudapp.net", "vm002", "ready", "65.52.251.57", "22", "", "",
        "service001.cloudapp.net", "role002", "ready", "65.52.249.191", "23", "", "",
        "service001.cloudapp.net", "role001", "ready", "65.52.249.191", "22", "", "",
        "service002.cloudapp.net", "vm01", "ready", "65.52.251.144", "54047", "", "",
        "service004.cloudapp.net", "ssh-vm", "ready", "65.52.251.57", "22", "", "",
        "service004.cloudapp.net", "winrm-vm", "ready", "65.52.249.191", "", "5985", "3389",
        "vmname.cloudapp.net", "vmname", "ready", "65.52.251.57", "22", "", ""], :uneven_columns_across, 7)
    @server_instance.run
  end
end
