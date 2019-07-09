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

describe Chef::Knife::AzurermServerList do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerList)
    @service = @arm_server_instance.service

    @compute_client = double("ComputeManagementClient")

    @server1 = double("server1", name: "MyVM1", id: double, location: "west-us")
    allow(@server1.id).to receive(:split).and_return(["", "subscriptions", "subscription_id", "resourcegroups", "myresourcegroup1", "Microsoft.compute", "virtualmachines", "MyVM1"])
    allow(@server1.id.split[4]).to receive(:downcase).and_return("myresourcegroup1")
    allow(@server1).to receive(:provisioning_state).and_return("running")
    allow(@server1).to receive_message_chain(
      :storage_profile, :os_disk, :os_type
    ).and_return("linux")

    @server2 = double("server2", name: "MyVM2", id: double, location: "west-us")
    allow(@server2.id).to receive(:split).and_return(["", "subscriptions", "subscription_id", "resourcegroups", "myresourcegroup2", "Microsoft.compute", "virtualmachines", "MyVM2"])
    allow(@server2.id.split[4]).to receive(:downcase).and_return("myresourcegroup2")
    allow(@server2).to receive(:provisioning_state).and_return("running")
    allow(@server2).to receive_message_chain(
      :storage_profile, :os_disk, :os_type
    ).and_return("linux")

    @server3 = double("server3", name: "MyVM3", id: double, location: "west-us")
    allow(@server3.id).to receive(:split).and_return(["", "subscriptions", "subscription_id", "resourcegroups", "myresourcegroup1", "Microsoft.compute", "virtualmachines", "MyVM3"])
    allow(@server3.id.split[4]).to receive(:downcase).and_return("myresourcegroup1")
    allow(@server3).to receive(:provisioning_state).and_return("running")
    allow(@server3).to receive_message_chain(
      :storage_profile, :os_disk, :os_type
    ).and_return("windows")

    allow(@arm_server_instance.service).to receive(
      :compute_management_client
    ).and_return(@compute_client)
    allow_any_instance_of(Chef::Knife::AzurermBase).to receive(:get_azure_cli_version).and_return("1.0.0")
  end

  context "resource_group_name is not given" do
    before do
      Chef::Config[:knife].delete(:azure_resource_group_name)
    end

    it "should display only labels if there are no servers" do
      expect(@compute_client).to receive_message_chain(
        :virtual_machines, :list_all
      ).and_return([])
      expect(@arm_server_instance.service).to receive(:display_list).with(
        @arm_server_instance.service.ui,
        ["VM Name", "Resource Group Name", "Location", "Provisioning State", "OS Type"],
        []
      )
      @arm_server_instance.run
    end

    it "should display VM Name, Location, Provisioning State and OS Type for all the VMs irrespective of the resource_group" do
      output_row = [@server1.name, @server1.id.split[4], @server1.location, @server1.provisioning_state, @server1.storage_profile.os_disk.os_type,
                    @server2.name, @server2.id.split[4], @server2.location, @server2.provisioning_state, @server2.storage_profile.os_disk.os_type,
                    @server3.name, @server3.id.split[4], @server3.location, @server3.provisioning_state, @server3.storage_profile.os_disk.os_type
                   ]
      expect(@compute_client).to receive_message_chain(
        :virtual_machines, :list_all
      ).and_return(
        [@server1, @server2, @server3]
      )
      expect(@arm_server_instance.service).to receive(:display_list).with(
        @arm_server_instance.service.ui,
        ["VM Name", "Resource Group Name", "Location", "Provisioning State", "OS Type"],
        output_row
      )
      @arm_server_instance.run
    end
  end

  context "resource_group_name is given" do
    before do
      Chef::Config[:knife][:azure_resource_group_name] = "myresourcegroup1"
    end

    it "should display only labels if there are no servers under the given resource_group" do
      expect(@compute_client).to receive_message_chain(
        :virtual_machines, :list
      ).and_return([])
      expect(@arm_server_instance.service).to receive(:display_list).with(
        @arm_server_instance.service.ui,
        ["VM Name", "Resource Group Name", "Location", "Provisioning State", "OS Type"],
        []
      )
      @arm_server_instance.run
    end

    it "should display VM Name, Location, Provisioning State and OS Type for all the VMs existing under the given resource_group" do
      output_row = [@server1.name, @server1.id.split[4], @server1.location, @server1.provisioning_state, @server1.storage_profile.os_disk.os_type,
                    @server3.name, @server3.id.split[4], @server3.location, @server3.provisioning_state, @server3.storage_profile.os_disk.os_type
                   ]
      expect(@compute_client).to receive_message_chain(
        :virtual_machines, :list
      ).and_return(
        [@server1, @server3]
      )
      expect(@arm_server_instance.service).to receive(:display_list).with(
        @arm_server_instance.service.ui,
        ["VM Name", "Resource Group Name", "Location", "Provisioning State", "OS Type"],
        output_row
      )
      @arm_server_instance.run
    end
  end
end
