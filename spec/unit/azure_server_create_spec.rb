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
		:source_image => 'SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd',
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

		context "Tests for publish settings file" do
			before do
				Chef::Config[:knife][:azure_host_name] = nil
				Chef::Config[:knife][:azure_subscription_id] = nil
			end
			def validate_cert()
				Chef::Config[:knife][:azure_mgmt_cert].should include("-----BEGIN CERTIFICATE-----")
				Chef::Config[:knife][:azure_mgmt_cert].should include("-----END CERTIFICATE-----")
				Chef::Config[:knife][:azure_mgmt_cert].should include("-----BEGIN RSA PRIVATE KEY-----")
				Chef::Config[:knife][:azure_mgmt_cert].should include("-----END RSA PRIVATE KEY-----")
			end
			it "- should continue to regular flow if publish settings file not provided" do
				Chef::Config[:knife][:azure_host_name] = "preview.core.windows-int.net"
				Chef::Config[:knife][:azure_subscription_id] = "azure_subscription_id"
				@server_instance.validate!
				Chef::Config[:knife][:azure_host_name].should == "preview.core.windows-int.net"
				Chef::Config[:knife][:azure_subscription_id].should == "azure_subscription_id"
			end

			it "- should validate extract parameters" do
				Chef::Config[:knife][:azure_publish_settings_file] = "azureValid.publishsettings"
				@server_instance.validate!
				Chef::Config[:knife][:azure_host_name].should == 'management.core.windows.net'
				Chef::Config[:knife][:azure_subscription_id].should == 'id1'
				validate_cert()
			end

			it "- should validate parse method" do
				@server_instance.parse_publish_settings_file("azureValid.publishsettings")
				Chef::Config[:knife][:azure_host_name].should == 'management.core.windows.net'
				Chef::Config[:knife][:azure_subscription_id].should == 'id1'
				validate_cert()
			end

			it "- should validate settings file and subscrition id" do
				Chef::Config[:knife][:azure_subscription_id] = "azure_subscription_id"
				Chef::Config[:knife][:azure_publish_settings_file] = "azureValid.publishsettings"
				@server_instance.validate!
				Chef::Config[:knife][:azure_host_name].should == 'management.core.windows.net'
				Chef::Config[:knife][:azure_subscription_id].should == 'azure_subscription_id'
				validate_cert()
			end

			it "- should raise error if invalid publish settings provided" do
				Chef::Config[:knife][:azure_publish_settings_file] = "azureInvalid.publishsettings"
				expect {@server_instance.validate!}.to raise_error
			end

			it "- should raise error if publish settings file does not exists" do
				Chef::Config[:knife][:azure_publish_settings_file] = "azureNotAvailable.publishsettings"
				expect {@server_instance.validate!}.to raise_error
			end
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
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			@server_instance.run
			@server_instance.config[:hosted_service_name].should match(/\Avm01/)
		end

		it "sets param <storage_account> from role_name" do
			Chef::Config[:knife].delete(:storage_account)
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			@server_instance.run
			@server_instance.config[:storage_account].should match(/\Avm01/)
		end

		it "sets param <storage_account> from storage name" do
			Chef::Config[:knife].delete(:storage_account)
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			Chef::Config[:knife][:service_location] = 'service-location'
			@server_instance.run
			@server_instance.config[:storage_account].should match(/storage-service-name/)
		end

		it "successful bootstrap of windows instance" do
			@server_instance.should_receive(:is_image_windows?).exactly(2).times.and_return(true)
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
			@server_instance.should_receive(:is_image_windows?).exactly(2).times.and_return(true)
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
			@server_instance.should_receive(:is_image_windows?).exactly(2).times.and_return(false)
			@bootstrap = Chef::Knife::Bootstrap.new
	      	Chef::Knife::Bootstrap.stub(:new).and_return(@bootstrap)
	      	@bootstrap.should_receive(:run)
			@server_instance.run
		end

		context "ssh key" do
			before do
				Chef::Config[:knife][:ssh_password] = ''
				Chef::Config[:knife][:identity_file] = 'ssh_key'
			end
			it "check if ssh-key set correctly" do
				@server_instance.should_receive(:is_image_windows?).and_return(false)
				@server_params = @server_instance.create_server_def
				@server_params[:os_type].should == 'Linux'
				@server_params[:identity_file].should == 'ssh_key'
				@server_params[:ssh_user].should == 'ssh_user'
				@server_params[:bootstrap_proto].should == 'ssh'
				@server_params[:hosted_service_name].should == 'service001'
			end
			it "successful bootstrap with ssh key" do
				@server_instance.should_receive(:is_image_windows?).exactly(2).times.and_return(false)
				@bootstrap = Chef::Knife::Bootstrap.new
		      	Chef::Knife::Bootstrap.stub(:new).and_return(@bootstrap)
		      	@bootstrap.should_receive(:run)
		      	@server_instance.connection.certificates.stub(:generate_public_key_certificate_data).and_return("cert_data")
		      	@server_instance.connection.certificates.should_receive(:create)
				@server_instance.run
			end
		end

		context "bootstrap"
			before do
				@server_params = @server_instance.create_server_def
				@bootstrap = Chef::Knife::Bootstrap.new
		      	Chef::Knife::Bootstrap.stub(:new).and_return(@bootstrap)
			end

			it "enables sudo password when ssh_user is not root" do
		      	@bootstrap.should_receive(:run)
				@server_instance.run
				@bootstrap.config[:use_sudo_password].should == true
			end

			it "does not enable sudo password when ssh_user is root" do
		      	@bootstrap.should_receive(:run)
		      	Chef::Config[:knife][:ssh_user] = 'root'
				@server_instance.run
				@bootstrap.config[:use_sudo_password].should_not == true
			end

	end

end

end
