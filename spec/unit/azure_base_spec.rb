#
# Author:: Ameya Varade (<ameya.varade@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Chef::Knife::AzureBase do
	include AzureSpecHelper
	class Chef
  		class Knife
			class DummyClass < Knife
				include Knife::AzureBase
  			end
  		end
  	end
	before do
		@dummy = Chef::Knife::DummyClass.new
		Chef::Config[:knife][:azure_api_host_name] = 'preview.core.windows-int.net'
		Chef::Config[:knife][:azure_subscription_id] = 'azure_subscription_id'
		Chef::Config[:knife][:azure_mgmt_cert] = 'AzureLinuxCert.pem'
		@dummy.ui.stub(:error)
	end
	describe "azure base tests - " do
		context "Tests for publish settings file" do
			before do
				Chef::Config[:knife][:azure_api_host_name] = nil
				Chef::Config[:knife][:azure_subscription_id] = nil
			end
			def validate_cert()
				Chef::Config[:knife][:azure_mgmt_cert].should include("-----BEGIN CERTIFICATE-----")
				Chef::Config[:knife][:azure_mgmt_cert].should include("-----END CERTIFICATE-----")
				Chef::Config[:knife][:azure_mgmt_cert].should include("-----BEGIN RSA PRIVATE KEY-----")
				Chef::Config[:knife][:azure_mgmt_cert].should include("-----END RSA PRIVATE KEY-----")
			end
			it "- should continue to regular flow if publish settings file not provided" do
				Chef::Config[:knife][:azure_api_host_name] = "preview.core.windows-int.net"
				Chef::Config[:knife][:azure_subscription_id] = "azure_subscription_id"
				@dummy.validate!
				Chef::Config[:knife][:azure_api_host_name].should == "preview.core.windows-int.net"
				Chef::Config[:knife][:azure_subscription_id].should == "azure_subscription_id"
			end

			it "- should validate extract parameters" do
				Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureValid.publishsettings")
				@dummy.validate!
				Chef::Config[:knife][:azure_api_host_name].should == 'management.core.windows.net'
				Chef::Config[:knife][:azure_subscription_id].should == 'id1'
				validate_cert()
			end

			it "- should validate parse method" do
				@dummy.parse_publish_settings_file(get_publish_settings_file_path("azureValid.publishsettings"))
				Chef::Config[:knife][:azure_api_host_name].should == 'management.core.windows.net'
				Chef::Config[:knife][:azure_subscription_id].should == 'id1'
				validate_cert()
			end

			it "- should validate parse method for SchemaVersion2-0 publishsettings file" do
				@dummy.parse_publish_settings_file(get_publish_settings_file_path("azureValidSchemaVersion-2.0.publishsettings"))
				Chef::Config[:knife][:azure_api_host_name].should == 'management.core.windows.net'
				Chef::Config[:knife][:azure_subscription_id].should == 'id1'
				validate_cert()
			end

			it "- should validate parse method for SchemaVersion2-0 publishsettings file" do
				@dummy.parse_publish_settings_file("azureValidSchemaVersion-2.0.publishsettings")
				Chef::Config[:knife][:azure_api_host_name].should == 'management.core.windows.net'
				Chef::Config[:knife][:azure_subscription_id].should == 'id1'
				validate_cert()
			end

			it "- should validate settings file and subscrition id" do
				@dummy.config[:azure_subscription_id] = "azure_subscription_id"
				Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureValid.publishsettings")
				@dummy.validate!
				Chef::Config[:knife][:azure_api_host_name].should == 'management.core.windows.net'
				@dummy.config[:azure_subscription_id].should == 'azure_subscription_id'
				Chef::Config[:knife][:azure_subscription_id].should == 'id1'
				validate_cert()
			end

			it "- should raise error if invalid publish settings provided" do
				Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureInvalid.publishsettings")
				expect {@dummy.validate!}.to raise_error
			end

			it "- should raise error if publish settings file does not exists" do
				Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureNotAvailable.publishsettings")
				expect {@dummy.validate!}.to raise_error
			end
		end
	end
end
