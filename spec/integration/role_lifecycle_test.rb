require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe "role lifecycle" do
  Chef::Log.init()
  Chef::Log.level=:info
  before(:all) do
    connection_params = { :azure_subscription_id => "155a9851-88a8-49b4-98e4-58055f08f412",
      :azure_pem_file => "AzureLinuxCert.pem",
      :azure_host_name => "management-preview.core.windows-int.net",
      :service_name => "hostedservices"}
    @connection = Azure::Connection.new(connection_params)
    arbitrary = rand(1000) + 1
    @params = { 
      :hosted_service_name=>'service002',
      :role_name=>'role' + arbitrary.to_s,
      :host_name=>'host' + arbitrary.to_s,
      :ssh_user=>'jetstream',
      :ssh_password=>'jetstream1!',
      :media_location_prefix=>'auxpreview104',
      :source_image=>'SUSE__OpenSUSE64121-03192012-en-us-15GB',
      :role_size=>'ExtraSmall'
    }
  end
  # ToFix - breaks because it does not refresh each role
  #  within loop and does not know that it needs to delete
  #  a deployment instead of a role when it gets down to
  #  the last role in a deployment
  it 'delete everything, build out completely' do
    Chef::Log.info 'deleting any existing roles'
    @connection.roles.all.each do |role|
      Chef::Log.info 'deleting role' + role.name
      @connection.roles.delete role.name
      break
    end

    Chef::Log.info 'deleting any existing hosts'
    @connection.hosts.all.each do |host|
      Chef::Log.info 'deleting host' + host.name
      @connection.hosts.delete host.name
    end

    # create 5 new roles
    ['001', '002', '003', '004', '005'].each do |val|
      arbitrary = rand(1000) + 1
      @params[:role_name]='role' + val + arbitrary.to_s
      @params[:host_name]='host' + val
      Chef::Log.info 'creating a new role named ' + @params[:role_name]
      @connection.deploys.create(@params)
    end
    
    # refresh the roles list
    Chef::Log.info 'refreshing roles'
    @connection.roles.all

    # list the roles
    Chef::Log.info 'display roles'
    @connection.roles.roles.each do |role|
      Chef::Log.info role.name
    end
  end
  #specify {@connection.roles.exists(@params[:role_name]).should == true}
  #specify {@connection.roles.exists(@params[:role_name] + 'notexist').should == false}
end
