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
      items.length.should be > 1
      items.each do |ag|
        ag.name.should_not be_nil
        ag.label.should_not be_nil
        ag.location.should_not be_nil
      end
    end
    it 'should contain West US ag' do
      items = @connection.ags.all
      found_us = false
      items.each do |item|
        found_us = true if item.location == 'West US'
      end
      found_us.should == true
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
      @postname.should eq('affinitygroups')
      @postverb.should eq('post')
      Nokogiri::XML(@postbody).should be_equivalent_to(
        Nokogiri::XML readFile('create_ag_for_new-ag.xml')
      )
    end
  end

end
