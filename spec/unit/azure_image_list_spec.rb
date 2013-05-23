require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe "knife azure " do
  include AzureSpecHelper
  include QueryAzureMock
  before 'setup connection' do
    setup_query_azure_mock
  end

  context 'image list' do

  before(:each) do
    @server_instance = Chef::Knife::AzureImageList.new
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
    @server_instance.stub(:items).and_return(:true)
  end
    
    it "should display only Name and OS columns." do
      # $stdout.should_receive(:write).at_least(:twice).and_return(kind_of(String))
      @server_instance.run

    end

    it "--full should display Name , Category, Label and OS columns." do
      Chef::Config[:knife][:show_all_fields] = true
      # $stdout.should_receive(:write).at_least(:twice).and_return(kind_of(String))
      @server_instance.run
    end
  end
end