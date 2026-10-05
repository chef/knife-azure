#
# Author:: Nimisha Sharad (<nimisha.sharad@clogeny.com>)
# Copyright:: Copyright (c) 2012-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../spec_helper"
require_relative "query_azure_mock"
require "chef/knife/bootstrap"

describe Chef::Knife::BootstrapAzurerm do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @bootstrap_azurerm_instance = create_arm_instance(Chef::Knife::BootstrapAzurerm)
    @bootstrap_azurerm_instance.merge_configs
    @service = @bootstrap_azurerm_instance.service
    @bootstrap_azurerm_instance.name_args = ["test-vm-01"]
    @bootstrap_azurerm_instance.config[:azure_resource_group_name] = "test-rgp-01"
    @bootstrap_azurerm_instance.config[:azure_service_location] = "West US"

    @compute_client = double("ComputeManagementClient")
    allow(@bootstrap_azurerm_instance.service).to receive(
      :compute_management_client
    ).and_return(@compute_client)
    allow(@bootstrap_azurerm_instance).to receive(:check_license)
  end

  context "parameters validation" do
    it "raises error when server name is not given in the args" do
      @bootstrap_azurerm_instance.name_args = []
      expect(@bootstrap_azurerm_instance.ui).to receive(:log).with("Validating...")
      expect(@bootstrap_azurerm_instance).to receive(:validate_arm_keys!)
      expect(@service).to_not receive(:create_vm_extension)
      expect(@bootstrap_azurerm_instance.ui).to receive(:error)
      expect(Chef::Log).to receive(:debug).at_least(:once)
      @bootstrap_azurerm_instance.run
    end

    it "raises error when azure_resource_group_name is not specified" do
      @bootstrap_azurerm_instance.config.delete(:azure_resource_group_name)
      expect(@bootstrap_azurerm_instance.ui).to receive(:log).with("Validating...")
      expect(@bootstrap_azurerm_instance.ui).to receive(:error)
      expect { @bootstrap_azurerm_instance.run }.to raise_error(SystemExit)
    end

    it "raises error when azure_service_location is not specified" do
      @bootstrap_azurerm_instance.config.delete(:azure_service_location)
      expect(@bootstrap_azurerm_instance.ui).to receive(:log).with("Validating...")
      expect(@bootstrap_azurerm_instance.ui).to receive(:error)
      expect { @bootstrap_azurerm_instance.run }.to raise_error(SystemExit)
    end

    it "raises error when more than one server name is specified" do
      @bootstrap_azurerm_instance.name_args = %w{test-vm-01 test-vm-02 test-vm-03}
      expect(@bootstrap_azurerm_instance.name_args.length).to be == 3
      expect(@bootstrap_azurerm_instance.ui).to receive(:log).with("Validating...")
      expect(@service).to_not receive(:create_vm_extension)
      expect(@bootstrap_azurerm_instance.ui).to receive(:error)
      expect(Chef::Log).to receive(:debug).at_least(:once)
      @bootstrap_azurerm_instance.run
    end

    it "raises error when server name specified does not exist under the given hosted service" do
      expect(@bootstrap_azurerm_instance.name_args.length).to be == 1
      expect(@service).to_not receive(:create_vm_extension)
      expect(@service).to receive(:find_server).and_return(nil)
      expect(@bootstrap_azurerm_instance.ui).to receive(:log).twice
      expect(@bootstrap_azurerm_instance.ui).to receive(:error)
      expect(Chef::Log).to receive(:debug).at_least(:once)
      @bootstrap_azurerm_instance.run
    end

    it "raises error if the extension is already installed on the server" do
      @server = double("server", name: "foo")
      expect(@bootstrap_azurerm_instance.name_args.length).to be == 1
      expect(@bootstrap_azurerm_instance.ui).to receive(:log).twice
      allow(@service).to receive(:find_server).and_return(@server)
      allow(@service).to receive(:extension_already_installed?).and_return(true)
      expect(@bootstrap_azurerm_instance.ui).to receive(:error)
      expect(Chef::Log).to receive(:debug).at_least(:once)
      @bootstrap_azurerm_instance.run
    end
  end

  context "set_ext_params" do
    it "sets ChefClient extension in the ext_params for windows" do
      @server = double("server")
      allow(@service).to receive(:find_server).and_return(@server)
      allow(@service).to receive(:extension_already_installed?).and_return(false)
      allow(@server).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("windows")
      allow(@bootstrap_azurerm_instance).to receive(:get_chef_extension_version).and_return("1210.*")
      allow(@bootstrap_azurerm_instance).to receive(:get_chef_extension_public_params).and_return("public_params")
      allow(@bootstrap_azurerm_instance).to receive(:get_chef_extension_private_params).and_return("private_params")
      response = @bootstrap_azurerm_instance.set_ext_params
      expect(response[:chef_extension]).to be == "ChefClient"
      expect(response[:azure_resource_group_name]).to be == "test-rgp-01"
      expect(response[:azure_vm_name]).to be == "test-vm-01"
      expect(response[:azure_service_location]).to be == "West US"
      expect(response[:chef_extension_publisher]).to be == "Chef.Bootstrap.WindowsAzure"
      expect(response[:chef_extension_version]).to be == "1210.*"
      expect(response[:chef_extension_public_param]).to be == "public_params"
      expect(response[:chef_extension_private_param]).to be == "private_params"
    end

    it "sets LinuxChefClient extension in the ext_params for linux" do
      @server = double("server")
      allow(@service).to receive(:find_server).and_return(@server)
      allow(@service).to receive(:extension_already_installed?).and_return(false)
      allow(@server).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("linux")
      allow(@server).to receive_message_chain(:storage_profile, :image_reference, :offer).and_return("ubuntu")
      allow(@bootstrap_azurerm_instance).to receive(:get_chef_extension_version).and_return("1210.*")
      allow(@bootstrap_azurerm_instance).to receive(:get_chef_extension_public_params).and_return("public_params")
      allow(@bootstrap_azurerm_instance).to receive(:get_chef_extension_private_params).and_return("private_params")
      response = @bootstrap_azurerm_instance.set_ext_params
      expect(response[:chef_extension]).to be == "LinuxChefClient"
      expect(response[:azure_resource_group_name]).to be == "test-rgp-01"
      expect(response[:azure_vm_name]).to be == "test-vm-01"
      expect(response[:azure_service_location]).to be == "West US"
      expect(response[:chef_extension_publisher]).to be == "Chef.Bootstrap.WindowsAzure"
      expect(response[:chef_extension_version]).to be == "1210.*"
      expect(response[:chef_extension_public_param]).to be == "public_params"
      expect(response[:chef_extension_private_param]).to be == "private_params"
    end

    it "raises error if an offer of OS_type linux is not supported" do
      @server = double("server")
      allow(@service).to receive(:find_server).and_return(@server)
      allow(@service).to receive(:extension_already_installed?).and_return(false)
      allow(@server).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("linux")
      allow(@server).to receive_message_chain(:storage_profile, :image_reference, :offer).and_return("abc")
      expect(@bootstrap_azurerm_instance.ui).to receive(:log).twice
      expect(@bootstrap_azurerm_instance.ui).to receive(:error)
      expect(Chef::Log).to receive(:debug).at_least(:once)
      @bootstrap_azurerm_instance.run
    end
  end

  context "when correct parameters are given" do
    it "creates VM extension with no extended log option passed" do
      @server = double("server", name: "foo", id: 1)
      vm_extension = double("vm_extension", name: "foo", id: 1)
      public_params = { extendedLogs: "false" }
      allow(@service).to receive(:find_server).and_return(@server)
      allow(@service).to receive(:extension_already_installed?).and_return(false)
      allow(@server).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("linux")
      allow(@server).to receive_message_chain(:storage_profile, :image_reference, :offer).and_return("ubuntu")
      allow(@bootstrap_azurerm_instance.ui).to receive(:log)
      allow(@bootstrap_azurerm_instance).to receive(:get_chef_extension_version).and_return("1210.*")
      allow(@bootstrap_azurerm_instance).to receive(:get_chef_extension_public_params).and_return(public_params)
      allow(@bootstrap_azurerm_instance).to receive(:get_chef_extension_private_params).and_return("private_params")
      expect(@service).to receive(:create_vm_extension).and_return(vm_extension)
      expect(@service).not_to receive(:fetch_chef_client_logs)
      @bootstrap_azurerm_instance.run
    end

    it "creates VM extension with extended log option passed" do
      @server = double("server", name: "foo", id: 1)
      vm_extension = double("vm_extension", name: "foo", id: 1)
      public_params = { extendedLogs: "true" }
      allow(@service).to receive(:find_server).and_return(@server)
      allow(@service).to receive(:extension_already_installed?).and_return(false)
      allow(@server).to receive_message_chain(:storage_profile, :os_disk, :os_type).and_return("linux")
      allow(@server).to receive_message_chain(:storage_profile, :image_reference, :offer).and_return("ubuntu")
      allow(@bootstrap_azurerm_instance.ui).to receive(:log)
      allow(@bootstrap_azurerm_instance).to receive(:get_chef_extension_version).and_return("1210.*")
      allow(@bootstrap_azurerm_instance).to receive(:get_chef_extension_public_params).and_return(public_params)
      allow(@bootstrap_azurerm_instance).to receive(:get_chef_extension_private_params).and_return("private_params")
      expect(@service).to receive(:create_vm_extension).and_return(vm_extension)
      expect(@service).to receive(:fetch_chef_client_logs).exactly(1).times
      @bootstrap_azurerm_instance.run
    end
  end

  context "find_server" do
    it "returns error if the server or resource group doesn't exist" do
      allow(@compute_client).to receive_message_chain(:virtual_machines, :get).and_return(nil)
      response = @service.find_server("test-vm-01", "test-rgp-01")
      expect(response).to be(nil)
    end
  end

  context "extension_already_installed?" do
    it "returns true if the VM has ChefClient extension installed" do
      extension = double(virtual_machine_extension_type: "ChefClient")
      @server = double("server", resources: [extension])
      extension_installed = @service.extension_already_installed?(@server)
      expect(extension_installed).to be(true)
    end

    it "returns true if the VM has LinuxChefClient extension installed" do
      extension = double(virtual_machine_extension_type: "LinuxChefClient")
      @server = double("server", resources: [extension])
      extension_installed = @service.extension_already_installed?(@server)
      expect(extension_installed).to be(true)
    end

    it "returns false if the VM doesn't have chef extension installed" do
      extension = double(virtual_machine_extension_type: "some_type")
      @server = double("server", resources: [extension])
      extension_installed = @service.extension_already_installed?(@server)
      expect(extension_installed).to be(false)
    end
  end

  describe "get_chef_extension_version" do
    before do
      allow(@service).to receive(:instance_of?).with(
        Azure::ResourceManagement::ARMInterface
      ).and_return(true)
    end

    context "when extension version is set in knife.rb" do
      before do
        @bootstrap_azurerm_instance.config[:azure_chef_extension_version] = "1312.11"
      end

      it "will pick up the extension version from knife.rb" do
        response = @bootstrap_azurerm_instance.get_chef_extension_version("MyChefClient")
        expect(response).to be == "1312.11"
      end
    end

    context "when extension version is not set in knife.rb" do
      before do
        @bootstrap_azurerm_instance.config.delete(:azure_chef_extension_version)
        allow(@service).to receive(
          :get_latest_chef_extension_version
        ).and_return("1213.14")
      end

      it "will pick up the latest version of the extension" do
        expect(@service).to_not receive(:get_extension)
        response = @bootstrap_azurerm_instance.get_chef_extension_version("MyChefClient")
        expect(response).to be == "1213.14"
      end
    end
  end

  describe "get_chef_extension_public_params" do
    context "service is an instance_of ARM" do
      before do
        allow(@service).to receive(:instance_of?).and_return(true)
      end

      it "does not set hints in extension's public config parameters" do
        response = @bootstrap_azurerm_instance.get_chef_extension_public_params
        expect(response.key?(:hints)).to be == false
      end
    end

    context "service is not an instance_of ARM" do
      before do
        allow(@service).to receive(:instance_of?).and_return(false)
      end

      it "does not set hints in extension's public config parameters" do
        response = @bootstrap_azurerm_instance.get_chef_extension_public_params
        expect(response.key?(:hints)).to be == false
      end
    end

    context "when a license key is available" do
      it "succeeds and sets bootstrap_version for chef-ice (major >= 19)" do
        @bootstrap_azurerm_instance.config[:bootstrap_version] = "19"
        @bootstrap_azurerm_instance.config[:chef_license_key] = "my-license-key"
        response = @bootstrap_azurerm_instance.get_chef_extension_public_params
        expect(response[:bootstrap_options][:bootstrap_version]).to eq("19")
      end

      it "succeeds and sets bootstrap_version for the legacy chef product (major < 19)" do
        @bootstrap_azurerm_instance.config[:bootstrap_version] = "18"
        @bootstrap_azurerm_instance.config[:chef_license_key] = "my-license-key"
        response = @bootstrap_azurerm_instance.get_chef_extension_public_params
        expect(response[:bootstrap_options][:bootstrap_version]).to eq("18")
      end
    end

    context "when no license key is available" do
      # A license key is not mandated here: Chef::Knife::Bootstrap#fetch_license
      # (called before any plugin_* hook runs) is responsible for license
      # enforcement for the knife CLI as a whole. get_chef_extension_public_params
      # simply sets bootstrap_version regardless of license availability;
      # get_chef_extension_private_params decides separately whether to
      # forward a license key to the extension (see that method/spec).
      before do
        @bootstrap_azurerm_instance.config[:chef_license_key] = nil
        @bootstrap_azurerm_instance.config[:license_id] = nil
      end

      it "succeeds and sets bootstrap_version for chef-ice (major >= 19)" do
        @bootstrap_azurerm_instance.config[:bootstrap_version] = "19"
        response = @bootstrap_azurerm_instance.get_chef_extension_public_params
        expect(response[:bootstrap_options][:bootstrap_version]).to eq("19")
      end

      it "succeeds and sets bootstrap_version for the legacy chef product (major < 19)" do
        @bootstrap_azurerm_instance.config[:bootstrap_version] = "18"
        response = @bootstrap_azurerm_instance.get_chef_extension_public_params
        expect(response[:bootstrap_options][:bootstrap_version]).to eq("18")
      end
    end
  end

  describe "get_chef_extension_private_params" do
    before do
      allow(@bootstrap_azurerm_instance).to receive(:create_node_and_client_pem).and_return("/tmp/client.pem")
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/tmp/client.pem").and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with("/tmp/client.pem").and_return("client-pem-content")
      allow(@bootstrap_azurerm_instance).to receive(:load_correct_secret).and_return(nil)
      # create_arm_instance defaults config[:chef_license_key] so unrelated
      # specs don't need to set it explicitly; clear it here so these
      # license-specific contexts can control it precisely.
      @bootstrap_azurerm_instance.config[:chef_license_key] = nil
    end

    context "when --chef-license-key is provided" do
      before do
        @bootstrap_azurerm_instance.config[:chef_license_key] = "my-license-key"
      end

      it "forwards chef_license_key into the extension's protected config parameters" do
        response = @bootstrap_azurerm_instance.get_chef_extension_private_params
        expect(response[:chef_license_key]).to eq("my-license-key")
      end
    end

    context "when --chef-license-key is not provided but a license was already fetched/persisted" do
      before do
        # Chef::Knife::Bootstrap#run calls fetch_license before any plugin_*
        # hook runs, populating config[:license_id] with the locally
        # persisted/validated license key.
        @bootstrap_azurerm_instance.config[:license_id] = "persisted-license-key"
      end

      it "auto-forwards the persisted license into the extension's protected config parameters" do
        response = @bootstrap_azurerm_instance.get_chef_extension_private_params
        expect(response[:chef_license_key]).to eq("persisted-license-key")
      end
    end

    context "when --disable-license-activation is set" do
      before do
        @bootstrap_azurerm_instance.config[:disable_license_activation] = true
      end

      it "does not forward an explicitly provided --chef-license-key" do
        @bootstrap_azurerm_instance.config[:chef_license_key] = "my-license-key"
        response = @bootstrap_azurerm_instance.get_chef_extension_private_params
        expect(response.key?(:chef_license_key)).to be == false
      end

      it "does not forward a persisted license" do
        @bootstrap_azurerm_instance.config[:license_id] = "persisted-license-key"
        response = @bootstrap_azurerm_instance.get_chef_extension_private_params
        expect(response.key?(:chef_license_key)).to be == false
      end
    end

    context "when --chef-license-key is provided and a persisted license also exists" do
      before do
        @bootstrap_azurerm_instance.config[:chef_license_key] = "my-license-key"
        @bootstrap_azurerm_instance.config[:license_id] = "persisted-license-key"
      end

      it "prefers the explicitly provided --chef-license-key" do
        response = @bootstrap_azurerm_instance.get_chef_extension_private_params
        expect(response[:chef_license_key]).to eq("my-license-key")
      end
    end

    context "when neither --chef-license-key nor a persisted license is available" do
      it "does not set chef_license_key in extension's protected config parameters" do
        response = @bootstrap_azurerm_instance.get_chef_extension_private_params
        expect(response.key?(:chef_license_key)).to be == false
      end
    end

    context "when --azure-chef-extension-version pins a build older than protectedSettings support" do
      before do
        @bootstrap_azurerm_instance.config[:chef_license_key] = "my-license-key"
        @bootstrap_azurerm_instance.config[:azure_chef_extension_version] = "1210.15.11.0"
      end

      it "fails fast instead of silently forwarding an unusable license key" do
        expect(@bootstrap_azurerm_instance.ui).to receive(:error)
          .with(/older than 1210.15.11.1/)
        expect { @bootstrap_azurerm_instance.get_chef_extension_private_params }.to raise_error(SystemExit)
      end
    end

    context "when --azure-chef-extension-version pins a build at the minimum supported version" do
      before do
        @bootstrap_azurerm_instance.config[:chef_license_key] = "my-license-key"
        @bootstrap_azurerm_instance.config[:azure_chef_extension_version] = "1210.15.11.1"
      end

      it "forwards chef_license_key normally" do
        response = @bootstrap_azurerm_instance.get_chef_extension_private_params
        expect(response[:chef_license_key]).to eq("my-license-key")
      end
    end

    context "when --azure-chef-extension-version pins a build newer than the minimum supported version" do
      before do
        @bootstrap_azurerm_instance.config[:chef_license_key] = "my-license-key"
        @bootstrap_azurerm_instance.config[:azure_chef_extension_version] = "1312.11"
      end

      it "forwards chef_license_key normally" do
        response = @bootstrap_azurerm_instance.get_chef_extension_private_params
        expect(response[:chef_license_key]).to eq("my-license-key")
      end
    end

    context "when --azure-chef-extension-version is a family wildcard" do
      before do
        @bootstrap_azurerm_instance.config[:chef_license_key] = "my-license-key"
        @bootstrap_azurerm_instance.config[:azure_chef_extension_version] = "1210.*"
      end

      it "forwards chef_license_key without rejecting the ambiguous pin" do
        response = @bootstrap_azurerm_instance.get_chef_extension_private_params
        expect(response[:chef_license_key]).to eq("my-license-key")
      end
    end

    context "when an old pinned --azure-chef-extension-version is set but --disable-license-activation suppresses forwarding" do
      before do
        @bootstrap_azurerm_instance.config[:chef_license_key] = "my-license-key"
        @bootstrap_azurerm_instance.config[:azure_chef_extension_version] = "1210.15.11.0"
        @bootstrap_azurerm_instance.config[:disable_license_activation] = true
      end

      it "does not reject the pin, since no license key is forwarded anyway" do
        expect(@bootstrap_azurerm_instance.ui).to_not receive(:error)
        response = @bootstrap_azurerm_instance.get_chef_extension_private_params
        expect(response.key?(:chef_license_key)).to be == false
      end
    end
  end
end
