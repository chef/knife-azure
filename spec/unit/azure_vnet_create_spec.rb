require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureVnetCreate do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @server_instance = Chef::Knife::AzureVnetCreate.new
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
    @server_instance.connection.vnets.should_not_receive(:create)
    @server_instance.ui.should_receive(:error).exactly(3).times
    expect { @server_instance.run }.to raise_error
  end

  it 'should succeed.' do
    Chef::Config[:knife][:azure_network_name] = 'new-net'
    Chef::Config[:knife][:azure_affinity_group] = 'ag'
    Chef::Config[:knife][:azure_address_space] = '10.0.0.0/24'
    @server_instance.connection.vnets.should_receive(:create).with(
      azure_vnet_name: 'new-net',
      azure_ag_name: 'ag',
      azure_address_space: '10.0.0.0/24',
    ).and_call_original
    @server_instance.ui.should_not_receive(:warn)
    @server_instance.ui.should_not_receive(:error)
    @server_instance.run
  end
end
