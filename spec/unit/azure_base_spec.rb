#
# Author:: Ameya Varade (<ameya.varade@clogeny.com>)
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
    Chef::Config[:knife][:azure_api_host_name] = "preview.core.windows-int.net"
    Chef::Config[:knife][:azure_subscription_id] = "azure_subscription_id"
    Chef::Config[:knife][:azure_mgmt_cert] = @cert_file
    allow(@dummy.ui).to receive(:error)
  end
  describe "azure base tests - " do
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
        @dummy.validate_asm_keys!
        expect(Chef::Config[:knife][:azure_api_host_name]).to be == "preview.core.windows-int.net"
        expect(Chef::Config[:knife][:azure_subscription_id]).to be == "azure_subscription_id"
      end

      it "- should validate extract parameters" do
        Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureValid.publishsettings")
        @dummy.validate_asm_keys!
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
        @dummy.validate_asm_keys!
        expect(Chef::Config[:knife][:azure_api_host_name]).to be == "management.core.windows.net"
        expect(@dummy.config[:azure_subscription_id]).to be == "azure_subscription_id"
        expect(Chef::Config[:knife][:azure_subscription_id]).to be == "id1"
        validate_cert
      end

      it "- should raise error if invalid publish settings provided" do
        Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureInvalid.publishsettings")
        expect { @dummy.validate_asm_keys! }.to raise_error(SystemExit)
      end

      it "- should raise error if publish settings file does not exists" do
        Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("azureNotAvailable.publishsettings")
        expect { @dummy.validate_asm_keys! }.to raise_error(SystemExit)
      end
    end
  end

  describe "azure base tests - for azure profile" do
    before(:each) do
      Chef::Config[:knife][:azure_mgmt_cert] = nil
    end

    context "when publishSettings file specified in knife.rb has A account and azureProfile file has B account" do
      before do
        Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("A_account.publishsettings")
        allow(@dummy).to receive(:get_azure_profile_file_path).and_return(File.dirname(__FILE__) + "/assets/azure-profile-files/B_account_azure_profile.json")
      end

      it "selects A account of publishSettings file" do
        @dummy.validate_asm_keys!
        expect(Chef::Config[:knife][:azure_api_host_name]).to eq("A.endpoint.net")
        expect(Chef::Config[:knife][:azure_subscription_id]).to eq("A_subscription_id")
      end
    end

    context "when publishSettings file specified in knife.rb has B account and azureProfile file has A account" do
      before do
        Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("B_account.publishsettings")
        allow(@dummy).to receive(:get_azure_profile_file_path).and_return(File.dirname(__FILE__) + "/assets/azure-profile-files/A_account_azure_profile.json")
        Chef::Config[:knife][:azure_api_host_name] = "preview.core.windows-int.net"
        Chef::Config[:knife][:azure_subscription_id] = "azure_subscription_id"
        Chef::Config[:knife][:azure_mgmt_cert] = @cert_file
      end

      it "selects B account of publishSettings file" do
        @dummy.validate_asm_keys!
        expect(Chef::Config[:knife][:azure_api_host_name]).to eq("B.endpoint.net")
        expect(Chef::Config[:knife][:azure_subscription_id]).to eq("B_subscription_id")
      end
    end

    context "when publishSettings file is not specified in knife.rb and azureProfile file has A account" do
      before do
        Chef::Config[:knife][:azure_publish_settings_file] = nil
        Chef::Config[:knife][:azure_api_host_name] = nil
        Chef::Config[:knife][:azure_subscription_id] = nil
        Chef::Config[:knife][:azure_mgmt_cert] = nil
        allow(@dummy).to receive(:get_azure_profile_file_path).and_return(File.dirname(__FILE__) + "/assets/azure-profile-files/A_account_azure_profile.json")
      end

      it "selects A account of azureProfile file" do
        @dummy.validate_asm_keys!
        expect(Chef::Config[:knife][:azure_api_host_name]).to eq("A.endpoint.net")
        expect(Chef::Config[:knife][:azure_subscription_id]).to eq("A_subscription_id")
      end
    end

    context "when publishSettings file is not specified in knife.rb and azureProfile file has B account" do
      before do
        Chef::Config[:knife][:azure_publish_settings_file] = nil

        Chef::Config[:knife][:azure_api_host_name] = nil
        Chef::Config[:knife][:azure_subscription_id] = nil
        Chef::Config[:knife][:azure_mgmt_cert] = nil
        allow(@dummy).to receive(:get_azure_profile_file_path).and_return(File.dirname(__FILE__) + "/assets/azure-profile-files/B_account_azure_profile.json")
      end

      it "selects B account of azureProfile file" do
        @dummy.validate_asm_keys!
        expect(Chef::Config[:knife][:azure_api_host_name]).to eq("B.endpoint.net")
        expect(Chef::Config[:knife][:azure_subscription_id]).to eq("B_subscription_id")
      end
    end

    context "when neither publishSettings file is specified in knife.rb nor azureProfile file exist" do
      before do
        Chef::Config[:knife][:azure_publish_settings_file] = nil
        allow(@dummy).to receive(:get_azure_profile_file_path).and_return(File.dirname(__FILE__) + "/assets/azure-profile-files/C_account_azure_profile.json")
      end

      it "gives error and exits" do
        expect { @dummy.validate_asm_keys! }.to raise_error SystemExit
      end
    end

    context "when publishSettings file is not specified in knife.rb and azureProfile file has both A and B account with B as the default account" do
      before do
        Chef::Config[:knife][:azure_publish_settings_file] = nil

        Chef::Config[:knife][:azure_api_host_name] = nil
        Chef::Config[:knife][:azure_subscription_id] = nil
        Chef::Config[:knife][:azure_mgmt_cert] = nil
        allow(@dummy).to receive(:get_azure_profile_file_path).and_return(File.dirname(__FILE__) + "/assets/azure-profile-files/A_Bd_account_azure_profile.json")
      end

      it "selects B account of azureProfile file" do
        @dummy.validate_asm_keys!
        expect(Chef::Config[:knife][:azure_api_host_name]).to eq("B.endpoint.net")
        expect(Chef::Config[:knife][:azure_subscription_id]).to eq("B_subscription_id")
      end
    end

    context "when publishSettings file is not specified in knife.rb and azureProfile file has both A and B account with A as the default account" do
      before do
        Chef::Config[:knife][:azure_publish_settings_file] = nil
        Chef::Config[:knife][:azure_api_host_name] = nil
        Chef::Config[:knife][:azure_subscription_id] = nil
        Chef::Config[:knife][:azure_mgmt_cert] = nil
        allow(@dummy).to receive(:get_azure_profile_file_path).and_return(File.dirname(__FILE__) + "/assets/azure-profile-files/Ad_B_account_azure_profile.json")
      end

      it "selects A account of azureProfile file" do
        @dummy.validate_asm_keys!
        expect(Chef::Config[:knife][:azure_api_host_name]).to eq("A.endpoint.net")
        expect(Chef::Config[:knife][:azure_subscription_id]).to eq("A_subscription_id")
      end
    end

    context "when publishSettings file specified in knife.rb has A account and azureProfile file has both A and B account with B as the default account" do
      before do
        Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("A_account.publishsettings")
        allow(@dummy).to receive(:get_azure_profile_file_path).and_return(File.dirname(__FILE__) + "/assets/azure-profile-files/A_Bd_account_azure_profile.json")
      end

      it "selects A account of publishSettings file" do
        @dummy.validate_asm_keys!
        expect(Chef::Config[:knife][:azure_api_host_name]).to eq("A.endpoint.net")
        expect(Chef::Config[:knife][:azure_subscription_id]).to eq("A_subscription_id")
      end
    end

    context "when publishSettings file specified in knife.rb has B account and azureProfile file has both A and B account with A as the default account" do
      before do
        Chef::Config[:knife][:azure_publish_settings_file] = get_publish_settings_file_path("B_account.publishsettings")
        allow(@dummy).to receive(:get_azure_profile_file_path).and_return(File.dirname(__FILE__) + "/assets/azure-profile-files/Ad_B_account_azure_profile.json")
      end

      it "selects B account of publishSettings file" do
        @dummy.validate_asm_keys!
        expect(Chef::Config[:knife][:azure_api_host_name]).to eq("B.endpoint.net")
        expect(Chef::Config[:knife][:azure_subscription_id]).to eq("B_subscription_id")
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
end
