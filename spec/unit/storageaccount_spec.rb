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

describe "storageaccounts" do
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

  context "get all storage accounts" do
    specify { expect(@connection.storageaccounts.all.length).to be > 0 }
    it "entry fields should not be null" do
      items = @connection.storageaccounts.all
      items.each do |storageaccount|
        expect(storageaccount.name).to_not be nil
      end
    end
  end

  context "check storage account existence" do
    it "storage account should exist" do
      expect(@connection.storageaccounts.exists?("storage-service-name")).to be true
    end
    it "storage account should not exist" do
      expect(@connection.storageaccounts.exists?("invalid-storage-service-name")).to be false
    end
  end

  context "create a new storage account" do
    it "using explicity parameters it should pass in expected body" do
      params = {
        azure_dns_name: "service003",
        azure_storage_account: "ka001testeurope",
        storage_location: "North Europe",
      }
      storageaccount = @connection.storageaccounts.create(params)
      expect(@postname).to be == "storageservices"
      expect(@postverb).to be == "post"
      expect(@postbody).to eq(readFile("create_storageservice_for_service003.xml"))
    end
  end

  context "create a new storage account with affinity group" do
    it "using explicity parameters it should pass in expected body" do
      params = {
        azure_dns_name: "service004",
        azure_storage_account: "ka001testeurope",
        azure_affinity_group: "test-affinity-group",
      }
      storageaccount = @connection.storageaccounts.create(params)
      expect(@postname).to be == "storageservices"
      expect(@postverb).to be == "post"
      expect(@postbody).to eq(readFile("create_storageservice_for_service004.xml"))
    end
  end

end
