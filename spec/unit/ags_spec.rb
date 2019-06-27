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

describe "ags" do
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
      items = @connection.ags.all
      expect(items.length).to be > 1
      items.each do |ag|
        expect(ag.name).not_to be_nil
        expect(ag.label).not_to be_nil
        expect(ag.location).not_to be_nil
      end
    end
    it "should contain West US ag" do
      items = @connection.ags.all
      found_us = false
      items.each do |item|
        found_us = true if item.location == "West US"
      end
      expect(found_us).to be true
    end
  end

  context "create a new affinity group" do
    it "using explicity parameters it should pass in expected body" do
      params = {
        azure_ag_name: "new-ag",
        azure_ag_desc: "ag description",
        azure_location: "West US",
      }
      @connection.ags.create(params)
      expect(@postname).to eq("affinitygroups")
      expect(@postverb).to eq("post")
      expect(@postbody).to eq(readFile("create_ag_for_new-ag.xml"))
    end
  end
end
