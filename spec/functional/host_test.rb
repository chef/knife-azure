require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Connection" do

  before(:all) do
    @connection = Azure::Connection.new(TEST_PARAMS)
    @items = @connection.hosts.all
  end

  specify {@items.length.should be > 0}
  specify {@connection.hosts.exists("thisServiceShouldNotBeThere").should == false}
  specify{@connection.hosts.exists("service002").should == true}
  it "looking for a specific host" do
    foundNamedHost = false
    @items.each do |host|
      next unless host.name == "service002"
      foundNamedHost = true
    end
    foundNamedHost.should == true
  end
end

