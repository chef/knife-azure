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

describe "vnets" do
  before(:all) do
    @connection = Azure::Connection.new(TEST_PARAMS)
    @connection.ags.create(azure_ag_name: "func-test-agforvnet",
                           azure_location: "West US")
  end

  it "create" do
    rsp = @connection.vnets.create(
      azure_vnet_name: "func-test-new-vnet",
      azure_ag_name: "func-test-agforvnet",
      azure_address_space: "10.0.0.0/16"
    )
    rsp.at_css("Status").should_not be_nil
    rsp.at_css("Status").content.should eq("Succeeded")
  end

  specify { @connection.vnets.exists?("notexist").should eq(false) }
  specify { @connection.vnets.exists?("func-test-new-vnet").should eq(true) }

  it "run through" do
    @connection.vnets.all.each do |vnet|
      vnet.name.should_not be_nil
      vnet.affinity_group.should_not be_nil
      vnet.state.should_not be_nil
    end
  end
end
