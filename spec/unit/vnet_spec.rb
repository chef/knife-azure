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

describe "vnets" do
  include AzureSpecHelper
  include QueryAzureMock

  before "setup connection" do
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

  context "mock with actually retrieved values" do
    it "should find strings" do
      items = @connection.vnets.all
      expect(items.length).to be > 1
      items.each do |vnet|
        expect(vnet.name).to_not be nil
        expect(vnet.affinity_group).to_not be nil
        expect(vnet.state).to_not be nil
      end
    end

    it "should find correct vnets." do
      expect(@connection.vnets.exists?("jm-vnet-test")).to eq(true)
      expect(@connection.vnets.exists?("not-there")).to eq(false)
    end

    it "should contain Created state" do
      @connection.vnets.all.each do |item|
        expect(item.state).to eq("Created")
      end
    end
  end

  context "create should" do
    it "create a vnet that does not already exist" do
      params = {
        azure_vnet_name: "new-vn",
        azure_ag_name: "someag",
        azure_address_space: "10.0.0.0/16",
        azure_subnet_name: "new-sb",
      }
      @connection.vnets.create(params)
      expect(@postname).to eq("networking/media")
      expect(@postverb).to eq("put")
      expect(@postbody).to eq(readFile("set_network_new.xml"))
    end
    it "modify an existing vnet" do
      params = {
        azure_vnet_name: "vnname",
        azure_ag_name: "new-agname",
        azure_address_space: "192.168.0.0/20",
        azure_subnet_name: "new-sb",
      }
      @connection.vnets.create(params)
      expect(@postname).to eq("networking/media")
      expect(@postverb).to eq("put")
      expect(@postbody).to eq(readFile("set_network_existing.xml"))
    end
  end
end
