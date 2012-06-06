require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Connection" do

  before(:all) do
    params = { :azure_subscription_id => "155a9851-88a8-49b4-98e4-58055f08f412",
      :azure_pem_file => "AzureLinuxCert.pem",
      :azure_host_name => "management-preview.core.windows-int.net",
      :service_name => "hostedservices"}
    @connection = Azure::Connection.new(params)
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

