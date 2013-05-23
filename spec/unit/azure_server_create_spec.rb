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
			#puts @receivedXML
		end

		it "advanced create" do
			# set all params
			Chef::Config[:knife][:azure_dns_name] = 'service001'
			Chef::Config[:knife][:azure_vm_name] = 'vm01'
			Chef::Config[:knife][:azure_storage_account] = 'ka001testeurope'
			Chef::Config[:knife][:azure_os_disk_name] = 'os-disk'
	      	#check if API calls are correct
			@server_instance.connection.should_receive(:query_azure).with("storageservices", "post", "<?xml version=\"1.0\"?>\n<CreateStorageServiceInput xmlns=\"http://schemas.microsoft.com/windowsazure\">\n  <ServiceName>#{Chef::Config[:knife][:azure_storage_account]}</ServiceName>\n  <Label>a2EwMDF0ZXN0ZXVyb3Bl\n</Label>\n  <Description>Explicitly created storage service</Description>\n  <Location>#{Chef::Config[:knife][:azure_service_location]}</Location>\n</CreateStorageServiceInput>\n")
			@server_instance.connection.should_receive(:query_azure).with("hostedservices/#{Chef::Config[:knife][:azure_dns_name]}/deployments/deployment001/roles", "post", "<?xml version=\"1.0\"?>\n<PersistentVMRole xmlns=\"http://schemas.microsoft.com/windowsazure\" xmlns:i=\"http://www.w3.org/2001/XMLSchema-instance\">\n  <RoleName>#{Chef::Config[:knife][:azure_vm_name]}</RoleName>\n  <OsVersion i:nil=\"true\"/>\n  <RoleType>PersistentVMRole</RoleType>\n  <ConfigurationSets>\n    <ConfigurationSet i:type=\"LinuxProvisioningConfigurationSet\">\n      <ConfigurationSetType>LinuxProvisioningConfiguration</ConfigurationSetType>\n      <HostName>#{Chef::Config[:knife][:azure_vm_name]}</HostName>\n      <UserName>#{Chef::Config[:knife][:ssh_user]}</UserName>\n      <UserPassword>#{Chef::Config[:knife][:ssh_password]}</UserPassword>\n      <DisableSshPasswordAuthentication>false</DisableSshPasswordAuthentication>\n    </ConfigurationSet>\n    <ConfigurationSet i:type=\"NetworkConfigurationSet\">\n      <ConfigurationSetType>NetworkConfiguration</ConfigurationSetType>\n      <InputEndpoints>\n        <InputEndpoint>\n          <LocalPort>22</LocalPort>\n          <Name>SSH</Name>\n          <Port>22</Port>\n          <Protocol>TCP</Protocol>\n        </InputEndpoint>\n      </InputEndpoints>\n    </ConfigurationSet>\n  </ConfigurationSets>\n  <Label>dm0wMQ==</Label>\n  <OSVirtualHardDisk>\n    <MediaLink>http://#{Chef::Config[:knife][:azure_storage_account]}.blob.core.windows.net/vhds/#{Chef::Config[:knife][:azure_os_disk_name]}.vhd</MediaLink>\n    <SourceImageName>SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd</SourceImageName>\n  </OSVirtualHardDisk>\n  <RoleSize>Small</RoleSize>\n</PersistentVMRole>\n")
			@server_instance.run
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
			@server_instance.should_receive(:is_image_windows?).exactly(4).times.and_return(true)
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
			@server_instance.should_receive(:is_image_windows?).exactly(4).times.and_return(true)
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
			@server_instance.should_receive(:is_image_windows?).exactly(4).times.and_return(false)
			@bootstrap = Chef::Knife::Bootstrap.new
	      	Chef::Knife::Bootstrap.stub(:new).and_return(@bootstrap)
	      	@bootstrap.should_receive(:run)
			@server_instance.run
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