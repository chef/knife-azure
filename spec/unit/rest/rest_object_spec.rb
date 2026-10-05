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
require_relative "../../../lib/azure/resource_management/rest/rest_object"

describe Azure::ResourceManagement::Rest::RestObject do
  describe "top-level attribute access" do
    let(:data) { { "name" => "vm1", "osType" => "Linux" } }
    let(:object) { described_class.new(data) }

    it "resolves a snake_case accessor against a camelCase key" do
      expect(object.os_type).to eq("Linux")
    end

    it "resolves an accessor whose name already matches the key" do
      expect(object.name).to eq("vm1")
    end

    it "returns nil for an attribute that is not present anywhere" do
      expect(object.missing_attribute).to be_nil
    end

    it "responds_to? any attribute name" do
      expect(object.respond_to?(:anything_at_all)).to be true
    end
  end

  describe "nested properties flattening" do
    let(:data) do
      {
        "name" => "vm1",
        "properties" => {
          "provisioningState" => "Succeeded",
          "storageProfile" => { "osDisk" => { "name" => "disk1" } },
        },
      }
    end
    let(:object) { described_class.new(data) }

    it "flattens a nested properties key onto the top-level object" do
      expect(object.provisioning_state).to eq("Succeeded")
    end

    it "wraps a nested Hash value as a RestObject too" do
      expect(object.storage_profile).to be_a(described_class)
      expect(object.storage_profile.os_disk.name).to eq("disk1")
    end

    it "prefers a top-level key over the same name inside properties" do
      flat = described_class.new("name" => "top", "properties" => { "name" => "nested" })
      expect(flat.name).to eq("top")
    end
  end

  describe "#[]" do
    let(:object) { described_class.new("name" => "vm1", "tags" => { "env" => "prod" }) }

    it "looks up a key directly (no camelCase/snake_case normalization)" do
      expect(object["name"]).to eq("vm1")
    end

    it "wraps a Hash value returned via []" do
      expect(object["tags"]).to be_a(described_class)
      expect(object["tags"]["env"]).to eq("prod")
    end

    it "returns nil for a missing key" do
      expect(object["missing"]).to be_nil
    end
  end

  describe "arrays" do
    it "wraps each Hash element of an Array, leaving scalars untouched" do
      wrapped = described_class.wrap([{ "name" => "a" }, { "name" => "b" }, "scalar"])
      expect(wrapped[0]).to be_a(described_class)
      expect(wrapped[0].name).to eq("a")
      expect(wrapped[1].name).to eq("b")
      expect(wrapped[2]).to eq("scalar")
    end

    it "wraps an array nested under a property" do
      object = described_class.new("properties" => { "dataDisks" => [{ "lun" => 0 }, { "lun" => 1 }] })
      disks = object.data_disks
      expect(disks.map(&:lun)).to eq([0, 1])
    end
  end

  describe "#key?" do
    let(:object) { described_class.new("osType" => "Linux", "properties" => { "provisioningState" => "Succeeded" }) }

    it "is true for a top-level key regardless of case/underscore differences" do
      expect(object.key?(:os_type)).to be true
    end

    it "is true for a key only present under properties" do
      expect(object.key?(:provisioning_state)).to be true
    end

    it "is false for a key that is not present anywhere" do
      expect(object.key?(:does_not_exist)).to be false
    end
  end

  describe "#nil?" do
    it "is true when constructed with nil data" do
      expect(described_class.new(nil).nil?).to be true
    end

    it "is true when constructed with an empty Hash" do
      expect(described_class.new({}).nil?).to be true
    end

    it "is false when data is present" do
      expect(described_class.new("name" => "vm1").nil?).to be false
    end
  end

  describe ".wrap" do
    it "returns a RestObject unchanged" do
      object = described_class.new("name" => "vm1")
      expect(described_class.wrap(object)).to equal(object)
    end

    it "returns scalars unchanged" do
      expect(described_class.wrap("plain")).to eq("plain")
      expect(described_class.wrap(42)).to eq(42)
      expect(described_class.wrap(nil)).to be_nil
    end
  end

  describe "#to_h / #to_hash" do
    it "returns the underlying raw Hash" do
      data = { "name" => "vm1" }
      object = described_class.new(data)
      expect(object.to_h).to equal(data)
      expect(object.to_hash).to equal(data)
    end
  end
end
