require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')

describe "deploys" do
include AzureSpecHelper
  include QueryAzureMock
  before 'setup connection' do
    @server_instance = Chef::Knife::AzureServerCreate.new
    {
      :azure_subscription_id => 'azure_subscription_id',
      :azure_mgmt_cert => @cert_file,
      :azure_api_host_name => 'preview.core.windows-int.net'
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    stub_query_azure (@server_instance.service.connection)
    @connection = @server_instance.service.connection
  end

  specify {expect(@connection.deploys.all.length).to be > 0}
  it 'each deployment should have values' do
    @connection.deploys.all.each do |deploy|
      expect(deploy.name).to_not be nil
      expect(deploy.status).to_not be nil
      expect(deploy.url).to_not be nil
      expect(deploy.roles.length).to be > 0
    end
  end
  it 'each role should have values' do
    @connection.deploys.all.each do |deploy|
    #describe_deploy deploy
      deploy.roles.each do |role|
        #describe_role role
        expect(role.name).to_not be nil
        expect(role.status).to_not be nil
        expect(role.size).to_not be nil
        expect(role.ipaddress).to_not be nil
        # We either have ssh port or winrm port on a role
        expect(role.winrmport).to_not be nil if role.sshport.nil?
        expect(role.sshport).to_not be nil if role.winrmport.nil?
        expect(role.publicipaddress).to_not be nil
      end
    end
  end
  def describe_deploy(deploy)
      puts '============================='
      puts 'deployed service: ' + deploy.hostedservicename + '  deployment: ' + deploy.name
  end
  def describe_role(role)
        puts 'role: ' + role.name
        puts 'status: ' + role.status
        puts 'size: ' + role.size
        puts 'ip address: ' + role.ipaddress
        puts 'ssh port: ' + role.sshport
        puts 'ssh ip address: ' + role.publicipaddress
        role.tcpports.each do |port|
          puts ' tcp: ' + port['Name'] + ' ' + port['Vip'] + ' ' +
            port['PublicPort'] + ' ' + port['LocalPort']
        end
        role.udpports.each do |port|
          puts ' udp: ' + port['Name'] + ' ' + port['Vip'] + ' ' +
            port['PublicPort'] + ' ' + port['LocalPort']
        end
        puts '============================='
  end
end
