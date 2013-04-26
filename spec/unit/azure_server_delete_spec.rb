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
		:azure_host_name => 'preview.core.windows-int.net',
		:role_name => 'vm01',
		:service_location => 'service_location',
		:source_image => 'source_image',
		:role_size => 'role_size',
		:hosted_service_name => 'service001',
		:storage_account => 'ka001testeurope'
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

	stub_query_azure (@server_instance.connection)
	@server_instance.name_args = ['vm01']
	@server_instance.stub(:confirm).and_return(:true)

	@server_instance.stub(:puts)
    @server_instance.stub(:print)
    @server_instance.ui.stub(:warn)
end

it "server delete test" do
	@server_instance.ui.should_receive(:warn).twice
	@server_instance.connection.roles.should_receive(:delete)
	@server_instance.ui.should_not_receive(:error)
	@server_instance.run
end

it "hosted service clean up test" do
	@server_instance.connection.hosts.should_receive(:delete)
	@server_instance.run
end

end