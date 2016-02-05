require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureAgList do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    @server_instance = Chef::Knife::AzureVnetList.new
      {
        :azure_subscription_id => 'azure_subscription_id',
        :azure_mgmt_cert => @cert_file,
        :azure_api_host_name => 'preview.core.windows-int.net',
        }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    stub_list_vnets(@server_instance.service)
    allow(@server_instance).to receive(:puts)
  end

  it 'should display Name, Affinity Group, and State columns.' do
    expect(@server_instance.hl).to receive(:list).with(
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
