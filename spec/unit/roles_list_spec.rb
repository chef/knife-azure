require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')
describe "roles" do 
  include AzureSpecHelper
  include QueryAzureMock
  before do
    setup_query_azure_mock
  end
  
  it 'show all roles' do
    roles = @connection.roles.all
    roles.each do |role|
      role.name.should_not be_nil
    end
    roles.length.should == 5
  end
  specify {@connection.roles.exists('vm01').should == true}
  specify {@connection.roles.exists('vm002').should == true}
  specify {@connection.roles.exists('role001').should == true}
  specify {@connection.roles.exists('role002').should == true}
  specify {@connection.roles.exists('role002qqqqq').should == false}

  it 'each role should have values' do
    role = @connection.roles.find('vm01')
    role.name.should_not be_nil
    role.status.should_not be_nil
    role.size.should_not be_nil
    role.ipaddress.should_not be_nil
    role.sshport.should_not be_nil
    role.publicipaddress.should_not be_nil
  end
end
