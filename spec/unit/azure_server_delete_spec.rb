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

describe Chef::Knife::AzureServerDelete do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @server_instance = Chef::Knife::AzureServerDelete.new
    {
      azure_subscription_id: "azure_subscription_id",
      azure_mgmt_cert: @cert_file,
      azure_api_host_name: "preview.core.windows-int.net",
      name: "vm01",
      azure_service_location: "West Europe",
      azure_source_image: "azure_source_image",
      azure_vm_size: "Small",
      azure_dns_name: "service001",
      azure_storage_account: "ka001testeurope",
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    @connection = @server_instance.service.connection
    stub_query_azure(@connection)

    # allow(@server_instance).to receive(:confirm).and_return(:true)
    allow(@server_instance.service.ui).to receive(:confirm).and_return(true)
    allow(@server_instance).to receive(:puts)
    allow(@server_instance).to receive(:print)
    allow(@server_instance.ui).to receive(:warn)
    expect(@server_instance.ui).to_not receive(:error).and_call_original
  end

  it "delete server" do
    @server_instance.name_args = ["role001"]
    expect(@server_instance.ui).to receive(:warn).twice
    expect(@server_instance.service).to receive(:delete_server).and_call_original
    expect(@server_instance.service).to receive(:msg_pair).exactly(4).times
    @server_instance.run
  end

  it "wait for server delete" do
    Chef::Config[:knife][:wait] = true
    @server_instance.name_args = ["role001"]
    expect(@server_instance.ui).to receive(:warn).twice
    expect(@server_instance.service).to receive(:delete_server).and_call_original
    expect(@server_instance.service).to receive(:msg_pair).exactly(4).times
    expect(@connection).to receive(:query_azure).with("hostedservices/service001/deployments/deployment001/roles/role001", "delete")
    # comp=media deletes associated vhd
    expect(@connection).to receive(:query_azure).with("disks/deployment001-role002-0-201241722728", "delete", "", "comp=media", true)

    @server_instance.run
  end

  it "wait for server delete and preserve_azure_vhd" do
    Chef::Config[:knife][:wait] = true
    Chef::Config[:knife][:preserve_azure_vhd] = true
    @server_instance.name_args = ["role001"]
    expect(@server_instance.ui).to receive(:warn).twice
    expect(@server_instance.service).to receive(:delete_server).and_call_original
    expect(@server_instance.service).to receive(:msg_pair).exactly(4).times
    expect(@connection).to receive(:query_azure).with("hostedservices/service001/deployments/deployment001/roles/role001", "delete")
    expect(@connection).to receive(:query_azure).with("disks/deployment001-role002-0-201241722728", "get")
    # absent comp=media param preserve vhd disk and delete os disk
    expect(@connection).to receive(:query_azure).with("disks/deployment001-role002-0-201241722728", "delete")
    @server_instance.run
  end

  it "delete everything if cloud service contains only one role and no wait and no preserve option set" do
    Chef::Config[:knife][:wait] = false
    Chef::Config[:knife][:azure_dns_name] = "service002"
    @server_instance.name_args = ["vm01"]
    expect(@server_instance.ui).to receive(:warn).twice
    expect(@server_instance.service).to receive(:delete_server).and_call_original
    expect(@server_instance.service).to receive(:msg_pair).exactly(4).times

    # comp=media deletes cloud service, role and associated disks
    expect(@connection).to receive(:query_azure).with("hostedservices/service002", "delete", "", "comp=media", false)
    @server_instance.run
  end

  it "delete everything if cloud service contains only one role and preserve-azure-dns true set and no wait and no other preserve option set" do
    Chef::Config[:knife][:wait] = false
    Chef::Config[:knife][:azure_dns_name] = "service002"
    Chef::Config[:knife][:preserve_azure_dns_name] = true
    @server_instance.name_args = ["vm01"]
    expect(@server_instance.ui).to receive(:warn).twice
    expect(@server_instance.service).to receive(:delete_server).and_call_original
    expect(@server_instance.service).to receive(:msg_pair).exactly(4).times

    # comp=media deletes role and associated disks
    expect(@connection).to receive(:query_azure).with("hostedservices/service002/deployments/testrequest", "delete", "", "comp=media", false)
    @server_instance.run
  end

  it "display valid nomenclature in delete output" do
    @server_instance.name_args = ["role001"]
    expect(@server_instance.ui).to receive(:warn).twice
    expect(@server_instance.service).to receive(:msg_pair).with(@server_instance.service.ui, "DNS Name", Chef::Config[:knife][:azure_dns_name] + ".cloudapp.net")
    expect(@server_instance.service).to receive(:msg_pair).with(@server_instance.service.ui, "VM Name", "role001")
    expect(@server_instance.service).to receive(:msg_pair).with(@server_instance.service.ui, "Size", "Small")
    expect(@server_instance.service).to receive(:msg_pair).with(@server_instance.service.ui, "Public Ip Address", "65.52.249.191")
    expect(@server_instance.service).to receive(:delete_server).and_call_original
    # expect(@server_instance.service).to receive(:msg_pair).exactly(4).times
    @server_instance.run
  end

  it "test hosted service cleanup with shared service" do
    @server_instance.name_args = ["role001"]
    expect(@server_instance.ui).to receive(:warn).twice
    expect(@server_instance.service).to receive(:delete_server).and_call_original
    expect(@server_instance.service).to receive(:msg_pair).exactly(4).times

    expect(@connection.hosts).to_not receive(:delete)
    @server_instance.run
  end

  it "dont cleanup hosted service when --preserve-azure-dns-name param set" do
    @server_instance.name_args = ["role001"]
    Chef::Config[:knife][:preserve_azure_dns_name] = true
    expect(@server_instance.ui).to receive(:warn).twice
    expect(@server_instance.service).to receive(:delete_server).and_call_original
    expect(@server_instance.service).to receive(:msg_pair).exactly(4).times

    expect(@connection.hosts).to_not receive(:delete)
    @server_instance.run
  end

  it "delete vm within a hosted service when --azure-dns-name param set" do
    test_hostname = "vm002"
    @server_instance.name_args = [test_hostname]

    Chef::Config[:knife][:azure_dns_name] = "service001"
    Chef::Config[:knife][:preserve_azure_os_disk] = true
    expect(@server_instance.service).to receive(:delete_server).and_call_original
    expect(@server_instance.service).to receive(:msg_pair).exactly(4).times

    # test correct params are passed to azure API.
    expect(@connection).to receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001/roles/#{test_hostname}", "delete")

    @server_instance.run
  end

  it "delete multiple vm's within a hosted service when --azure-dns-name param set" do
    test_hostnames = %w{vm002 role002 role001}
    @server_instance.name_args = test_hostnames

    Chef::Config[:knife][:azure_dns_name] = "service001"
    Chef::Config[:knife][:preserve_azure_os_disk] = true

    expect(@server_instance.service).to receive(:delete_server).exactly(3).times.and_call_original
    expect(@server_instance.service).to receive(:msg_pair).exactly(12).times

    # test correct calls are made to azure API.
    expect(@connection).to receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001", "delete")
    expect(@connection).to receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001/roles/#{test_hostnames[1]}", "delete")
    expect(@connection).to receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001/roles/#{test_hostnames[0]}", "delete")

    @server_instance.run
  end

  it "should preserve OS Disk when --preserve-azure-os-disk is set." do
    test_hostname = "role002"
    test_diskname = "disk1"
    @server_instance.name_args = [test_hostname]
    Chef::Config[:knife][:preserve_azure_os_disk] = true
    expect(@server_instance.service).to receive(:delete_server).exactly(:once).and_call_original
    expect(@server_instance.service).to receive(:msg_pair).exactly(4).times

    expect(@connection).to receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001/roles/#{test_hostname}", "delete").exactly(:once)
    expect(@connection).to_not receive(:query_azure).with("disks/#{test_diskname}", "delete")
    @server_instance.run
  end

  it "should delete OS Disk and VHD when --wait set and --preserve-azure-os-disk, --preserve-azure-vhd are not set." do
    Chef::Config[:knife][:wait] = true
    test_hostname = "role001"
    test_diskname = "deployment001-role002-0-201241722728"
    @server_instance.name_args = [test_hostname]
    expect(@server_instance.service).to receive(:delete_server).exactly(1).and_call_original
    expect(@server_instance.service).to receive(:msg_pair).exactly(4).times

    expect(@connection).to receive(:query_azure).with("disks/#{test_diskname}", "delete", "", "comp=media", true)
    @server_instance.run
  end

  it "should preserve VHD when --preserve-azure-vhd is set." do
    test_hostname = "role001"
    test_diskname = "deployment001-role002-0-201241722728"
    Chef::Config[:knife][:preserve_azure_vhd] = true
    @server_instance.name_args = [test_hostname]
    expect(@server_instance.service).to receive(:delete_server).exactly(1).and_call_original
    expect(@server_instance.service).to receive(:msg_pair).exactly(4).times

    expect(@connection).to receive(:query_azure).with("disks/#{test_diskname}", "delete")
    @server_instance.run
  end

  describe "Storage Account" do
    before(:each) do
      test_hostname = "role001"
      @test_storage_account = "auxpreview104imagestore"
      @server_instance.name_args = [test_hostname]
    end

    it "should be deleted when --delete-azure-storage-account is set." do
      Chef::Config[:knife][:delete_azure_storage_account] = true
      expect(@connection).to receive(:query_azure).with("storageservices/#{@test_storage_account}", "delete")
      expect(@server_instance.service).to receive(:msg_pair).exactly(4).times

      @server_instance.run
    end

    it "should not be deleted  when --delete-azure-storage-account is not set." do
      expect(@connection).to_not receive(:query_azure).with("storageservices/#{@test_storage_account}", "delete")
      expect(@server_instance.service).to receive(:msg_pair).exactly(4).times

      @server_instance.run
    end
  end

  it "should give a warning and exit when both --preserve-azure-os-disk and --delete-azure-storage-account are set." do
    test_hostname = "role001"
    Chef::Config[:knife][:preserve_azure_os_disk] = true
    Chef::Config[:knife][:delete_azure_storage_account] = true
    @server_instance.name_args = [test_hostname]
    test_storage_account = "auxpreview104imagestore"
    test_diskname = "deployment001-role002-0-201241722728"
    expect(@connection).to_not receive(:query_azure).with("disks/#{test_diskname}", "delete")
    expect(@connection).to_not receive(:query_azure).with("storageservices/#{test_storage_account}", "delete")
    expect(@server_instance.ui).to receive(:warn).with("Cannot delete storage account while keeping OS Disk. Please set any one option.")
    expect(lambda { @server_instance.validate_disk_and_storage }).to raise_error(SystemExit)
  end

  after(:each) do
    Chef::Config[:knife][:preserve_azure_os_disk] = false if Chef::Config[:knife][:preserve_azure_os_disk] # cleanup config for each run
    Chef::Config[:knife][:delete_azure_storage_account] = false if Chef::Config[:knife][:delete_azure_storage_account]
  end
end
