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
		:azure_mgmt_cert => @cert_file,
		:azure_api_host_name => 'preview.core.windows-int.net',
		:azure_service_location => 'West Europe',
		:azure_source_image => 'SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd',
		:azure_dns_name => 'service001',
		:azure_vm_name => 'vm002',
		:azure_storage_account => 'ka001testeurope',
		:azure_vm_size => 'Small',
    :ssh_user => 'test-user'
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
    it "azure_service_location and azure_affinity_group not allowed" do
      Chef::Config[:knife][:azure_affinity_group] = 'test-affinity'
      @server_instance.ui.should_receive(:error)
      expect {@server_instance.run}.to raise_error
    end
    it "azure_service_location or azure_affinity_group must be provided" do
      Chef::Config[:knife].delete(:azure_service_location)
      @server_instance.ui.should_receive(:error)
      expect {@server_instance.run}.to raise_error
    end
	end

	context "server create options" do
		before do
			Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
			Chef::Config[:knife][:ssh_password] = 'ssh_password'
			Chef::Config[:knife][:ssh_user] = 'ssh_user'
			Chef::Config[:knife].delete(:azure_vm_name)
			Chef::Config[:knife].delete(:azure_storage_account)
			@bootstrap = Chef::Knife::Bootstrap.new
	      	Chef::Knife::Bootstrap.stub(:new).and_return(@bootstrap)
	      	@bootstrap.should_receive(:run)
		end

		it "quick create" do
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(false)
			Chef::Config[:knife][:azure_dns_name] = 'vmname' # service name to be used as vm name
			@server_instance.run
			@server_instance.config[:azure_vm_name].should == "vmname"
			testxml = Nokogiri::XML(@receivedXML)
			xml_content(testxml, 'MediaLink').should_not == nil
			xml_content(testxml, 'DiskName').should_not == nil
			test_params(testxml, Chef::Config[:knife], Chef::Config[:knife][:azure_dns_name],
										Chef::Config[:knife][:azure_dns_name])
		end

        it "generate unique OS DiskName" do
          os_disks = []
          @bootstrap.stub(:run)
          @server_instance.stub(:validate!)
          Chef::Config[:knife][:azure_dns_name] = 'vmname'

          5.times do
            @server_instance.run
            testxml = Nokogiri::XML(@receivedXML)
            disklink = xml_content(testxml, 'MediaLink')
            os_disks.should_not include(disklink)
            os_disks.push(disklink)
          end
        end

		it "skip user specified tcp-endpoints if its ports already use by ssh endpoint" do
			# Default external port for ssh endpoint is 22.
			@server_instance.config[:tcp_endpoints] = "12:22"
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(false)
			Chef::Config[:knife][:azure_dns_name] = 'vmname' # service name to be used as vm name
			@server_instance.run
			testxml = Nokogiri::XML(@receivedXML)
			testxml.css('InputEndpoint Protocol:contains("TCP")').each do | port |
			  # Test data in @server_instance.config[:tcp_endpoints]:=> "12:22" this endpoints external port 22 is already use by ssh endpoint. So it should skip endpoint "12:22".
			  port.parent.css("LocalPort").text.should_not eq("12")
			end
		end

		it "advanced create" do
			# set all params
			Chef::Config[:knife][:azure_dns_name] = 'service001'
			Chef::Config[:knife][:azure_vm_name] = 'vm002'
			Chef::Config[:knife][:azure_storage_account] = 'ka001testeurope'
			Chef::Config[:knife][:azure_os_disk_name] = 'os-disk'
			@server_instance.run
			testxml = Nokogiri::XML(@receivedXML)
			xml_content(testxml, 'MediaLink').should == 'http://ka001testeurope.blob.core.windows.net/vhds/os-disk.vhd'
			xml_content(testxml, 'DiskName').should == Chef::Config[:knife][:azure_os_disk_name]
			test_params(testxml, Chef::Config[:knife], Chef::Config[:knife][:azure_vm_name],
										Chef::Config[:knife][:azure_vm_name])
		end

    it "create with availability set" do
      # set all params
      Chef::Config[:knife][:azure_dns_name] = 'service001'
      Chef::Config[:knife][:azure_vm_name] = 'vm002'
      Chef::Config[:knife][:azure_storage_account] = 'ka001testeurope'
      Chef::Config[:knife][:azure_os_disk_name] = 'os-disk'
      Chef::Config[:knife][:azure_availability_set] = 'test-availability-set'
      @server_instance.run
      testxml = Nokogiri::XML(@receivedXML)
      xml_content(testxml, 'AvailabilitySetName').should == 'test-availability-set'
    end

    it "server create with virtual network and subnet" do
      Chef::Config[:knife][:azure_dns_name] = 'vmname'
      Chef::Config[:knife][:azure_network_name] = 'test-network'
      Chef::Config[:knife][:azure_subnet_name] = 'test-subnet'
      @server_instance.run
      testxml = Nokogiri::XML(@receivedXML)
      xml_content(testxml, 'SubnetName').should == 'test-subnet'
    end
  end

	context "#cleanup_and_exit" do
		it "service leak cleanup" do
			expect {@server_instance.cleanup_and_exit("hosted_srvc", "storage_srvc")}.to raise_error
		end

		it "service leak cleanup with nil params" do
			@server_instance.connection.hosts.should_not_receive(:delete)
			@server_instance.connection.storageaccounts.should_not_receive(:delete)
			expect {@server_instance.cleanup_and_exit(nil, nil)}.to raise_error
		end

		it "service leak cleanup with valid params" do
			@server_instance.connection.hosts.should_receive(:delete).with("hosted_srvc")
			@server_instance.connection.storageaccounts.should_receive(:delete).with("storage_srvc")
			expect {@server_instance.cleanup_and_exit("hosted_srvc", "storage_srvc")}.to raise_error
		end
	end

	context "connect to existing DNS tests" do
		before do
			Chef::Config[:knife][:azure_connect_to_existing_dns] = true
		end
		it "should throw error when DNS does not exist" do
			Chef::Config[:knife][:azure_dns_name] = 'does-not-exist'
            Chef::Config[:knife][:ssh_user] = 'azureuser'
            Chef::Config[:knife][:ssh_password] = 'Jetstream123!'
            expect {@server_instance.run}.to raise_error
		end
		it "port should be unique number when winrm-port not specified for winrm" do
			Chef::Config[:knife][:azure_dns_name] = 'service001'
			Chef::Config[:knife][:azure_vm_name] = 'newvm01'
			Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
			Chef::Config[:knife][:winrm_user] = 'testuser'
			Chef::Config[:knife][:winrm_password] = 'Jetstream123!'
			@server_instance.should_receive(:is_image_windows?).twice.and_return(true)
			@server_params = @server_instance.create_server_def
			@server_params[:port].should_not == '5985'
		end
		it "port should be winrm-port value specified in the option" do
            Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
            Chef::Config[:knife][:winrm_user] = 'testuser'
            Chef::Config[:knife][:winrm_password] = 'Jetstream123!'
            Chef::Config[:knife][:winrm_port] = '5990'
			@server_instance.should_receive(:is_image_windows?).twice.and_return(true)
			@server_params = @server_instance.create_server_def
			@server_params[:port].should == '5990'
		end
		it "port should be unique number when ssh-port not specified for linux image" do
			Chef::Config[:knife][:ssh_user] = 'azureuser'
			Chef::Config[:knife][:ssh_password] = 'Jetstream123!'
			Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
			@server_instance.should_receive(:is_image_windows?).twice.and_return(false)
			@server_params = @server_instance.create_server_def
			@server_params[:port].should_not == '22'
		end
		it "port should be ssh-port value specified in the option" do
			Chef::Config[:knife][:ssh_user] = 'azureuser'
			Chef::Config[:knife][:ssh_password] = 'Jetstream123!'
			Chef::Config[:knife][:ssh_port] = '24'
			@server_instance.should_receive(:is_image_windows?).twice.and_return(false)
			@server_params = @server_instance.create_server_def
			@server_params[:port].should == '24'
		end
		it "port should be be different if ssh-port = 22" do
			Chef::Config[:knife][:ssh_user] = 'azureuser'
			Chef::Config[:knife][:ssh_password] = 'Jetstream123!'
			Chef::Config[:knife][:ssh_port] = '22'
			@server_instance.should_receive(:is_image_windows?).twice.and_return(false)
			@server_params = @server_instance.create_server_def
			@server_params[:port].should_not == '22'
		end
	end

