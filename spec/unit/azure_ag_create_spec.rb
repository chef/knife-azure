require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureAgCreate do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @server_instance = create_instance(Chef::Knife::AzureAgCreate)
    Chef::Config[:knife][:azure_api_mode] = "ASM"
    @connection = @server_instance.service.connection
    stub_query_azure(@connection)
    allow(@server_instance).to receive(:puts)
    allow(@server_instance).to receive(:print)
  end

  it 'should fail missing args.' do
    expect(@connection.ags).to_not receive(:create)
    expect(@server_instance.ui).to receive(:error).twice
    expect { @server_instance.run }.to raise_error(SystemExit)
  end

  it 'should succeed.' do
    Chef::Config[:knife][:azure_affinity_group] = 'new-ag'
    Chef::Config[:knife][:azure_service_location] = 'West US'
    expect(@connection.ags).to receive(:create).with(
      azure_ag_name: 'new-ag',
      azure_ag_desc: nil,
      azure_location: 'West US',
    ).and_call_original
    expect(@server_instance.ui).to_not receive(:warn)
    expect(@server_instance.ui).to_not receive(:error)
    @server_instance.run
  end
end
