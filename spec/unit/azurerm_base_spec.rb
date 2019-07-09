#
# Author:: Dheeraj Dubey (<dheeraj.dubey@msystechnologies.com>)
# Copyright:: Copyright 2010-2019, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/../unit/query_azure_mock")

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
    Chef::Config[:knife][:azure_api_host_name] = "preview.core.windows-int.net"
    Chef::Config[:knife][:azure_subscription_id] = "azure_subscription_id"
    Chef::Config[:knife][:azure_mgmt_cert] = @cert_file
    allow(@dummy.ui).to receive(:error)
    @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerList)
    @service = @arm_server_instance.service
    @compute_client = double("ComputeManagementClient")
    @arm_server_instance.instance_variable_set(:@azure_prefix, "azure")
  end

  describe "azurerm base tests - " do
    context "Tests for publish settings file" do
      before do
        Chef::Config[:knife][:azure_api_host_name] = nil
        Chef::Config[:knife][:azure_subscription_id] = nil
      end

      def validate_cert
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
        expect(Chef::Config[:knife][:azure_api_host_name]).to be == "management.core.windows.net"
        expect(Chef::Config[:knife][:azure_subscription_id]).to be == "id1"
        validate_cert
      end

      it "- should validate parse method" do
        @dummy.parse_publish_settings_file(get_publish_settings_file_path("azureValid.publishsettings"))
        expect(Chef::Config[:knife][:azure_api_host_name]).to be == "management.core.windows.net"
        expect(Chef::Config[:knife][:azure_subscription_id]).to be == "id1"
        validate_cert
      end

      it "- should validate parse method for SchemaVersion2-0 publishsettings file" do
        @dummy.parse_publish_settings_file(get_publish_settings_file_path("azureValidSchemaVersion-2.0.publishsettings"))
        expect(Chef::Config[:knife][:azure_api_host_name]).to be == "management.core.windows.net"
        expect(Chef::Config[:knife][:azure_subscription_id]).to be == "id1"
        validate_cert
      end

      it "- should validate settings file and subscrition id" do
        @dummy.config[:azure_subscription_id] = "azure_subscription_id"
        Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureValid.publishsettings")
        @dummy.validate_arm_keys!
        expect(Chef::Config[:knife][:azure_api_host_name]).to be == "management.core.windows.net"
        expect(@dummy.config[:azure_subscription_id]).to be == "azure_subscription_id"
        expect(Chef::Config[:knife][:azure_subscription_id]).to be == "id1"
        validate_cert
      end
    end
  end

  describe "Token related test cases" do
    context "Xplat Azure login validation" do
      context "Platform is Linux" do
        let (:azure_prefix) { @dummy.instance_variable_get(:@azure_prefix) }
        before(:each) do
          allow(Chef::Platform).to receive(:windows?).and_return(false)
        end
        it "Accesstoken file doesnt exist for Linux" do
          allow(File).to receive(:exist?).and_return(false)
          expect { @arm_server_instance.validate_azure_login }.to raise_error("Please run XPLAT's 'azure login' command OR specify azure_tenant_id, azure_subscription_id, azure_client_id, azure_client_secret in your knife.rb")
        end

        it "Accesstoken file exist for Linux" do
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:size?).and_return(4)
          expect { @arm_server_instance.validate_azure_login }.not_to raise_error
        end

        it "Accesstoken file contain [] value upon running azure logout command for Linux" do
          allow(File).to receive(:size?).and_return(2)
          expect { @arm_server_instance.validate_azure_login }.to raise_error("Please run XPLAT's 'azure login' command OR specify azure_tenant_id, azure_subscription_id, azure_client_id, azure_client_secret in your knife.rb")
        end
      end

      context "Platform is Windows" do
        let(:xplat_creds_cmd) { double(run_command: double) }

        before(:each) do
          allow(Chef::Platform).to receive(:windows?).and_return(true)
        end

        context "old xplat_cli version is installed" do
          before do
            allow(@arm_server_instance).to receive(:is_old_xplat?).and_return(true)
          end

          it "validates azure login status by checking in WCM through cmdkey system command" do
            expect(Mixlib::ShellOut).to receive(:new).with(
              "cmdkey /list | findstr AzureXplatCli"
            ).and_return(xplat_creds_cmd)
            allow(xplat_creds_cmd.run_command).to receive(
              :stdout
            ).and_return("azure_cli_logged_in")
            expect { @arm_server_instance.validate_azure_login }.to_not raise_error
          end
        end

        context "new xplat_cli version is installed" do
          before(:each) do
            allow(@arm_server_instance).to receive(:is_old_xplat?).and_return(false)
          end

          context "WCM is used for token storage" do
            before do
              allow(@arm_server_instance).to receive(:is_WCM_env_var_set?).and_return(true)
            end

            context "token is not present in WCM" do
              before do
                allow(xplat_creds_cmd.run_command).to receive(:stdout).and_return("")
              end

              it "raises error" do
                expect(Mixlib::ShellOut).to receive(:new).with(
                  "cmdkey /list | findstr AzureXplatCli"
                ).and_return(xplat_creds_cmd)
                expect { @arm_server_instance.validate_azure_login }.to raise_error("Please run XPLAT's 'azure login' command OR specify azure_tenant_id, azure_subscription_id, azure_client_id, azure_client_secret in your knife.rb")
              end
            end

            context "token is present in WCM" do
              before do
                allow(xplat_creds_cmd.run_command).to receive(
                  :stdout
                ).and_return("azure_cli_logged_in")
              end

              it "does not raise error" do
                expect(Mixlib::ShellOut).to receive(:new).with(
                  "cmdkey /list | findstr AzureXplatCli"
                ).and_return(xplat_creds_cmd)
                expect { @arm_server_instance.validate_azure_login }.to_not raise_error
              end
            end
          end

          context "accessTokens.json file is used for token storage" do
            before do
              allow(@arm_server_instance).to receive(:is_WCM_env_var_set?).and_return(false)
            end

            context "token not present in accessTokens.json file" do
              before do
                allow(File).to receive(:exist?).and_return(true)
                allow(File).to receive(:size?).and_return(2)
              end

              it "raises error" do
                expect(Mixlib::ShellOut).to_not receive(:new)
                expect(File).to receive(:expand_path).and_return("user_home_path")
                expect { @arm_server_instance.validate_azure_login }.to raise_error("Please run XPLAT's 'azure login' command OR specify azure_tenant_id, azure_subscription_id, azure_client_id, azure_client_secret in your knife.rb")
              end
            end

            context "token present in accessTokens.json file" do
              before do
                allow(File).to receive(:exist?).and_return(true)
                allow(File).to receive(:size?).and_return(4)
              end

              it "does not raise error" do
                expect(Mixlib::ShellOut).to_not receive(:new)
                expect(File).to receive(:expand_path).and_return("user_home_path")
                expect { @arm_server_instance.validate_azure_login }.not_to raise_error
              end
            end
          end
        end
      end
    end

    context "Token Validation test cases" do
      before do
        allow(Mixlib::ShellOut).to receive_message_chain(:new, :run_command)
      end

      it "raises exception if token is expired for Linux" do
        token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        allow(@arm_server_instance).to receive(:refresh_token).and_return(token_details)
        allow(@arm_server_instance).to receive(:token_details_for_linux).and_return(token_details)
        expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error("Token has expired. Please run 'azure login' command")
      end

      it "raises exception if token is expired for Windows" do
        token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(@arm_server_instance).to receive(:refresh_token).and_return(token_details)
        allow(@arm_server_instance).to receive(:token_details_for_windows).and_return(token_details)
        expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error("Token has expired. Please run 'azure login' command")
      end

      it "Token is valid, no exception is raised" do
        token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2116-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        expect { @arm_server_instance.check_token_validity(token_details) }.not_to raise_error
      end

      it "New token is got using refresh token for Linux when token has expired" do
        token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        token_details1 = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2116-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        allow(@arm_server_instance).to receive(:refresh_token).and_return(token_details1)
        allow(@arm_server_instance).to receive(:token_details_for_linux).and_return(token_details)
        expect { @arm_server_instance.check_token_validity(token_details) }.not_to raise_error
      end

      it "New valid token is got using refresh token for Windows when token has expired" do
        token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        token_details1 = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2116-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(@arm_server_instance).to receive(:refresh_token).and_return(token_details1)
        allow(@arm_server_instance).to receive(:token_details_for_windows).and_return(token_details)
        expect { @arm_server_instance.check_token_validity(token_details) }.not_to raise_error
      end

      it "Mixlib shellout command for xplat raises Timeout error" do
        token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(Mixlib::ShellOut).to receive_message_chain(:new, :run_command).and_raise(Mixlib::ShellOut::CommandTimeout)
        allow(@arm_server_instance).to receive(:token_details_for_windows).and_return(token_details)
        expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error("Token has expired. Please run 'azure login' command")
      end

      it "Mixlib shellout command for xplat raises exception" do
        token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        allow(Mixlib::ShellOut).to receive_message_chain(:new, :run_command).and_raise(Exception)
        allow(@arm_server_instance).to receive(:token_details_for_linux).and_return(token_details)
        expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error("Token has expired. Please run 'azure login' command")
      end
    end

    context "is_token_valid?" do
      it "returns true if token is valid" do
        token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2116-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        token_valid = @arm_server_instance.is_token_valid?(token_details)
        expect(token_valid).to be == true
      end

      it "returns false if token has expired" do
        token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        token_valid = @arm_server_instance.is_token_valid?(token_details)
        expect(token_valid).to be == false
      end

      it "raises exception if token is about to expire within 10 minutes" do
        time_after_5_min = (Time.now + 300).to_s # 300sec = 5min
        token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: time_after_5_min, clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        expect { @arm_server_instance.is_token_valid?(token_details) }.to raise_error("Token will expire within 10 minutes. Please run 'azure login' command")
      end
    end

    context "ARM Authentication test cases" do
      before do
        Chef::Config[:knife][:azure_tenant_id] = "abeb039a-rfrgrggb48f-0c99bdc99d15"
        Chef::Config[:knife][:azure_client_id] = "54dsdwe-3e2f36-e9f11d7f88a1"
        Chef::Config[:knife][:azure_client_secret] = "xyz@123"
      end

      it "using AD App creds for authentication" do
        @authentication_details = @arm_server_instance.authentication_details
        expect(@authentication_details[:azure_tenant_id]).to be ==  "abeb039a-rfrgrggb48f-0c99bdc99d15"
        expect(@authentication_details[:azure_client_id]).to be ==  "54dsdwe-3e2f36-e9f11d7f88a1"
        expect(@authentication_details[:azure_client_secret]).to be == "xyz@123"
      end

      it "using Token Authentication for Linux Platform" do
        token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2116-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        Chef::Config[:knife].delete(:azure_tenant_id)
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        allow(@arm_server_instance).to receive(:token_details_for_linux).and_return(token_details)
        @authentication_details = @arm_server_instance.authentication_details
        expect(@authentication_details[:clientid]).to be == "dsff-8df-sd45e-34345f7b46"
      end

      it "using Token Authentication for Windows Platform" do
        token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2116-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
        Chef::Config[:knife].delete(:azure_tenant_id)
        allow(Chef::Platform).to receive(:windows?).and_return(true)
        allow(@arm_server_instance).to receive(:token_details_for_windows).and_return(token_details)
        @authentication_details = @arm_server_instance.authentication_details
        expect(@authentication_details[:clientid]).to be == "dsff-8df-sd45e-34345f7b46"
      end

      it "Get token details from Accesstoken file for Linux platform" do
        allow(Chef::Platform).to receive(:windows?).and_return(false)
        file_data = File.read(File.dirname(__FILE__) + "/assets/accessTokens.json")
        allow(File).to receive(:read).and_return(file_data)
        @authentication_details = @arm_server_instance.token_details_for_linux
        expect(@authentication_details[:clientid]).to be == "dsff-8df-sd45e-34345f7b46"
      end
    end

    context "find_file" do
      it "finds the file with given path" do
        file_path = get_publish_settings_file_path("azureValid.publishsettings")
        Chef::Config[:knife][:azure_publish_settings_file] = file_path
        expect(@dummy.find_file(Chef::Config[:knife][:azure_publish_settings_file])).to eq file_path
      end
    end
  end

  describe "current_xplat_cli_version" do
    let(:mixlib_object) { double("MixlibObject", stdout: "0.10.4") }

    it "returns the version of xplat_cli" do
      expect(@arm_server_instance).to receive(:shell_out!).and_return(mixlib_object)
      response = @arm_server_instance.get_azure_cli_version
      expect(response).to be == "0.10.4"
    end
  end

  describe "is_old_xplat?" do
    context "old version of xplat_cli is installed" do
      before do
        allow(@arm_server_instance).to receive(
          :current_xplat_cli_version
        ).and_return("0.10.3")
      end

      it "returns true" do
        response = @arm_server_instance.send(:is_old_xplat?)
        expect(response).to be == true
      end
    end

    context "new version of xplat_cli is installed" do
      before do
        allow(@arm_server_instance).to receive(:get_azure_cli_version).and_return("2.0.0")
      end

      it "returns true" do
        response = @arm_server_instance.send(:is_old_xplat?)
        expect(response).to be == true
      end
    end
  end

  describe "is_WCM_env_var_set?" do
    context "environment variable is not set" do
      it "returns false" do
        response = @arm_server_instance.send(:is_WCM_env_var_set?)
        expect(response).to be == false
      end
    end

    context "environment variable is set" do
      before do
        allow(ENV).to receive(:[]).with(
          "AZURE_USE_SECURE_TOKEN_STORAGE"
        ).and_return("true")
      end

      it "returns true" do
        response = @arm_server_instance.send(:is_WCM_env_var_set?)
        expect(response).to be == true
      end
    end
  end

  describe "token_details_for_windows" do
    context "old version of xplat_cli is installed" do
      before do
        allow(@arm_server_instance).to receive(:is_old_xplat?).and_return(true)
      end

      it "invokes appropriate method to fetch token details from WCM" do
        expect(@arm_server_instance).to receive(:token_details_from_WCM)
        expect(@arm_server_instance).to_not receive(:is_WCM_env_var_set?)
        expect(@arm_server_instance).to_not receive(:token_details_from_accessToken_file)
        @arm_server_instance.token_details_for_windows
      end
    end

    context "new version of xplat_cli is installed" do
      before(:each) do
        allow(@arm_server_instance).to receive(:is_old_xplat?).and_return(false)
      end

      context "WCM is used for token storage" do
        before do
          allow(@arm_server_instance).to receive(:is_WCM_env_var_set?).and_return(true)
        end

        it "invokes appropriate method to fetch token details from WCM" do
          expect(@arm_server_instance).to receive(:token_details_from_WCM)
          expect(@arm_server_instance).to_not receive(:token_details_from_accessToken_file)
          @arm_server_instance.token_details_for_windows
        end
      end

      context "accessTokens.json file is used for token storage" do
        before do
          allow(@arm_server_instance).to receive(:is_WCM_env_var_set?).and_return(false)
        end

        it "invokes appropriate method to fetch token details from accessTokens.json file" do
          expect(@arm_server_instance).to_not receive(:token_details_from_WCM)
          expect(@arm_server_instance).to receive(:token_details_from_accessToken_file)
          @arm_server_instance.token_details_for_windows
        end
      end
    end
  end

  context "Token Validation test cases for Azure CLI 2.0" do
    before do
      @arm_server_instance.instance_variable_set(:@azure_prefix, "az")
      allow(Mixlib::ShellOut).to receive_message_chain(:new, :run_command)
    end

    it "raises exception if token is expired for Linux" do
      token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
      allow(Chef::Platform).to receive(:windows?).and_return(false)
      allow(@arm_server_instance).to receive(:refresh_token).and_return(token_details)
      allow(@arm_server_instance).to receive(:token_details_for_linux).and_return(token_details)
      expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error("Token has expired. Please run 'az login' command")
    end

    it "raises exception if token is expired for Windows" do
      token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
      allow(Chef::Platform).to receive(:windows?).and_return(true)
      allow(@arm_server_instance).to receive(:refresh_token).and_return(token_details)
      allow(@arm_server_instance).to receive(:token_details_for_windows).and_return(token_details)
      expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error("Token has expired. Please run 'az login' command")
    end

    it "Token is valid, no exception is raised" do
      token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2116-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
      expect { @arm_server_instance.check_token_validity(token_details) }.not_to raise_error
    end

    it "New token is got using refresh token for Linux when token has expired" do
      token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
      token_details1 = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2116-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
      allow(Chef::Platform).to receive(:windows?).and_return(false)
      allow(@arm_server_instance).to receive(:refresh_token).and_return(token_details1)
      allow(@arm_server_instance).to receive(:token_details_for_linux).and_return(token_details)
      expect { @arm_server_instance.check_token_validity(token_details) }.not_to raise_error
    end

    it "New valid token is got using refresh token for Windows when token has expired" do
      token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
      token_details1 = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2116-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
      allow(Chef::Platform).to receive(:windows?).and_return(true)
      allow(@arm_server_instance).to receive(:refresh_token).and_return(token_details1)
      allow(@arm_server_instance).to receive(:token_details_for_windows).and_return(token_details)
      expect { @arm_server_instance.check_token_validity(token_details) }.not_to raise_error
    end

    it "Mixlib shellout command for xplat raises Timeout error" do
      token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
      allow(Chef::Platform).to receive(:windows?).and_return(true)
      allow(Mixlib::ShellOut).to receive_message_chain(:new, :run_command).and_raise(Mixlib::ShellOut::CommandTimeout)
      allow(@arm_server_instance).to receive(:token_details_for_windows).and_return(token_details)
      expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error("Token has expired. Please run 'az login' command")
    end

    it "Mixlib shellout command for xplat raises exception" do
      token_details = { tokentype: "Bearer", user: "xxx@outlook.com", token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1iIxLjAifQ.hZjHXXjbSdMmMs9oSZxGKa62EnNG6jkTY4RSmq8dQMvmwHgDCF4KoT_sOIsrAJTVwXuCdxYa5Jr83sfydFwiO2QWWOaSgyRXGPouex4NXFI_LFdnRzhLBoN0ONwUWHrV12N4LBgHyNLiyfeZQJFCbD0LTcPdjh7qQZ5aVgcoz_CB33PGD_z2L_6ynWrlAoihLEmYD6vbebMDSSFazvzoVg", expiry_time: "2016-05-31T09:42:15.617Z", clientid: "dsff-8df-sd45e-34345f7b46", refreshtoken: "FPbm0gXiszvV_cMwGkgACwMBZ26fWA6fH3ToRLTHYU3wvvTWiU74ukRhMHhv20OJOtZBOtbckh3kTMT7QvzUYfd4uHFzwAYCtsh2SOY-dCAA" }
      allow(Chef::Platform).to receive(:windows?).and_return(false)
      allow(Mixlib::ShellOut).to receive_message_chain(:new, :run_command).and_raise(Exception)
      allow(@arm_server_instance).to receive(:token_details_for_linux).and_return(token_details)
      expect { @arm_server_instance.check_token_validity(token_details) }.to raise_error("Token has expired. Please run 'az login' command")
    end
  end
end