end

describe "cloud attributes" do
	context "WinRM protocol:" do
		before do
			@bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
			Chef::Knife::BootstrapWindowsWinrm.stub(:new).and_return(@bootstrap)
			@bootstrap.should_receive(:run)
			@server_instance.stub(:is_image_windows?).and_return(true)
			Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
			Chef::Config[:knife][:winrm_user] = 'testuser'
			Chef::Config[:knife][:winrm_password] = 'winrm_password'
			Chef::Config[:knife][:azure_dns_name] = 'service004'
			Chef::Config[:knife][:azure_vm_name] = 'winrm-vm'
			Chef::Config[:knife][:hints] = nil # reset as this is loaded only once for app(test here)
			@server_instance.run
		end

		it "should set the cloud attributes in hints" do
			cloud_attributes = Chef::Config[:knife][:hints]["azure"]
			cloud_attributes["public_ip"].should == "65.52.249.191"
			cloud_attributes["vm_name"].should == "winrm-vm"
			cloud_attributes["public_fqdn"].should == "service004.cloudapp.net"
			cloud_attributes["public_ssh_port"].should be_nil
			cloud_attributes["public_winrm_port"].should == "5985"
		end
	end
	context "SSH protocol:" do
		before do
			@bootstrap = Chef::Knife::Bootstrap.new
			Chef::Knife::Bootstrap.stub(:new).and_return(@bootstrap)
			@bootstrap.should_receive(:run)
			@server_instance.stub(:is_image_windows?).and_return(false)
			Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
			Chef::Config[:knife][:ssh_password] = 'ssh_password'
			Chef::Config[:knife][:ssh_user] = 'ssh_user'
			Chef::Config[:knife][:azure_dns_name] = 'service004'
			Chef::Config[:knife][:azure_vm_name] = 'ssh-vm'
			Chef::Config[:knife][:hints] = nil # reset as this is loaded only once for app(test here)
			@server_instance.run
		end

		it "should set the cloud attributes in hints" do
			cloud_attributes = Chef::Config[:knife][:hints]["azure"]
			cloud_attributes["public_ip"].should == "65.52.251.57"
			cloud_attributes["vm_name"].should == "ssh-vm"
			cloud_attributes["public_fqdn"].should == "service004.cloudapp.net"
			cloud_attributes["public_ssh_port"].should  == "22"
			cloud_attributes["public_winrm_port"].should be_nil
		end
	end
