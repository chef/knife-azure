require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureAgList do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    @server_instance = create_instance(Chef::Knife::AzureVnetList)
    Chef::Config[:knife][:azure_api_mode] = "asm"
    stub_query_azure(@server_instance.service.connection)
    allow(@server_instance).to receive(:puts)
  end

  it 'should display Name, Affinity Group, and State columns.' do
    expect(@server_instance.ui).to receive(:list).with(
      ['Name', 'Affinity Group', 'State',
       'jm-vnet-test', 'jm-affinity-group', 'Created',
       'vnet-test-2', 'test', 'Created',
       'vnname', 'agname', 'Created'],
      :uneven_columns_across,
      3
    )
    @server_instance.run
  end

end
