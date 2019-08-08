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

describe Chef::Knife::AzureAgList do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    @server_instance = create_instance(Chef::Knife::AzureVnetList)
    stub_query_azure(@server_instance.service.connection)
    allow(@server_instance).to receive(:puts)
  end

  it "should display Name, Affinity Group, and State columns." do
    expect(@server_instance.ui).to receive(:list).with(
      ["Name", "Affinity Group", "State",
       "jm-vnet-test", "jm-affinity-group", "Created",
       "vnet-test-2", "test", "Created",
       "vnname", "agname", "Created"],
      :uneven_columns_across,
      3
    )
    @server_instance.run
  end
end
