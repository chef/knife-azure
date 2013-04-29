#
# Author:: Mukta Aphale (<mukta.aphale@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')
require 'chef/knife/bootstrap'
require 'chef/knife/bootstrap_windows_winrm'
require 'chef/knife/bootstrap_windows_ssh'

describe Chef::Knife::AzureServerCreate do
include AzureSpecHelper
include QueryAzureMock

before do    
	@server_instance = Chef::Knife::AzureServerCreate.new

	{
   		:azure_subscription_id => 'azure_subscription_id',
		:azure_mgmt_cert => 'AzureLinuxCert.pem',
		:azure_host_name => 'preview.core.windows-int.net',
		:role_name => 'vm01',
		:service_location => 'service_location',
		:source_image => 'source_image',
		:role_size => 'role_size',
		:hosted_service_name => 'service001',
		:storage_account => 'ka001testeurope'
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    stub_query_azure (@server_instance.connection)

    @server_instance.stub(:tcp_test_ssh).and_return(true)
    @server_instance.stub(:tcp_test_winrm).and_return(true)
    @server_instance.initial_sleep_delay = 0
    @server_instance.stub(:sleep).and_return(0)
    @server_instance.stub(:puts)
    @server_instance.stub(:print)
end

describe "compulsory parameter test:" do

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

end

describe "for bootstrap protocol winrm:" do
	before do
		Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
		Chef::Config[:knife][:winrm_password] = 'winrm_password'
	end

	it "check if all params are set correctly" do
		@server_instance.should_receive(:is_image_windows?).and_return(true)
		@server_params = @server_instance.create_server_def
		@server_params[:os_type].should == 'Windows'
		@server_params[:admin_password].should == 'winrm_password'
		@server_params[:bootstrap_proto].should == 'winrm'
		@server_params[:hosted_service_name].should == 'service001'
	end

	context "bootstrap node" do
		before do
			@bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
		   	Chef::Knife::BootstrapWindowsWinrm.stub(:new).and_return(@bootstrap)
		   	@bootstrap.should_receive(:run)
		end

		it "sets param <hosted_service_name> from role_name" do
			Chef::Config[:knife].delete(:hosted_service_name)
			#@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			@server_instance.stub(:is_image_windows?).and_return(true)
			@server_instance.run
			@server_instance.config[:hosted_service_name].should match(/\Avm01/)
		end

		it "sets param <storage_account> from role_name" do
			Chef::Config[:knife].delete(:storage_account)
			#@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			@server_instance.stub(:is_image_windows?).and_return(true)
			@server_instance.run
			@server_instance.config[:storage_account].should match(/\Avm01/)
		end

		it "sets param <storage_account> from storage name" do
			Chef::Config[:knife].delete(:storage_account)
			#@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			@server_instance.stub(:is_image_windows?).and_return(true)
			Chef::Config[:knife][:service_location] = 'service-location'
			@server_instance.run
			@server_instance.config[:storage_account].should match(/storage-service-name/)
		end

		it "successful bootstrap of windows instance" do		
			#@server_instance.should_receive(:is_image_windows?).exactly(3).times.and_return(true)
			@server_instance.stub(:is_image_windows?).and_return(true)
		   	@server_instance.run
		end
	end
end

describe "for bootstrap protocol ssh:" do
	before do
		Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
	end

	context "windows instance:" do
		it "successful bootstrap" do
			#@server_instance.should_receive(:is_image_windows?).exactly(3).times.and_return(true)
			@server_instance.stub(:is_image_windows?).and_return(true)
			@bootstrap = Chef::Knife::BootstrapWindowsSsh.new
		   	Chef::Knife::BootstrapWindowsSsh.stub(:new).and_return(@bootstrap)
		   	@bootstrap.should_receive(:run)		
		   	@server_instance.run
		end
	end

	context "linux instance" do
		before do
			Chef::Config[:knife][:ssh_password] = 'ssh_password'
			Chef::Config[:knife][:ssh_user] = 'ssh_user'
		end
		it "check if all params are set correctly" do
			@server_instance.should_receive(:is_image_windows?).and_return(false)		
			@server_params = @server_instance.create_server_def
			@server_params[:os_type].should == 'Linux'
			@server_params[:ssh_password].should == 'ssh_password'
			@server_params[:ssh_user].should == 'ssh_user'
			@server_params[:bootstrap_proto].should == 'ssh'
			@server_params[:hosted_service_name].should == 'service001'
		end

		it "successful bootstrap" do
			@server_instance.should_receive(:is_image_windows?).exactly(3).times.and_return(false)
			@bootstrap = Chef::Knife::Bootstrap.new
	      	Chef::Knife::Bootstrap.stub(:new).and_return(@bootstrap)
	      	@bootstrap.should_receive(:run)
			@server_instance.run
		end
	end

end

end