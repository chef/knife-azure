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

describe "hosts" do
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

  context "get all hosts" do
    specify { expect(@connection.hosts.all.length).to be > 1 }
    it "entry fields should not be nil" do
      items = @connection.hosts.all
      items.each do |host|
        expect(host.name).to_not be nil
        expect(host.url).to_not be nil
        expect(host.label).to_not be nil
        expect(host.dateCreated).to_not be nil
        expect(host.description).to_not be nil
        expect(host.location).to_not be nil
        expect(host.dateModified).to_not be nil
        expect(host.status).to_not be nil
      end
    end
    specify { expect(@connection.hosts.exists?("notExpectedName")).to be == false }
    specify { expect(@connection.hosts.exists?("service001")).to be == true }
  end

  context "create a new host with service location" do
    it "using explicit parameters it should pass in expected body" do
      params = { :azure_dns_name => "service003", :azure_service_location => "West US", "hosted_azure_service_location" => "Windows Azure Preview" }
      host = @connection.hosts.create(params)
      expect(@postname).to be == "hostedservices"
      expect(@postverb).to be == "post"
      expect(@postbody).to eq(readFile("create_host_location.xml"))
    end
    it "using default parameters it should pass in expected body" do
      params = { azure_dns_name: "service003", azure_service_location: "West US" }
      host = @connection.hosts.create(params)
      expect(@postname).to be == "hostedservices"
      expect(@postverb).to be == "post"
      expect(@postbody).to eq(readFile("create_host_location.xml"))
    end
  end
  context "create a new host with affinity group" do
    it "using explicit parameters it should pass in expected body" do
      params = { azure_dns_name: "service003", azure_affinity_group: "test-affinity" }
      host = @connection.hosts.create(params)
      expect(@postname).to be == "hostedservices"
      expect(@postverb).to be == "post"
      expect(@postbody).to eq(readFile("create_host_affinity.xml"))
    end
  end
  context "delete a host" do
    it "should pass in correct name, verb, and body" do
      @connection.hosts.delete("service001")
      expect(@deletename).to be == "hostedservices/service001"
      expect(@deleteverb).to be == "delete"
      expect(@deletebody).to be nil
    end
  end
end
