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

describe Chef::Knife::AzureInternalLbCreate do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @server_instance = create_instance(Chef::Knife::AzureInternalLbCreate)
    @connection = @server_instance.service.connection
    stub_query_azure(@connection)
    allow(@server_instance).to receive(:puts)
    allow(@server_instance).to receive(:print)
  end

  it "should fail missing args." do
    expect(@connection.lbs).to_not receive(:create)
    expect(@server_instance.ui).to receive(:error)
    expect { @server_instance.run }.to raise_error(SystemExit)
  end

  it "should succeed." do
    Chef::Config[:knife][:azure_load_balancer] = "new-lb"
    Chef::Config[:knife][:azure_lb_static_vip] = "10.3.3.3"
    Chef::Config[:knife][:azure_subnet_name] = "vnet"
    Chef::Config[:knife][:azure_dns_name] = "vmname"
    expect(@server_instance.service.connection.lbs).to receive(:create).with(
      azure_load_balancer: "new-lb",
      azure_lb_static_vip: "10.3.3.3",
      azure_subnet_name: "vnet",
      azure_dns_name: "vmname"
    ).and_call_original
    expect(@server_instance.ui).to_not receive(:warn)
    expect(@server_instance.ui).to_not receive(:error)
    @server_instance.run
  end
end
