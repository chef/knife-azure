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
    allow(@server_instance).to receive(:puts)
    allow(@server_instance).to receive(:print)
  end

  it 'should fail missing args.' do
    expect(@server_instance.connection.ags).to_not receive(:create)
    expect(@server_instance.ui).to receive(:error).twice
    expect { @server_instance.run }.to raise_error(SystemExit)
  end

  it 'should succeed.' do
    Chef::Config[:knife][:azure_affinity_group] = 'new-ag'
    Chef::Config[:knife][:azure_service_location] = 'West US'
    expect(@server_instance.connection.ags).to receive(:create).with(
      azure_ag_name: 'new-ag',
      azure_ag_desc: nil,
      azure_location: 'West US',
    ).and_call_original
    expect(@server_instance.ui).to_not receive(:warn)
    expect(@server_instance.ui).to_not receive(:error)
    @server_instance.run
  end
end
