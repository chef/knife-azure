require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "roles" do
  before(:all) do
    params = { :azure_subscription_id => "155a9851-88a8-49b4-98e4-58055f08f412",
      :azure_pem_file => "AzureLinuxCert.pem",
      :azure_host_name => "management-preview.core.windows-int.net",
      :service_name => "hostedservices"}
    @connection = Azure::Connection.new(params)
    @roles = @connection.roles.all
  end

  specify {@connection.roles.exists('notexist').should == false}
  specify {@connection.roles.exists('role126').should == true}
  it 'run through roles' do
    @connection.roles.roles.each do |role|
      role.name.should_not be_nil
    end
  end
end
