require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')

describe "storageaccounts" do
  include AzureSpecHelper
  include QueryAzureMock
  
  before 'setup connection' do
    setup_query_azure_mock
  end

  context 'get all storage accounts' do
    specify {@connection.storageaccounts.all.length.should be > 0}
    it "entry fields should not be null" do
      items = @connection.storageaccounts.all
      items.each do |storageaccount|
        storageaccount.name.should_not be_nil
      end
    end
  end

  context 'check storage account existence' do
    it 'storage account should exist' do
      expect(@connection.storageaccounts.exists?("storage-service-name")).to be_true
    end
    it 'storage account should not exist' do
      expect(@connection.storageaccounts.exists?("invalid-storage-service-name")).to be_false
    end
  end

  context 'create a new storage account' do
    it 'using explicity parameters it should pass in expected body' do
      params = {
        :azure_dns_name => 'service003',
        :azure_storage_account => 'ka001testeurope',
        :storage_location => 'North Europe'
      }
      storageaccount = @connection.storageaccounts.create(params)
      @postname.should == 'storageservices'
      @postverb.should == 'post'
      Nokogiri::XML(@postbody).should be_equivalent_to(Nokogiri::XML readFile('create_storageservice_for_service003.xml'))
    end
  end

  context 'create a new storage account with affinity group' do
    it 'using explicity parameters it should pass in expected body' do
      params = {
        :azure_dns_name => 'service004',
        :azure_storage_account => 'ka001testeurope',
        :azure_affinity_group => 'test-affinity-group'
      }
      storageaccount = @connection.storageaccounts.create(params)
      @postname.should == 'storageservices'
      @postverb.should == 'post'
      Nokogiri::XML(@postbody).should be_equivalent_to(Nokogiri::XML readFile('create_storageservice_for_service004.xml'))
    end
  end

end
