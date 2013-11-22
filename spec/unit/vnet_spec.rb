require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')

describe 'vnets' do
  include AzureSpecHelper
  include QueryAzureMock

  before 'setup connection' do
    setup_query_azure_mock
  end

  context 'mock with actually retrieved values' do
    it 'should find strings' do
      items = @connection.vnets.all
      items.length.should be > 1
      items.each do |vnet|
        vnet.name.should_not be_nil
        vnet.affinity_group.should_not be_nil
        vnet.state.should_not be_nil
      end
    end

    it 'should find correct vnets.' do
      expect(@connection.vnets.exists?('jm-vnet-test')).to eq(true)
      expect(@connection.vnets.exists?('not-there')).to eq(false)
    end

    it 'should contain Created state' do
      @connection.vnets.all.each do |item|
        item.state.should eq('Created')
      end
    end
  end

  context 'create should' do
    it 'create a vnet that does not already exist' do
      params = {
        azure_vnet_name: 'new-vn',
        azure_ag_name: 'someag',
        azure_address_space: '10.0.0.0/16',
      }
      @connection.vnets.create(params)
      @postname.should eq('networking/media')
      @postverb.should eq('put')
      Nokogiri::XML(@postbody).should be_equivalent_to(
        Nokogiri::XML readFile('set_network_new.xml')
      )
    end
    it 'modify an existing vnet' do
      params = {
        azure_vnet_name: 'vnname',
        azure_ag_name: 'new-agname',
        azure_address_space: '192.168.0.0/20',
      }
      @connection.vnets.create(params)
      @postname.should eq('networking/media')
      @postverb.should eq('put')
      Nokogiri::XML(@postbody).should be_equivalent_to(
        Nokogiri::XML readFile('set_network_existing.xml')
      )
    end
  end

end
