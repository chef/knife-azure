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
#include AzureSpecHelper

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
		:role_size => 'role_size'
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    #@server_instance.connection = mock(Azure::Connection)

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
	#@server_instance.ui.should_not_receive(:error)	
end



describe "run:" do
	before do
		Chef::Config[:knife][:storage_account] = 'storage_account'
		@server_instance.connection.deploys = mock()
		@server_instance.connection.deploys.stub(:create).and_return(@server_def)
		@server_instance.should_receive(:create_server_def).and_return(@server_def)
		@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
	end

	it "creates azure instance for windows with winrm protocol and bootstraps it" do
		Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
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
		@bootstrap = Chef::Knife::BootstrapWindowsSsh.new
	   	Chef::Knife::BootstrapWindowsSsh.stub(:new).and_return(@bootstrap)
	   	@bootstrap.should_receive(:run)		
	   	@server_instance.run
	end

	it "creates azure instance for linux with ssh protocol and bootstraps it" do
		@server_def.stub(:sshipaddress).and_return('sshipaddress')
		@server_def.stub(:sshport).and_return('sshport')
		Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
		@bootstrap = Chef::Knife::Bootstrap.new
      	Chef::Knife::Bootstrap.stub(:new).and_return(@bootstrap)
      	@bootstrap.should_receive(:run)
		@server_instance.run
	end

end

describe "parameter testing:" do
	before do
	end

	it "storage account" do
		#If Storage Account is not specified, check if the geographic location has one to re-use
	end

	it "all server parameters are set correctly - for windows image" do
		Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
		Chef::Config[:knife][:hosted_service_name] = 'hosted_service_name'
		@server_instance.should_receive(:is_image_windows?).and_return(true)
		Chef::Config[:knife][:winrm_password] = 'winrm_password'
		@server_params = @server_instance.create_server_def
		@server_params[:os_type].should == 'Windows'
		@server_params[:admin_password].should == 'winrm_password'
		@server_params[:bootstrap_proto].should == 'winrm'
		@server_params[:hosted_service_name].should == 'hosted_service_name'
	end

	it "all server parameters are set correctly - for linux image" do
		@server_instance.should_receive(:is_image_windows?).and_return(false)
		Chef::Config[:knife][:ssh_password] = 'ssh_password'
		Chef::Config[:knife][:ssh_user] = 'ssh_user'
		Chef::Config[:knife][:hosted_service_name] = 'hosted_service_name'
		@server_params = @server_instance.create_server_def
		@server_params[:os_type].should == 'Linux'
		@server_params[:ssh_password].should == 'ssh_password'
		@server_params[:ssh_user].should == 'ssh_user'
		@server_params[:bootstrap_proto].should == 'ssh'
		@server_params[:hosted_service_name].should == 'hosted_service_name'
	end

	context "compalsory parameters for windows image -" do
		before do
			
		end
		it "azure_subscription_id" do		
			Chef::Config[:knife].delete(:azure_subscription_id)			
			@server_instance.ui.should_receive(:error) 
			expect {@server_instance.run}.to raise_error
		end
		it "azure_mgmt_cert" do		
			Chef::Config[:knife].delete(:azure_mgmt_cert)			
			@server_instance.ui.should_receive(:error)
			expect {@server_instance.run}.to raise_error
		end
		it "azure_host_name" do		
			Chef::Config[:knife].delete(:azure_host_name)			
			@server_instance.ui.should_receive(:error)
			expect {@server_instance.run}.to raise_error
		end
		it "role_name" do		
			Chef::Config[:knife].delete(:role_name)			
			@server_instance.ui.should_receive(:error)
			expect {@server_instance.run}.to raise_error
		end
		it "service_location" do		
			Chef::Config[:knife].delete(:service_location)			
			@server_instance.ui.should_receive(:error)
			expect {@server_instance.run}.to raise_error
		end
		it "source_image" do		
			Chef::Config[:knife].delete(:source_image)			
			@server_instance.ui.should_receive(:error)
			expect {@server_instance.run}.to raise_error
		end
		it "role_size" do		
			Chef::Config[:knife].delete(:role_size)			
			@server_instance.ui.should_receive(:error)
			expect {@server_instance.run}.to raise_error
		end
		it "setting hosted_service_name correctly from role_name" do
			Chef::Config[:knife].delete(:hosted_service_name)
			@server_instance.connection.deploys = mock()
			@server_instance.connection.deploys.stub(:create).and_return(@server_def)
			@server_instance.should_receive(:create_server_def).and_return(@server_def)
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			Chef::Config[:knife][:storage_account] = 'storage_account'
			@server_def.stub(:winrmipaddress).and_return('winrmipaddress')
			@server_def.stub(:winrmport).and_return('winrmport')						
			@bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
	   		Chef::Knife::BootstrapWindowsWinrm.stub(:new).and_return(@bootstrap)
	   		@bootstrap.should_receive(:run)
			@server_instance.run
			@server_instance.config[:hosted_service_name].should match(/\Arolename/)
		end

		it "setting storage_account correctly 1" do
			Chef::Config[:knife].delete(:storage_account)
			@server_instance.connection.deploys = mock()
			@server_instance.connection.deploys.stub(:create).and_return(@server_def)
			@server_instance.connection.storageaccounts = mock()
			@server_instance.connection.storageaccounts.stub(:all).and_return(['service_storage_account'])
			@server_instance.should_receive(:create_server_def).and_return(@server_def)
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			@server_def.stub(:winrmipaddress).and_return('winrmipaddress')
			@server_def.stub(:winrmport).and_return('winrmport')						
			@bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
	   		Chef::Knife::BootstrapWindowsWinrm.stub(:new).and_return(@bootstrap)
	   		@bootstrap.should_receive(:run)
			@server_instance.run
			@server_instance.config[:storage_account].should match(/\Arolename/)
		end
		it "setting storage_account correctly 2" do
			Chef::Config[:knife].delete(:storage_account)
			@server_instance.connection.deploys = mock()
			@server_instance.connection.deploys.stub(:create).and_return(@server_def)
			@server_instance.should_receive(:create_server_def).and_return(@server_def)
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			Chef::Config[:knife][:storage_account] = 'storage_account'
			@server_def.stub(:winrmipaddress).and_return('winrmipaddress')
			@server_def.stub(:winrmport).and_return('winrmport')						
			@bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
	   		Chef::Knife::BootstrapWindowsWinrm.stub(:new).and_return(@bootstrap)
	   		@bootstrap.should_receive(:run)
			@server_instance.run
			#@server_instance.config[:storage_account].should match(/\Arolename/)
		end
	end
end

end