require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureServerDelete do
include AzureSpecHelper
include QueryAzureMock

before do
	@server_instance = Chef::Knife::AzureServerDelete.new

	{
   	:azure_subscription_id => 'azure_subscription_id',
		:azure_mgmt_cert => @cert_file,
		:azure_api_host_name => 'preview.core.windows-int.net',
		:name => 'vm01',
		:azure_service_location => 'West Europe',
		:azure_source_image => 'azure_source_image',
		:azure_vm_size => 'Small',
		:azure_dns_name => 'service001',
		:azure_storage_account => 'ka001testeurope'
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

	stub_query_azure (@server_instance.connection)

	@server_instance.stub(:confirm).and_return(:true)

	@server_instance.stub(:puts)
    @server_instance.stub(:print)
    @server_instance.ui.stub(:warn)
    @server_instance.ui.should_not_receive(:error).and_call_original
end

	it "server delete test" do
		@server_instance.name_args = ['role001']
		@server_instance.ui.should_receive(:warn).twice
		@server_instance.connection.roles.should_receive(:delete).and_call_original
		@server_instance.run
	end

	it "display valid nomenclature in delete output" do
		@server_instance.name_args = ['role001']
		@server_instance.ui.should_receive(:warn).twice
		@server_instance.should_receive(:msg_pair).with("DNS Name", Chef::Config[:knife][:azure_dns_name] + ".cloudapp.net")
		@server_instance.should_receive(:msg_pair).with("VM Name", "role001")
		@server_instance.should_receive(:msg_pair).with("Size", "Small")
		@server_instance.should_receive(:msg_pair).with("Public Ip Address", "65.52.249.191")
		@server_instance.connection.roles.should_receive(:delete).and_call_original
		@server_instance.run
	end

	it "test hosted service cleanup with shared service" do
		@server_instance.name_args = ['role001']
		@server_instance.ui.should_receive(:warn).twice
		@server_instance.connection.roles.should_receive(:delete).and_call_original
		@server_instance.connection.hosts.should_not_receive(:delete)
		@server_instance.run
	end

	it "dont cleanup hosted service when --preserve-azure-dns-name param set" do
		@server_instance.name_args = ['role001']
		Chef::Config[:knife][:preserve_azure_dns_name] = true
		@server_instance.ui.should_receive(:warn).twice
		@server_instance.connection.roles.should_receive(:delete).and_call_original
		@server_instance.connection.hosts.should_not_receive(:delete)
		@server_instance.run
	end

	it "delete vm within a hosted service when --azure-dns-name param set" do
		test_hostname = 'vm002'
		@server_instance.name_args = [test_hostname]

		Chef::Config[:knife][:azure_dns_name] = 'service001'
		Chef::Config[:knife][:preserve_azure_os_disk] = true

		@server_instance.connection.roles.should_receive(:delete).and_call_original

		# test correct params are passed to azure API.
		@server_instance.connection.should_receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001/roles/#{test_hostname}", "delete")

		@server_instance.run
	end

	it "delete multiple vm's within a hosted service when --azure-dns-name param set" do
		test_hostnames = ['vm002', 'role002', 'role001']
		@server_instance.name_args = test_hostnames

		Chef::Config[:knife][:azure_dns_name] = 'service001'
		Chef::Config[:knife][:preserve_azure_os_disk] = true

		@server_instance.connection.roles.should_receive(:delete).exactly(3).times.and_call_original

		# test correct calls are made to azure API.
		@server_instance.connection.should_receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001/roles/#{test_hostnames[0]}", "delete")
		@server_instance.connection.should_receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001/roles/#{test_hostnames[1]}", "delete")
		@server_instance.connection.should_receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001", "delete")

		@server_instance.run
	end

	it "should preserve OS Disk when --preserve-azure-os-disk is set." do
		test_hostname = 'role002'
		test_diskname = 'disk1'
		@server_instance.name_args = [test_hostname]
		Chef::Config[:knife][:preserve_azure_os_disk] = true
		@server_instance.connection.roles.should_receive(:delete).exactly(:once).and_call_original
		@server_instance.connection.should_receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001/roles/#{test_hostname}", "delete").exactly(:once)
		@server_instance.connection.should_not_receive(:query_azure).with("disks/#{test_diskname}", "delete")
		@server_instance.run
	end

	it "should delete OS Disk and VHD when --preserve-azure-os-disk and --preserve-azure-vhd are not set." do
		test_hostname = 'role001'
		test_diskname = 'deployment001-role002-0-201241722728'
		@server_instance.name_args = [test_hostname]
		@server_instance.connection.roles.should_receive(:delete).exactly(1).and_call_original
		@server_instance.connection.should_receive(:query_azure).with("disks/#{test_diskname}", "delete", "", "comp=media")
		@server_instance.run
	end

  it "should preserve VHD when --preserve-azure-vhd is set." do
    test_hostname = 'role001'
    test_diskname = 'deployment001-role002-0-201241722728'
    Chef::Config[:knife][:preserve_azure_vhd] = true
    @server_instance.name_args = [test_hostname]
    @server_instance.connection.roles.should_receive(:delete).exactly(1).and_call_original
    @server_instance.connection.should_receive(:query_azure).with("disks/#{test_diskname}", "delete")
    @server_instance.run
  end

	describe "Storage Account" do
		before(:each) do
			test_hostname = 'role001'
			@test_storage_account = 'auxpreview104imagestore'
			@server_instance.name_args = [test_hostname]
		end

		it "should be deleted when --delete-azure-storage-account is set." do
			Chef::Config[:knife][:delete_azure_storage_account] = true
			@server_instance.connection.should_receive(:query_azure).with("storageservices/#{@test_storage_account}", "delete")
			@server_instance.run
		end

		it "should not be deleted  when --delete-azure-storage-account is not set." do
			@server_instance.connection.should_not_receive(:query_azure).with("storageservices/#{@test_storage_account}", "delete")
			@server_instance.run
		end
  end

	it "should give a warning and exit when both --preserve-azure-os-disk and --delete-azure-storage-account are set." do
		test_hostname = 'role001'
		Chef::Config[:knife][:preserve_azure_os_disk] = true
		Chef::Config[:knife][:delete_azure_storage_account] = true
		@server_instance.name_args = [test_hostname]
		test_storage_account = 'auxpreview104imagestore'
		test_diskname = 'deployment001-role002-0-201241722728'
		@server_instance.connection.should_not_receive(:query_azure).with("disks/#{test_diskname}", "delete")
		@server_instance.connection.should_not_receive(:query_azure).with("storageservices/#{test_storage_account}", "delete")
		@server_instance.ui.should_receive(:warn).with("Cannot delete storage account while keeping OS Disk. Please set any one option.")
		lambda { @server_instance.validate_disk_and_storage }.should raise_error(SystemExit)
	end

	after(:each) do
		Chef::Config[:knife][:preserve_azure_os_disk] = false if Chef::Config[:knife][:preserve_azure_os_disk] #cleanup config for each run
		Chef::Config[:knife][:delete_azure_storage_account] = false if Chef::Config[:knife][:delete_azure_storage_account]
	end
end
