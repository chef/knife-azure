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
include AzureUtility

before do
	@server_instance = Chef::Knife::AzureServerCreate.new

	{
   	:azure_subscription_id => 'azure_subscription_id',
		:azure_mgmt_cert => 'AzureLinuxCert.pem',
		:azure_api_host_name => 'preview.core.windows-int.net',
		:azure_service_location => 'West Europe',
		:azure_source_image => 'SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd',
		:azure_dns_name => 'service001',
		:azure_vm_name => 'vm01',
		:azure_storage_account => 'ka001testeurope',
		:azure_vm_size => 'Small'
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

def test_params(testxml, chef_config, role_name, host_name)
	xml_content(testxml, 'UserName').should == chef_config[:ssh_user]
	xml_content(testxml, 'UserPassword').should == chef_config[:ssh_password]
	xml_content(testxml, 'SourceImageName').should == chef_config[:azure_source_image]
	xml_content(testxml, 'RoleSize').should == chef_config[:azure_vm_size]
	xml_content(testxml, 'HostName').should == host_name
	xml_content(testxml, 'RoleName').should == role_name
end

describe "parameter test:" do

	context "compulsory parameters" do

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
		it "azure_api_host_name" do
			Chef::Config[:knife].delete(:azure_api_host_name)
			@server_instance.ui.should_receive(:error)
			expect {@server_instance.run}.to raise_error
		end
		it "azure_service_location" do
			Chef::Config[:knife].delete(:azure_service_location)
			@server_instance.ui.should_receive(:error)
			expect {@server_instance.run}.to raise_error
		end
		it "azure_source_image" do
			Chef::Config[:knife].delete(:azure_source_image)
			@server_instance.ui.should_receive(:error)
			expect {@server_instance.run}.to raise_error
		end
		it "azure_vm_size" do
			Chef::Config[:knife].delete(:azure_vm_size)
			@server_instance.ui.should_receive(:error)
			expect {@server_instance.run}.to raise_error
		end
		it "azure_dns_name" do
			Chef::Config[:knife].delete(:azure_dns_name)
			@server_instance.ui.should_receive(:error)
			expect {@server_instance.run}.to raise_error
		end
	end

	context "server create options" do
		before do
			Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
			Chef::Config[:knife][:ssh_password] = 'ssh_password'
			Chef::Config[:knife][:ssh_user] = 'ssh_user'
			Chef::Config[:knife][:azure_dns_name] = 'vm01'
			Chef::Config[:knife].delete(:azure_vm_name)
			Chef::Config[:knife].delete(:azure_storage_account)
			@bootstrap = Chef::Knife::Bootstrap.new
	      	Chef::Knife::Bootstrap.stub(:new).and_return(@bootstrap)
	      	@bootstrap.should_receive(:run)
		end

		it "quick create" do
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(false)
			@server_instance.run
			@server_instance.config[:azure_vm_name].should == "vm01"
			testxml = Nokogiri::XML(@receivedXML)
			xml_content(testxml, 'MediaLink').should_not == nil
			test_params(testxml, Chef::Config[:knife], Chef::Config[:knife][:azure_dns_name],
										Chef::Config[:knife][:azure_dns_name])
		end

		it "advanced create" do
			# set all params
			Chef::Config[:knife][:azure_dns_name] = 'service001'
			Chef::Config[:knife][:azure_vm_name] = 'vm01'
			Chef::Config[:knife][:azure_storage_account] = 'ka001testeurope'
			Chef::Config[:knife][:azure_os_disk_name] = 'os-disk'
			@server_instance.run
			testxml = Nokogiri::XML(@receivedXML)
			xml_content(testxml, 'MediaLink').should == 'http://ka001testeurope.blob.core.windows.net/vhds/os-disk.vhd'
			test_params(testxml, Chef::Config[:knife], Chef::Config[:knife][:azure_vm_name],
										Chef::Config[:knife][:azure_vm_name])
		end
	end
end

describe "for bootstrap protocol winrm:" do
	before do
		Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
		Chef::Config[:knife][:winrm_password] = 'winrm_password'
	end

	it "check if all server params are set correctly" do
		@server_instance.should_receive(:is_image_windows?).twice.and_return(true)
		@server_params = @server_instance.create_server_def
		@server_params[:os_type].should == 'Windows'
		@server_params[:admin_password].should == 'winrm_password'
		@server_params[:bootstrap_proto].should == 'winrm'
		@server_params[:azure_dns_name].should == 'service001'
		@server_params[:azure_vm_name].should == 'vm01'
		@server_params[:port].should == '5985'
	end

	context "bootstrap node" do
		before do
			@bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
		   	Chef::Knife::BootstrapWindowsWinrm.stub(:new).and_return(@bootstrap)
		   	@bootstrap.should_receive(:run)
		end

		it "sets param <azure_storage_account> from azure_vm_name" do
			Chef::Config[:knife].delete(:azure_storage_account)
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			@server_instance.run
			@server_instance.config[:azure_storage_account].should match(/\Avm01/)
		end

		it "sets param <azure_storage_account> from storage name" do
			Chef::Config[:knife].delete(:azure_storage_account)
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			Chef::Config[:knife][:azure_service_location] = 'service-location'
			@server_instance.run
			@server_instance.config[:azure_storage_account].should match(/storage-service-name/)
		end

		it "successful bootstrap of windows instance" do
			@server_instance.should_receive(:is_image_windows?).exactly(3).times.and_return(true)
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
			@server_instance.should_receive(:is_image_windows?).exactly(3).times.and_return(true)
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
		it "check if all server params are set correctly" do
			@server_instance.should_receive(:is_image_windows?).twice.and_return(false)
			@server_params = @server_instance.create_server_def
			@server_params[:os_type].should == 'Linux'
			@server_params[:ssh_password].should == 'ssh_password'
			@server_params[:ssh_user].should == 'ssh_user'
			@server_params[:bootstrap_proto].should == 'ssh'
			@server_params[:azure_dns_name].should == 'service001'
			@server_params[:azure_vm_name].should == 'vm01'
			@server_params[:port].should == '22'
		end

		it "successful bootstrap" do
			@server_instance.should_receive(:is_image_windows?).exactly(3).times.and_return(false)
			@bootstrap = Chef::Knife::Bootstrap.new
	      	Chef::Knife::Bootstrap.stub(:new).and_return(@bootstrap)
	      	@bootstrap.should_receive(:run)
			@server_instance.run
		end

		context "ssh key" do
			before do
				Chef::Config[:knife][:ssh_password] = ''
				Chef::Config[:knife][:identity_file] = 'path_to_rsa_private_key'
			end
			it "check if ssh-key set correctly" do
				@server_instance.should_receive(:is_image_windows?).twice.and_return(false)
				@server_params = @server_instance.create_server_def
				@server_params[:os_type].should == 'Linux'
				@server_params[:identity_file].should == 'path_to_rsa_private_key'
				@server_params[:ssh_user].should == 'ssh_user'
				@server_params[:bootstrap_proto].should == 'ssh'
				@server_params[:azure_dns_name].should == 'service001'
			end
			it "successful bootstrap with ssh key" do
				@server_instance.should_receive(:is_image_windows?).exactly(3).times.and_return(false)
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
