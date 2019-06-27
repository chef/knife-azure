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

describe "disks" do
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
      items = @connection.disks.all
      expect(items.length).to be > 1
      items.each do |disk|
        expect(disk.name).to_not be nil
      end
    end
    it "should contain an attached disk" do
      items = @connection.disks.all
      count = 0
      items.each do |item|
        if item.attached == true
          count += 1
        end
      end
      expect(count).to be == 1
    end
    it "should contain unattached disks" do
      items = @connection.disks.all
      count = 0
      items.each do |item|
        if item.attached == false
          count += 1
        end
      end
      expect(count).to be == 7
    end
    it "should clear all unattached disks" do
      @connection.disks.clear_unattached
      expect(@deletecount).to be == 7
    end
  end
end
