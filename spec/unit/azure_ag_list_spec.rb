require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureAgList do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    @server_instance = Chef::Knife::AzureAgList.new
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
    stub_query_azure(@server_instance.connection)
    @server_instance.stub(:items).and_return(:true)
    @server_instance.stub(:puts)
  end

    it 'should display only Name and Location columns.' do
      @server_instance.hl.should_receive(:list).with(
        ['Name', 'Location', 'Description',
         'agname', 'West US', 'agdesc',
         'jm-affinity-group', 'West US', '',
         'test', 'West US', 'testdesc',
        ],
        :uneven_columns_across,
        3)
      @server_instance.run
    end

end
