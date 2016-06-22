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
    end
  end

  describe "Token related test cases" do
    context 'Xplat Azure login validation' do
      it 'Accesstoken file doesnt exist for Linux' do
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        allow(File).to receive(:exists?).and_return(false)
        expect { @arm_server_instance.validate_azure_login }.to raise_error("Please run XPLAT's 'azure login' command OR specify azure_tenant_id, azure_subscription_id, azure_client_id, azure_client_secret in your knife.rb")
      end

      it 'Accesstoken file exist for Linux' do
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        allow(File).to receive(:exists?).and_return(true)
        allow(File).to receive(:size?).and_return(4)
        expect { @arm_server_instance.validate_azure_login }.not_to raise_error("Please run XPLAT's 'azure login' command OR specify azure_tenant_id, azure_subscription_id, azure_client_id, azure_client_secret in your knife.rb")
      end

      it 'Accesstoken file contain [] value upon running azure logout command for Linux' do
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        allow(File).to receive(:size?).and_return(2)
        expect { @arm_server_instance.validate_azure_login }.to raise_error("Please run XPLAT's 'azure login' command OR specify azure_tenant_id, azure_subscription_id, azure_client_id, azure_client_secret in your knife.rb")
      end

      it 'Token Object not present in windows credential manager' do
        @xplat_creds_cmd = double(:run_command => double)
        @result = double(:stdout => "")
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(Mixlib::ShellOut).to receive(:new).and_return(@xplat_creds_cmd)
        allow(@xplat_creds_cmd).to receive(:run_command).and_return(@result)
        allow(@result).to receive(:stdout).and_return("")
        expect { @arm_server_instance.validate_azure_login }.to raise_error("Please run XPLAT's 'azure login' command OR specify azure_tenant_id, azure_subscription_id, azure_client_id, azure_client_secret in your knife.rb")
      end

      it 'Token Object present in windows credential manager' do
        @xplat_creds_cmd = double(:run_command => double)
        @result = double(:stdout => double)
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(Mixlib::ShellOut).to receive(:new).and_return(@xplat_creds_cmd)
        allow(@xplat_creds_cmd).to receive(:run_command).and_return(@result)
        allow(@result).to receive(:stdout).and_return(double)
        expect { @arm_server_instance.validate_azure_login }.not_to raise_error("Please run XPLAT's 'azure login' command OR specify azure_tenant_id, azure_subscription_id, azure_client_id, azure_client_secret in your knife.rb")
      end

    end

    context "Token Validation test cases" do
      before do
         allow(Mixlib::ShellOut).to receive_message_chain(:new,:run_command)
      end

      it "raises exception if token is expired for Linux" do
        token_details = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2016-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        allow(@arm_server_instance).to receive(:refresh_token).and_return(token_details)
        allow(@arm_server_instance).to receive(:token_details_for_linux).and_return(token_details)
        expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error("Token has expired. Please run 'azure login' command")
      end

      it "raises exception if token is expired for Windows" do
        token_details = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2016-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(@arm_server_instance).to receive(:refresh_token).and_return(token_details)
        allow(@arm_server_instance).to receive(:token_details_for_windows).and_return(token_details)
        expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error("Token has expired. Please run 'azure login' command")
      end

      it 'Token is valid, no exception is raised' do
        token_details = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2116-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
        expect { @arm_server_instance.check_token_validity(token_details) }.not_to raise_error("Token has expired. Please run 'azure login' command")
      end

      it 'New token is got using refresh token for Linux when token has expired' do
        token_details = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2016-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
        token_details1 = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2116-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        allow(@arm_server_instance).to receive(:refresh_token).and_return(token_details1)
        allow(@arm_server_instance).to receive(:token_details_for_linux).and_return(token_details)
        expect { @arm_server_instance.check_token_validity(token_details) }.not_to raise_error("Token has expired. Please run 'azure login' command")
      end

      it 'New valid token is got using refresh token for Windows when token has expired' do
        token_details = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2016-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
        token_details1 = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2116-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(@arm_server_instance).to receive(:refresh_token).and_return(token_details1)
        allow(@arm_server_instance).to receive(:token_details_for_windows).and_return(token_details)
        expect { @arm_server_instance.check_token_validity(token_details) }.not_to raise_error("Token has expired. Please run 'azure login' command")
      end

      it 'Mixlib shellout command for xplat raises Timeout error' do
        token_details = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2016-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(Mixlib::ShellOut).to receive_message_chain(:new,:run_command).and_raise(Mixlib::ShellOut::CommandTimeout)
        allow(@arm_server_instance).to receive(:token_details_for_windows).and_return(token_details)
        expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error("Token has expired. Please run 'azure login' command")
      end

      it 'Mixlib shellout command for xplat raises exception' do
        token_details = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2016-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"} 
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        allow(Mixlib::ShellOut).to receive_message_chain(:new,:run_command).and_raise(Exception)
        allow(@arm_server_instance).to receive(:token_details_for_linux).and_return(token_details)
        expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error("Token has expired. Please run 'azure login' command")
      end
    end

    context "ARM Authentication test cases" do
      before do
        Chef::Config[:knife][:azure_tenant_id] = "abeb039a-rfrgrggb48f-0c99bdc99d15"
        Chef::Config[:knife][:azure_client_id] = "54dsdwe-3e2f36-e9f11d7f88a1"
        Chef::Config[:knife][:azure_client_secret] = "xyz@123"
      end

      it 'using AD App creds for authentication' do
        @authentication_details = @arm_server_instance.authentication_details
        expect(@authentication_details[:azure_tenant_id]).to be ==  "abeb039a-rfrgrggb48f-0c99bdc99d15"
        expect(@authentication_details[:azure_client_id]).to be ==  "54dsdwe-3e2f36-e9f11d7f88a1"
        expect(@authentication_details[:azure_client_secret]).to be ==  "xyz@123"
      end

      it 'using Token Authentication for Linux Platform' do
        token_details = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2116-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
        Chef::Config[:knife].delete(:azure_tenant_id)
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        allow(@arm_server_instance).to receive(:token_details_for_linux).and_return(token_details)
        @authentication_details = @arm_server_instance.authentication_details
        expect(@authentication_details[:clientid]).to be ==  "dsff-8df-sd45e-34345f7b46"
      end

      it 'using Token Authentication for Windows Platform' do
        token_details = {:tokentype => "Bearer", :user => "xxx@outlook.com", :token => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", :expiry_time => "2116-05-31T09:42:15.617Z", :clientid => "dsff-8df-sd45e-34345f7b46", :refreshtoken => "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA"}
        Chef::Config[:knife].delete(:azure_tenant_id)
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(@arm_server_instance).to receive(:token_details_for_windows).and_return(token_details)
        @authentication_details = @arm_server_instance.authentication_details
        expect(@authentication_details[:clientid]).to be ==  "dsff-8df-sd45e-34345f7b46"
      end

      it 'Get token details from Accesstoken file for Linux platform' do
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        file_data = File.read(File.dirname(__FILE__) + "/assets/accessTokens.json")
        allow(File).to receive(:read).and_return(file_data)
        @authentication_details = @arm_server_instance.token_details_for_linux
        expect(@authentication_details[:clientid]).to be ==  "dsff-8df-sd45e-34345f7b46"
      end

      it 'Get Target name from Windows credential manager for Windows platform' do
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        target = "AzureXplatCli:target=_authority:https\://login.microsoftonline.com/abeb039a-rfrgrggb48f-0c99bdc99d15::_clientId:dsff-8df-sd45e-34345f7b46::expiresIn:3599::expiresOn:2116-05-31T09\:42\:15.617Z::identityProvider:live.com::isMRRT:true::resource:https\://management.core.windows.net/::tokenType:Bearer::userId:xxx@outlook.com--0-2"
        allow(@arm_server_instance).to receive(:target_name).and_return(target)
      end
    end
  end
end
