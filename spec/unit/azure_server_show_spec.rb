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

describe Chef::Knife::AzureServerShow do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    @server_instance = create_instance(Chef::Knife::AzureServerShow)

    stub_query_azure(@server_instance.service.connection)
    allow(@server_instance).to receive(:puts)
  end

  it "should display server information." do
    @server_instance.name_args = %w{role206 role001 role002 vm002 vm01 ssh-vm
                                    winrm-vm vmname}
    expect(@server_instance.ui).to receive(:list).with(
      ["Role name", "role001",
       "Status", "ReadyRole",
       "Size", "Small",
       "Hosted service name", "service001",
       "Deployment name", "deployment001",
       "Host name", "role001",
       "SSH port", "22",
       "Public IP", "65.52.249.191",
       "Thumbprint", "4BAE99A617B7B4F975C51A572CB8420F66477F4C"],
      :columns_across,
      2
    )
    expect(@server_instance.ui).to receive(:list).with(
      ["Role name", "role002",
       "Status", "RoleStateUnknown",
       "Size", "Small",
       "Hosted service name", "service001",
       "Deployment name", "deployment001",
       "Host name", "role002",
       "SSH port", "23",
       "Public IP", "65.52.249.191",
       "Thumbprint", "4BAE99A617B7B4F975C51A572CB8420F66477F4C"],
      :columns_across,
      2
    )
    expect(@server_instance.ui).to receive(:list).with(
      ["Role name", "vm002",
       "Status", "ReadyRole",
       "Size", "ExtraSmall",
       "Hosted service name", "service001",
       "Deployment name", "deployment001",
       "Host name", "myVm2",
       "SSH port", "22",
       "Public IP", "65.52.251.57",
       "Thumbprint", "4BAE99A617B7B4F975C51A572CB8420F66477F4C"],
      :columns_across,
      2
    )
    expect(@server_instance.ui).to receive(:list).with(
      ["Ports open", "Local port", "IP", "Public port",
       "tcp", "66", "65.52.251.57", "66"],
      :columns_across,
      4
    ).exactly(3).times
    expect(@server_instance.ui).to receive(:list).with(
      ["Ports open", "Local port", "IP", "Public port",
       "tcp", "3389", "65.52.249.191", "3389"],
      :columns_across,
      4
    ).exactly(1).times
    expect(@server_instance.ui).to receive(:list).with(
      ["Role name", "vm01",
       "Status", "ReadyRole",
       "Size", "ExtraSmall",
       "Hosted service name", "service002",
       "Deployment name", "testrequest",
       "Host name", "myVm",
       "SSH port", "54047",
       "Public IP", "65.52.251.144",
       "Thumbprint", "4BAE99A617B7B4F975C51A572CB8420F66477F4C"],
      :columns_across,
      2
    )
    expect(@server_instance.ui).to receive(:list).with(
      ["Role name", "ssh-vm",
       "Status", "ReadyRole",
       "Size", "ExtraSmall",
       "Hosted service name", "service004",
       "Deployment name", "deployment004",
       "Host name", "ssh-vm",
       "SSH port", "22",
       "Public IP", "65.52.251.57",
       "Thumbprint", "4BAE99A617B7B4F975C51A572CB8420F66477F4C"],
      :columns_across,
      2
    )
    expect(@server_instance.ui).to receive(:list).with(
      ["Role name", "winrm-vm",
       "Status", "ReadyRole",
       "Size", "Small",
       "Hosted service name", "service004",
       "Deployment name", "deployment004",
       "Host name", "winrm-vm",
       "WinRM port", "5985",
       "Public IP", "65.52.249.191",
       "Thumbprint", "4BAE99A617B7B4F975C51A572CB8420F66477F4C"],
      :columns_across,
      2
    )
    expect(@server_instance.ui).to receive(:list).with(
      ["Role name", "vmname",
       "Status", "ReadyRole",
       "Size", "ExtraSmall",
       "Hosted service name", "vmname",
       "Deployment name", "deployment001",
       "Host name", "myVm2",
       "SSH port", "22",
       "Public IP", "65.52.251.57",
       "Thumbprint", "4BAE99A617B7B4F975C51A572CB8420F66477F4C"],
      :columns_across,
      2
    )
    @server_instance.run
  end

end
