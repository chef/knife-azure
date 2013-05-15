require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe "role lifecycle" do
  Chef::Log.init()
  Chef::Log.level=:info
  before(:all) do
    include AzureSpecHelper
    connection_params = TEST_PARAMS
    @connection = Azure::Connection.new(connection_params)
    arbitrary = rand(1000) + 1
    @params = {
      :hosted_service_name=>'service002',
      :host_name=>'host' + arbitrary.to_s,
      :ssh_user=>'jetstream',
      :ssh_password=>'jetstream1!',
      :storage_account=>'auxpreview104',
      :source_image=>'OpenLogic__OpenLogic-CentOS-62-20120531-en-us-30GB.vhd',
      :size=>'ExtraSmall',
      :bootstrap_proto=>'ssh',
      :os_type=>'Linux'
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
      @connection.roles.delete(role.name, {:purge_os_disk => false})
      break
    end

    Chef::Log.info 'deleting any existing hosts'
    @connection.hosts.all.each do |host|
      Chef::Log.info 'deleting host' + host.name
      @connection.hosts.delete host.name
    end

    # create a new role
    arbitrary = rand(1000) + 1
    @params[:host_name]='host' + arbitrary.to_s
    Chef::Log.info 'creating a new role named ' + @params[:host_name]
    @connection.deploys.create(@params)


    # refresh the roles list
    Chef::Log.info 'refreshing roles'
    @connection.roles.all

    # list the roles
    Chef::Log.info 'display roles'
    @connection.roles.roles.each do |role|
      Chef::Log.info role.name
    end
  end
end
