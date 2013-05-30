require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureServerDelete do
include AzureSpecHelper
include QueryAzureMock

before do
	@server_instance = Chef::Knife::AzureServerDelete.new

	{
   	:azure_subscription_id => 'azure_subscription_id',
		:azure_mgmt_cert => 'AzureLinuxCert.pem',
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
		Chef::Config[:knife][:preserve_os_disk] = true

		@server_instance.connection.roles.should_receive(:delete).and_call_original

		# test correct params are passed to azure API.
		@server_instance.connection.should_receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001/roles/#{test_hostname}", "delete")

		@server_instance.run
	end

	it "delete multiple vm's within a hosted service when --azure-dns-name param set" do
		test_hostnames = ['vm002', 'role002', 'role001']
		@server_instance.name_args = test_hostnames

		Chef::Config[:knife][:azure_dns_name] = 'service001'
		Chef::Config[:knife][:preserve_os_disk] = true

		@server_instance.connection.roles.should_receive(:delete).exactly(3).times.and_call_original

		# test correct calls are made to azure API.
		@server_instance.connection.should_receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001/roles/#{test_hostnames[0]}", "delete")
		@server_instance.connection.should_receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001/roles/#{test_hostnames[1]}", "delete")
		@server_instance.connection.should_receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001", "delete")

		@server_instance.run
	end
end
