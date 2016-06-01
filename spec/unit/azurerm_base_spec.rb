#
# Author:: Dheeraj Dubey (<dheeraj.dubey@msystechnologies.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzurermBase do
	include AzureSpecHelper
        include QueryAzureMock
	class Chef
  	class Knife
	class DummyClass < Knife
	include Knife::AzurermBase
          if Chef::Platform.windows?
            require 'azure/resource_management/windows_credentials'
            include Azure::ARM::WindowsCredentials
          end
  	end
  	end
  	end
	before do
	  @dummy = Chef::Knife::DummyClass.new
	  Chef::Config[:knife][:azure_api_host_name] = 'preview.core.windows-int.net'
	  Chef::Config[:knife][:azure_subscription_id] = 'azure_subscription_id'
	  Chef::Config[:knife][:azure_mgmt_cert] = @cert_file
          allow(@dummy.ui).to receive(:error)
          @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerList)
          @service = @arm_server_instance.service
          @compute_client = double("ComputeManagementClient")
	end

	describe "azurerm base tests - " do
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
				allow(@dummy).to receive(:get_azure_profile_file_path).and_return(File.dirname(__FILE__) + "/assets/azure-profile-files/C_account_azure_arm_profile.json")
				Chef::Config[:knife][:azure_api_host_name] = "preview.core.windows-int.net"
				Chef::Config[:knife][:azure_subscription_id] = "azure_subscription_id"
				@dummy.validate_arm_keys!
				expect(Chef::Config[:knife][:azure_api_host_name]).to be == "preview.core.windows-int.net"
				expect(Chef::Config[:knife][:azure_subscription_id]).to be == "azure_subscription_id"
			end

			it "- should validate extract parameters" do
				Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureValid.publishsettings")
				@dummy.validate_arm_keys!
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
				@dummy.validate_arm_keys!
				expect(Chef::Config[:knife][:azure_api_host_name]).to be == 'management.core.windows.net'
				expect(@dummy.config[:azure_subscription_id]).to be == 'azure_subscription_id'
				expect(Chef::Config[:knife][:azure_subscription_id]).to be == 'id1'
				validate_cert()
			end

			it "- should raise error if invalid publish settings provided" do
				Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureInvalid.publishsettings")
				expect {@dummy.validate_arm_keys!}.to raise_error(SystemExit)
			end

			it "- should raise error if publish settings file does not exists" do
				Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureNotAvailable.publishsettings")
				expect {@dummy.validate_arm_keys!}.to raise_error(SystemExit)
			end
		end
	end

        describe "Token Authentication related test cases" do
                
                 context "Token Validation test cases" do
                        it "Token Validity expired" do
                          token_details = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2016-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
                         expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error(RuntimeError)
                        end
                       
                        it 'Token is valid' do
                          token_details = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2116-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
                          expect { @arm_server_instance.check_token_validity(token_details) }
                        end
                 end

                 context "Authentication" do  

                        before do
                            Chef::Config[:knife][:azure_tenant_id] = "abeb039a-rfrgrggb48f-0c99bdc99d15"
                            Chef::Config[:knife][:azure_client_id] = "54dsdwe-3e2f36-e9f11d7f88a1"
                            Chef::Config[:knife][:azure_client_secret] = "xyz@123"
                        end

                        it 'use AD App creds to authenticate' do
                          @authentication_details = @arm_server_instance.check_authentication_method
                          expect(@authentication_details[:azure_tenant_id]).to be ==  "abeb039a-rfrgrggb48f-0c99bdc99d15"
                          expect(@authentication_details[:azure_client_id]).to be ==  "54dsdwe-3e2f36-e9f11d7f88a1"
                          expect(@authentication_details[:azure_client_secret]).to be ==  "xyz@123"
                        end

                        it 'use Token Authentication for Windows/Linux Platform' do
                          token_details = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2116-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
                          Chef::Config[:knife].delete(:azure_tenant_id)
                          allow(@arm_server_instance).to receive(:token_details_for_linux).and_return(token_details) 
                          allow(@arm_server_instance).to receive(:token_details_for_windows).and_return(token_details)
                          @authentication_details = @arm_server_instance.check_authentication_method
                          expect(@authentication_details[:clientid]).to be ==  "dsff-8df-sd45e-34345f7b46"
                        end

                        it 'Get token details from Accesstoken file for Linux' do
                          file_data = File.read(File.dirname(__FILE__) + "/assets/accessTokens.json")
                          allow(File).to receive(:read).and_return(file_data)
                          @authentication_details = @arm_server_instance.token_details_for_linux
                          expect(@authentication_details[:clientid]).to be ==  "dsff-8df-sd45e-34345f7b46"
                        end
                 end
        end
end
