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
require File.expand_path(File.dirname(__FILE__) + "/query_azure_mock")
describe "roles" do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    @server_instance = Chef::Knife::AzureServerCreate.new
    {
      azure_subscription_id: "azure_subscription_id",
      azure_mgmt_cert: @cert_file,
      azure_api_host_name: "preview.core.windows-int.net",
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    stub_query_azure (@server_instance.service.connection)
    @connection = @server_instance.service.connection
  end

  it "show all roles" do
    roles = @connection.roles.all
    roles.each do |role|
      expect(role.name).to_not be nil
    end
    expect(roles.length).to be == 7
  end
  specify { expect(@connection.roles.exists?("vm01")).to be true }
  specify { expect(@connection.roles.exists?("vm002")).to be true }
  specify { expect(@connection.roles.exists?("role001")).to be true }
  specify { expect(@connection.roles.exists?("role002")).to be true }
  specify { expect(@connection.roles.exists?("role002qqqqq")).to be false }

  it "each role should have values" do
    role = @connection.roles.find("vm01")
    expect(role.name).to_not be nil
    expect(role.status).to_not be nil
    expect(role.size).to_not be nil
    expect(role.ipaddress).to_not be nil
    expect(role.sshport).to_not be nil
    expect(role.publicipaddress).to_not be nil
  end
end
