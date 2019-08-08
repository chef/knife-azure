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

describe Chef::Knife::AzureVnetCreate do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @server_instance = create_instance(Chef::Knife::AzureVnetCreate)
    @connection = @server_instance.service.connection
    stub_query_azure(@connection)
    allow(@server_instance).to receive(:puts)
    allow(@server_instance).to receive(:print)
  end

  it "should fail missing args." do
    expect(@connection.vnets).to_not receive(:create)
    expect(@server_instance.ui).to receive(:error).exactly(3).times
    expect { @server_instance.run }.to raise_error(SystemExit)
  end

  it "should succeed." do
    Chef::Config[:knife][:azure_network_name] = "new-net"
    Chef::Config[:knife][:azure_affinity_group] = "ag"
    Chef::Config[:knife][:azure_address_space] = "10.0.0.0/24"
    Chef::Config[:knife][:azure_subnet_name] = "Subnet-7"
    expect(@connection.vnets).to receive(:create).with(
      azure_vnet_name: "new-net",
      azure_ag_name: "ag",
      azure_address_space: "10.0.0.0/24",
      azure_subnet_name: "Subnet-7"
    ).and_call_original
    expect(@server_instance.ui).to_not receive(:warn)
    expect(@server_instance.ui).to_not receive(:error)
    @server_instance.run
  end
end
