require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "roles" do
  before(:all) do
    @connection = Azure::Connection.new(TEST_PARAMS)
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
