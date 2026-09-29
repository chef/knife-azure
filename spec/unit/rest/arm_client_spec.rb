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
require_relative "../../../lib/azure/resource_management/rest/arm_client"

describe Azure::ResourceManagement::Rest::ArmClient do
  let(:http) { double("Http") }
  let(:environment) { Azure::ResourceManagement::Rest::Environments.default }
  let(:client) { described_class.new("sub-123", http, environment) }

  def resp(body)
    double("response", body: body)
  end

  describe "#create_vm_extension" do
    it "polls the async PUT and then GETs the extension resource (not the status doc)" do
      url = "https://management.azure.com/subscriptions/sub-123/resourceGroups/rg" \
            "/providers/Microsoft.Compute/virtualMachines/vm/extensions/ChefClient" \
            "?api-version=#{described_class::COMPUTE_API_VERSION}"

      # request_and_poll resolves to an operation-status document ...
      expect(http).to receive(:request_and_poll)
        .with(:put, url, { "name" => "ChefClient" })
        .and_return("status" => "Succeeded")
      # ... so the resource itself must come from a follow-up GET.
      expect(http).to receive(:get).with(url).and_return(
        resp("name" => "ChefClient", "id" => "/subscriptions/sub-123/.../ChefClient")
      )

      result = client.create_vm_extension("rg", "vm", "ChefClient", { "name" => "ChefClient" })
      expect(result.name).to eq("ChefClient")
      expect(result.id).to eq("/subscriptions/sub-123/.../ChefClient")
    end
  end

  describe "#resource_group_exist?" do
    it "returns true when the HEAD request succeeds" do
      expect(http).to receive(:head).and_return(resp(nil))
      expect(client.resource_group_exist?("rg")).to be true
    end

    it "returns false when the HEAD raises a 404 OperationError" do
      allow(http).to receive(:head).and_raise(
        Azure::ResourceManagement::Rest::OperationError.new("not found", http_status: 404)
      )
      expect(client.resource_group_exist?("rg")).to be false
    end

    it "re-raises OperationErrors that are not 404" do
      allow(http).to receive(:head).and_raise(
        Azure::ResourceManagement::Rest::OperationError.new("boom", http_status: 500)
      )
      expect { client.resource_group_exist?("rg") }.to raise_error(
        Azure::ResourceManagement::Rest::OperationError
      )
    end
  end

  describe "#get_virtual_machine" do
    it "GETs the VM URL and exposes SDK-style dot notation over camelCase JSON" do
      url = "https://management.azure.com/subscriptions/sub-123/resourceGroups/rg" \
            "/providers/Microsoft.Compute/virtualMachines/vm" \
            "?api-version=#{described_class::COMPUTE_API_VERSION}"
      expect(http).to receive(:get).with(url).and_return(
        resp(
          "name" => "vm",
          "properties" => {
            "provisioningState" => "Succeeded",
            "storageProfile" => { "osDisk" => { "osType" => "Linux" } },
          }
        )
      )

      vm = client.get_virtual_machine("rg", "vm")
      expect(vm.name).to eq("vm")
      expect(vm.provisioning_state).to eq("Succeeded")
      expect(vm.storage_profile.os_disk.os_type).to eq("Linux")
    end
  end

  describe "#list_virtual_machines" do
    it "collects paged results and wraps each entry" do
      url = "https://management.azure.com/subscriptions/sub-123/resourceGroups/rg" \
            "/providers/Microsoft.Compute/virtualMachines" \
            "?api-version=#{described_class::COMPUTE_API_VERSION}"
      expect(http).to receive(:get_all).with(url).and_return(
        [{ "name" => "a" }, { "name" => "b" }]
      )

      expect(client.list_virtual_machines("rg").map(&:name)).to eq(%w{a b})
    end
  end
end
