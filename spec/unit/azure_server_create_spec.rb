#
# Author:: Mukta Aphale (<mukta.aphale@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')
require 'chef/knife/bootstrap'
require 'chef/knife/bootstrap_windows_winrm'
require 'chef/knife/bootstrap_windows_ssh'

describe Chef::Knife::AzureServerCreate do
include QueryAzureMock

before do
    setup_query_azure_mock
	@server_instance = Chef::Knife::AzureServerCreate.new

	{
   		:azure_subscription_id => 'azure_subscription_id',
		:azure_mgmt_cert => 'AzureLinuxCert.pem',
		:azure_host_name => 'preview.core.windows-int.net',
		:role_name => 'role_name',
		:service_location => 'service_location',
		:source_image => 'source_image',
		:role_size => 'role_size',
		:bootstrap_protocol => 'winrm'
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    @server_def = {
		  :hosted_service_name => 'hosted_service_name',
          :storage_account => 'storage_account',
          :role_name => 'role_name',
          :host_name => 'host_name',
          :service_location => 'service_location',
          :os_disk_name => 'os_disk_name',
          :source_image => 'source_image',
          :role_size => 'role_size',
          :tcp_endpoints => 'tcp_endpoints',
          :udp_endpoints => 'udp_endpoints',
          :bootstrap_proto => 'winrm'
		}

    @server_instance.stub(:tcp_test_ssh).and_return(true)
    @server_instance.stub(:tcp_test_winrm).and_return(true)
    @server_instance.initial_sleep_delay = 0
    @server_instance.stub(:sleep).and_return(0)
	@server_def.stub(:name).and_return('chef_node_name')
end

describe "run:" do
	before do
		Chef::Config[:knife][:storage_account] = 'storage_account'
		@server_instance.connection.deploys = mock()
		@server_instance.connection.deploys.stub(:create).and_return(@server_def)
	end

	it "creates azure instance for windows with winrm protocol and bootstraps it" do
		@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
		@server_instance.should_receive(:create_server_def).and_return(@server_def)
		@server_def.stub(:winrmipaddress).and_return('winrmipaddress')
		@server_def.stub(:winrmport).and_return('winrmport')						
		@bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
	   	Chef::Knife::BootstrapWindowsWinrm.stub(:new).and_return(@bootstrap)
	   	@bootstrap.should_receive(:run)
	   	@server_instance.run
	end

	it "creates azure instance for windows with ssh protocol and bootstraps it" do
		Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
		@server_def.stub(:sshipaddress).and_return('sshpaddress')
		@server_def.stub(:sshport).and_return('sshport')
		@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
		@server_instance.should_receive(:create_server_def).and_return(@server_def)	
		@bootstrap = Chef::Knife::BootstrapWindowsSsh.new
	   	Chef::Knife::BootstrapWindowsSsh.stub(:new).and_return(@bootstrap)
	   	@bootstrap.should_receive(:run)		
	   	@server_instance.run
	end

	it "creates azure instance for linux with ssh protocol and bootstraps it" do
		@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(false)
		@server_instance.should_receive(:create_server_def).and_return(@server_def)
		@server_def.stub(:sshipaddress).and_return('sshipaddress')
		@server_def.stub(:sshport).and_return('sshport')
		@server_def.stub(:name).and_return('chef_node_name_linux')
		Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
		@bootstrap = Chef::Knife::Bootstrap.new
      	Chef::Knife::Bootstrap.stub(:new).and_return(@bootstrap)
      	@bootstrap.should_receive(:run)
		@server_instance.run
	end

	it "creates azure instance for linux with winrm protocol and bootstraps it" do
	end
end

describe "parameter testing:" do
	before do
	end

	it "storage account" do
		#If Storage Account is not specified, check if the geographic location has one to re-use
	end

	it "all server parameters are set correctly - for windows image" do
		#test the create_server_def method
	end

	it "all server parameters are set correctly - for linux image" do
		#test the create_server_def method
	end
end

end