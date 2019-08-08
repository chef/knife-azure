#
# Copyright:: Copyright 2010-2019, Chef Software Inc.
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

describe Chef::Knife::AzureServerList do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @server_management_instance = create_instance(Azure::ServiceManagement::ASMInterface)
    @server_instance = create_instance(Chef::Knife::AzureServerList)
  end

  it "should display DNS Name, VM Name, Status, IP Address, SSH Port, Winrm Port and RDP Port for ASM command." do
    stub_query_azure(@server_instance.service.connection)
    allow(@server_instance).to receive(:puts)
    expect(@server_instance.ui).to receive(:list)
      .with(["DNS Name", "VM Name", "Status", "IP Address", "SSH Port", "WinRM Port", "RDP Port",
        "service001.cloudapp.net", "vm002", "ready", "65.52.251.57", "22", "", "",
        "service001.cloudapp.net", "role002", "ready", "65.52.249.191", "23", "", "",
        "service001.cloudapp.net", "role001", "ready", "65.52.249.191", "22", "", "",
        "service002.cloudapp.net", "vm01", "ready", "65.52.251.144", "54047", "", "",
        "service004.cloudapp.net", "ssh-vm", "ready", "65.52.251.57", "22", "", "",
        "service004.cloudapp.net", "winrm-vm", "ready", "65.52.249.191", "", "5985", "3389",
        "vmname.cloudapp.net", "vmname", "ready", "65.52.251.57", "22", "", ""], :uneven_columns_across, 7)
    @server_instance.run
  end

  it "should return public port for Remote Desktop if set" do
    arr_hash = [{ "Name" => "PowerShell", "Vip" => "13.92.236.37", "PublicPort" => "5986", "LocalPort" => "5986" },
                { "Name" => "Remote Desktop", "Vip" => "13.92.236.37", "PublicPort" => "3389", "LocalPort" => "3389" }]
    rdp_port = @server_management_instance.rdp_port(arr_hash)
    expect(rdp_port).to be == "3389"
  end

  it "should return empty port for Remote Desktop if not set" do
    arr_hash = [{ "Name" => "PowerShell", "Vip" => "13.92.236.37", "PublicPort" => "5986", "LocalPort" => "5986" }]
    rdp_port = @server_management_instance.rdp_port(arr_hash)
    expect(rdp_port).to be == ""
  end
end
