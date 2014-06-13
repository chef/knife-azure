require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')

describe 'ags' do
  include AzureSpecHelper
  include QueryAzureMock

  before 'setup connection' do
    setup_query_azure_mock
  end

  context 'mock with actually retrieved values' do
    it 'should find strings' do
      items = @connection.ags.all
      expect(items.length).to be > 1
      items.each do |ag|
        expect(ag.name).not_to be_nil
        expect(ag.label).not_to be_nil
        expect(ag.location).not_to be_nil
      end
    end
    it 'should contain West US ag' do
      items = @connection.ags.all
      found_us = false
      items.each do |item|
        found_us = true if item.location == 'West US'
      end
      expect(found_us).to be true
    end
  end

  context 'create a new affinity group' do
    it 'using explicity parameters it should pass in expected body' do
      params = {
        azure_ag_name: 'new-ag',
        azure_ag_desc: 'ag description',
        azure_location: 'West US'
      }
      @connection.ags.create(params)
      expect(@postname).to eq('affinitygroups')
      expect(@postverb).to eq('post')
      expect(Nokogiri::XML(@postbody)).to match(
        Nokogiri::XML readFile('create_ag_for_new-ag.xml')
      )
    end
  end
end