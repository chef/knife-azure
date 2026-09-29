#
# Copyright:: Copyright (c) 2012-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../../spec_helper"
require_relative "../../../lib/azure/resource_management/rest/environments"

describe Azure::ResourceManagement::Rest::Environments do
  describe ".default" do
    it "points at the public cloud endpoints" do
      env = described_class.default
      expect(env.resource_manager_endpoint_url).to eq("https://management.azure.com")
      expect(env.active_directory_endpoint_url).to eq("https://login.microsoftonline.com")
      expect(env.token_audience).to eq("https://management.azure.com/")
    end
  end

  describe ".from_name" do
    it "selects the US Government cloud so tokens go to the correct ARM/AAD endpoints" do
      env = described_class.from_name("AzureUSGovernment")
      expect(env.resource_manager_endpoint_url).to eq("https://management.usgovcloudapi.net")
      expect(env.active_directory_endpoint_url).to eq("https://login.microsoftonline.us")
      expect(env.token_audience).to eq("https://management.usgovcloudapi.net/")
    end

    it "selects the China cloud" do
      env = described_class.from_name("AzureChinaCloud")
      expect(env.resource_manager_endpoint_url).to eq("https://management.chinacloudapi.cn")
    end

    it "trims surrounding whitespace on the supplied name" do
      env = described_class.from_name("  AzureUSGovernment  ")
      expect(env.resource_manager_endpoint_url).to eq("https://management.usgovcloudapi.net")
    end

    it "falls back to the public cloud for a nil name" do
      expect(described_class.from_name(nil).resource_manager_endpoint_url).to eq("https://management.azure.com")
    end

    it "falls back to the public cloud for an unknown name" do
      expect(described_class.from_name("NotACloud").resource_manager_endpoint_url).to eq("https://management.azure.com")
    end
  end

  describe ".names" do
    it "lists every supported cloud" do
      expect(described_class.names).to include(
        "AzureCloud", "AzureUSGovernment", "AzureChinaCloud", "AzureGermanCloud"
      )
    end
  end
end
