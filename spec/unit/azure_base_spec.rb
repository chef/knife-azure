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
		Chef::Config[:knife][:azure_mgmt_cert] = @cert_file
		allow(@dummy.ui).to receive(:error)
	end
	describe "azure base tests - " do
		context "Tests for publish settings file" do
			before do
				Chef::Config[:knife][:azure_api_host_name] = nil
				Chef::Config[:knife][:azure_subscription_id] = nil
			end
			def validate_cert()
				expect(Chef::Config[:knife][:azure_mgmt_cert]).to include("-----BEGIN CERTIFICATE-----")
				expect(Chef::Config[:knife][:azure_mgmt_cert]).to include("-----END CERTIFICATE-----")
				expect(Chef::Config[:knife][:azure_mgmt_cert]).to include("-----BEGIN RSA PRIVATE KEY-----")
				expect(Chef::Config[:knife][:azure_mgmt_cert]).to include("-----END RSA PRIVATE KEY-----")
			end
			it "- should continue to regular flow if publish settings file not provided" do
				Chef::Config[:knife][:azure_api_host_name] = "preview.core.windows-int.net"
				Chef::Config[:knife][:azure_subscription_id] = "azure_subscription_id"
				@dummy.validate!
				expect(Chef::Config[:knife][:azure_api_host_name]).to be == "preview.core.windows-int.net"
				expect(Chef::Config[:knife][:azure_subscription_id]).to be == "azure_subscription_id"
			end

			it "- should validate extract parameters" do
				Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureValid.publishsettings")
				@dummy.validate!
				expect(Chef::Config[:knife][:azure_api_host_name]).to be == 'management.core.windows.net'
				expect(Chef::Config[:knife][:azure_subscription_id]).to be == 'id1'
				validate_cert()
			end

			it "- should validate parse method" do
				@dummy.parse_publish_settings_file(get_publish_settings_file_path("azureValid.publishsettings"))
				expect(Chef::Config[:knife][:azure_api_host_name]).to be == 'management.core.windows.net'
				expect(Chef::Config[:knife][:azure_subscription_id]).to be == 'id1'
				validate_cert()
			end

			it "- should validate parse method for SchemaVersion2-0 publishsettings file" do
				@dummy.parse_publish_settings_file(get_publish_settings_file_path("azureValidSchemaVersion-2.0.publishsettings"))
				expect(Chef::Config[:knife][:azure_api_host_name]).to be == 'management.core.windows.net'
				expect(Chef::Config[:knife][:azure_subscription_id]).to be == 'id1'
				validate_cert()
			end

			it "- should validate settings file and subscrition id" do
				@dummy.config[:azure_subscription_id] = "azure_subscription_id"
				Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureValid.publishsettings")
				@dummy.validate!
				expect(Chef::Config[:knife][:azure_api_host_name]).to be == 'management.core.windows.net'
				expect(@dummy.config[:azure_subscription_id]).to be == 'azure_subscription_id'
				expect(Chef::Config[:knife][:azure_subscription_id]).to be == 'id1'
				validate_cert()
			end

			it "- should raise error if invalid publish settings provided" do
				Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureInvalid.publishsettings")
				expect {@dummy.validate!}.to raise_error(SystemExit)
			end

			it "- should raise error if publish settings file does not exists" do
				Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureNotAvailable.publishsettings")
				expect {@dummy.validate!}.to raise_error(SystemExit)
			end
		end
	end
end
