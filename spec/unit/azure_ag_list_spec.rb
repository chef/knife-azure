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
    @server_instance = Chef::Knife::AzureAgList.new
    {
      azure_subscription_id: "azure_subscription_id",
      azure_mgmt_cert: @cert_file,
      azure_api_host_name: "preview.core.windows-int.net",
      azure_service_location: "West Europe",
      azure_source_image: "SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd",
      azure_dns_name: "service001",
      azure_vm_name: "vm01",
      azure_storage_account: "ka001testeurope",
      azure_vm_size: "Small",
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    stub_query_azure(@server_instance.service.connection)
    allow(@server_instance).to receive(:items).and_return(:true)
    allow(@server_instance).to receive(:puts)
  end

  it "should display Name, Location, and Description columns." do
    expect(@server_instance.ui).to receive(:list).with(
      ["Name", "Location", "Description",
       "agname", "West US", "agdesc",
       "jm-affinity-group", "West US", "",
       "test", "West US", "testdesc"
      ],
      :uneven_columns_across,
      3
    )
    @server_instance.run
  end

end
