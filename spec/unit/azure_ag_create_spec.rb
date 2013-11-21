require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureAgCreate do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @server_instance = Chef::Knife::AzureAgCreate.new
      {
        azure_subscription_id: 'azure_subscription_id',
        azure_mgmt_cert: @cert_file,
        azure_api_host_name: 'preview.core.windows-int.net',
      }.each do |key, value|
        Chef::Config[:knife][key] = value
      end
    stub_query_azure(@server_instance.connection)
    @server_instance.stub(:puts)
    @server_instance.stub(:print)
  end

  it 'should fail missing args.' do
    @server_instance.connection.ags.should_not_receive(:create)
    @server_instance.ui.should_receive(:error).twice
    lambda { @server_instance.run }.should raise_error SystemExit
  end

  it 'should succeed.' do
    Chef::Config[:knife][:azure_affinity_group] = 'new-ag'
    Chef::Config[:knife][:azure_service_location] = 'West US'
    @server_instance.connection.ags.should_receive(:create).with(
      azure_ag_name: 'new-ag',
      azure_ag_desc: nil,
      azure_location: 'West US',
    ).and_call_original
    @server_instance.ui.should_not_receive(:warn)
    @server_instance.ui.should_not_receive(:error)
    @server_instance.run
  end
end