end

describe "for bootstrap protocol winrm:" do
	before do
		Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
		Chef::Config[:knife][:winrm_user] = 'testuser'
		Chef::Config[:knife][:winrm_password] = 'winrm_password'
		@server_instance.ui.stub(:error)
	end

	it "check if all server params are set correctly" do
		@server_instance.should_receive(:is_image_windows?).twice.and_return(true)
		@server_params = @server_instance.create_server_def
		@server_params[:os_type].should == 'Windows'
		@server_params[:admin_password].should == 'winrm_password'
		@server_params[:bootstrap_proto].should == 'winrm'
		@server_params[:azure_dns_name].should == 'service001'
		@server_params[:azure_vm_name].should == 'vm002'
		@server_params[:winrm_user].should == 'testuser'
		@server_params[:port].should == '5985'
	end

	it "winrm_user cannot be 'administrator'" do
		@server_instance.should_receive(:is_image_windows?).twice.and_return(true)
		Chef::Config[:knife][:winrm_user] = 'administrator'
		expect {@server_instance.create_server_def}.to raise_error
	end

	it "winrm_user cannot be 'admin*'" do
		@server_instance.should_receive(:is_image_windows?).twice.and_return(true)
		Chef::Config[:knife][:winrm_user] = 'Admin12'
		expect {@server_instance.create_server_def}.to raise_error
	end

	context "bootstrap node" do
		before do
			@bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
		   	Chef::Knife::BootstrapWindowsWinrm.stub(:new).and_return(@bootstrap)
		   	@bootstrap.should_receive(:run)
		end

		it "sets valid distro for windows vm" do
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			@server_instance.run
			@server_instance.config[:distro].should == 'windows-chef-client-msi'
		end

		it "sets param <azure_storage_account> from azure_vm_name" do
			Chef::Config[:knife].delete(:azure_storage_account)
			@server_instance.should_receive(:is_image_windows?).at_least(:twice).and_return(true)
			@server_instance.run
			@server_instance.config[:azure_storage_account].should match(/\Avm002/)
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
		Chef::Config[:knife][:ssh_user] = "testuser"
		Chef::Config[:knife][:ssh_password] = "testpass"
	end

	context "windows instance:" do
		it "successful bootstrap" do
			@server_instance.should_receive(:is_image_windows?).exactly(3).times.and_return(true)
			@bootstrap = Chef::Knife::BootstrapWindowsSsh.new
		   	Chef::Knife::BootstrapWindowsSsh.stub(:new).and_return(@bootstrap)
		   	@bootstrap.should_receive(:run)
		   	@server_instance.run
		end
		it "raise error if ssh user is missing" do
			Chef::Config[:knife][:ssh_user] = nil
			@server_instance.stub(:is_image_windows?).and_return(true)
			@server_instance.ui.should_receive(:error).with("SSH User is compulsory parameter and it cannot be named 'admin*'")
		   	expect { @server_instance.run }.to raise_error
		end
		it "raise error if ssh password is missing" do
			Chef::Config[:knife][:ssh_password] = nil
			@server_instance.stub(:is_image_windows?).and_return(true)
			@server_instance.ui.should_receive(:error).with("SSH Password is compulsory parameter for windows image")
		   	expect { @server_instance.run }.to raise_error
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
			@server_params[:azure_vm_name].should == 'vm002'
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
