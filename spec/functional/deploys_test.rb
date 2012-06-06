require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "deploys" do
  before(:all) do
    @connection = Azure::Connection.new(TEST_PARAMS)
    @deploys = @connection.deploys.all
  end

  specify {@deploys.length.should be > 0}
  it 'each deployment should have values' do
    @deploys.each do |deploy|
      deploy.name.should_not be_nil
      deploy.status.should_not be_nil
      deploy.url.should_not be_nil
      deploy.roles.length.should be > 0
    end
  end
  it 'each role should have values' do
    @deploys.each do |deploy|
        Chef::Log.info '============================='
      Chef::Log.info 'hosted service: ' + deploy.hostedservicename + '  deployment: ' + deploy.name
      deploy.roles.each do |role|
        role.name.should_not be_nil
        role.status.should_not be_nil
        role.size.should_not be_nil
        role.ipaddress.should_not be_nil
        role.sshport.should_not be_nil
        role.sshipaddress.should_not be_nil
        Chef::Log.info '============================='
        Chef::Log.info 'role: ' + role.name
        Chef::Log.info 'status: ' + role.status
        Chef::Log.info 'size: ' + role.size
        Chef::Log.info 'ip address: ' + role.ipaddress
        Chef::Log.info 'ssh port: ' + role.sshport
        Chef::Log.info 'ssh ip address: ' + role.sshipaddress
      end
    end
  end
end
