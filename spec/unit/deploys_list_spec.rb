require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')

describe "deploys" do 
include AzureSpecHelper
  include QueryAzureMock
  before 'setup connection' do
    setup_query_azure_mock
  end

  specify {@connection.deploys.all.length.should be > 0}
  it 'each deployment should have values' do
    @connection.deploys.all.each do |deploy|
      deploy.name.should_not be_nil
      deploy.status.should_not be_nil
      deploy.url.should_not be_nil
      deploy.roles.length.should be > 0
    end
  end
  it 'each role should have values' do
    @connection.deploys.all.each do |deploy|
    #describe_deploy deploy
      deploy.roles.each do |role|
        #describe_role role
        role.name.should_not be_nil
        role.status.should_not be_nil
        role.size.should_not be_nil
        role.ipaddress.should_not be_nil
        role.sshport.should_not be_nil
        role.publicipaddress.should_not be_nil
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
