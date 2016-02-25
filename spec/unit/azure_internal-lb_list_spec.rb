require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureInternalLbList do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    @server_instance = Chef::Knife::AzureInternalLbList.new
      {
        :azure_subscription_id => 'azure_subscription_id',
        :azure_mgmt_cert => @cert_file,
        :azure_api_host_name => 'preview.core.windows-int.net',
        :azure_service_location => 'West Europe',
        :azure_source_image =>
            'SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd',
        :azure_dns_name => 'service001',
        :azure_vm_name => 'vm01',
        :azure_storage_account => 'ka001testeurope',
        :azure_vm_size => 'Small'
      }.each do |key, value|
          Chef::Config[:knife][key] = value
        end
    stub_query_azure(@server_instance.service.connection)
    allow(@server_instance).to receive(:items).and_return(:true)
    allow(@server_instance).to receive(:puts)
  end

    it 'should display Name, Service, Subnet, and VIP columns.' do
      expect(@server_instance.ui).to receive(:list).with(
        ['Name', 'Service', 'Subnet', 'VIP',
         'lb_name', 'service001', 'vnet1', '10.4.4.4'
        ],
        :uneven_columns_across,
        4)
      @server_instance.run
    end

end
