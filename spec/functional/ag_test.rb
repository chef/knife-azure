require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'ags' do
  before(:all) do
    @connection = Azure::Connection.new(TEST_PARAMS)
  end

  it 'create' do
    rsp = @connection.ags.create(azure_ag_name: 'func-test-new-ag',
                                 azure_location: 'West US')
    rsp.at_css('Status').should_not be_nil
    rsp.at_css('Status').content.should eq('Succeeded')
  end

  specify { @connection.ags.exists?('notexist').should eq(false) }
  specify { @connection.ags.exists?('func-test-new-ag').should eq(true) }

  it 'run through' do
    @connection.ags.all.each do |ag|
      ag.name.should_not be_nil
      ag.location.should_not be_nil
    end
  end
end
