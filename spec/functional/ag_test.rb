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

describe "ags" do
  before(:all) do
    @connection = Azure::Connection.new(TEST_PARAMS)
  end

  it "create" do
    rsp = @connection.ags.create(azure_ag_name: "func-test-new-ag",
                                 azure_location: "West US")
    rsp.at_css("Status").should_not be_nil
    rsp.at_css("Status").content.should eq("Succeeded")
  end

  specify { @connection.ags.exists?("notexist").should eq(false) }
  specify { @connection.ags.exists?("func-test-new-ag").should eq(true) }

  it "run through" do
    @connection.ags.all.each do |ag|
      ag.name.should_not be_nil
      ag.location.should_not be_nil
    end
  end
end
