#
# Author:: Aliasgar Batterywala (<aliasgar.batterywala@clogeny.com>)
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
require "chef/knife/bootstrap"

describe Chef::Knife::AzurermServerCreate do
  include AzureSpecHelper
  include QueryAzureMock
  include AzureUtility

  before do
    @arm_server_instance = create_arm_instance(Chef::Knife::AzurermServerCreate)
    @service = @arm_server_instance.service

    @params = {
      azure_resource_group_name: Chef::Config[:knife][:azure_resource_group_name],
      azure_service_location: Chef::Config[:knife][:azure_service_location],
      azure_vm_name: Chef::Config[:knife][:azure_vm_name],
      connection_user: Chef::Config[:knife][:connection_user],
      connection_password: "connection_password",
      azure_vm_size: "small",
      azure_storage_account: "azurestorageaccount",
      azure_storage_account_type: "azure_storage_account_type",
      azure_os_disk_name: "azureosdiskname",
      azure_os_disk_caching: "azure_os_disk_caching",
      azure_os_disk_create_option: "azure_os_disk_create_option",
      azure_vnet_name: "azure_virtual_network_name",
      azure_vnet_subnet_name: "azure_subnet_name",
      rdp_port: "3389",
      connection_port: "22",
      chef_extension_publisher: "chef_extension_publisher",
      chef_extension: "chef_extension",
      chef_extension_version: "11.10.1",
      chef_extension_private_param: { validation_key: "37284723sdjfhsdkfsfd" },
      latest_chef_extension_version: "1210.12",
      chef_extension_public_param: {
        hints: %w{vm_name public_fqdn platform},
        bootstrap_options: { bootstrap_version: "12.8.1" },
      },
      vnet_config: {
        virtualNetworkName: "vnet1",
        addressPrefixes: ["10.0.0.0/16"],
        subnets: [{ "name" => "sbn1",
                    "properties" => {
                      "addressPrefix" => "10.0.0.0/24",
                    } }],
      },
    }

    allow(@service.ui).to receive(:log)
    allow(Chef::Log).to receive(:info)
    allow(File).to receive(:read).and_return("foo")
    allow(@arm_server_instance).to receive(:check_license)
    stub_client_builder
    allow_any_instance_of(Chef::Knife::AzurermBase).to receive(:get_azure_cli_version).and_return("1.0.0")
  end

  describe "parameter test:" do
    context "compulsory parameters" do
      it "connection_user" do
        Chef::Config[:knife].delete(:connection_user)
        expect(@arm_server_instance.ui).to receive(:error)
        expect { @arm_server_instance.run }.to raise_error(SystemExit)
      end

      it "connection_password" do
        Chef::Config[:knife].delete(:connection_password)
        expect(@arm_server_instance.ui).to receive(:error)
        expect { @arm_server_instance.run }.to raise_error(SystemExit)
      end

      it "ssh_public_key" do
        Chef::Config[:knife].delete(:ssh_public_key)
        expect(@arm_server_instance.ui).to receive(:error)
        expect { @arm_server_instance.run }.to raise_error(SystemExit)
      end

      it "azure_subscription_id" do
        Chef::Config[:knife].delete(:azure_subscription_id)
        expect(@arm_server_instance.ui).to receive(:error).twice
        expect { @arm_server_instance.run }.to raise_error(SystemExit)
      end

      it "azure_resource_group_name" do
        Chef::Config[:knife].delete(:azure_resource_group_name)
        expect(@arm_server_instance.ui).to receive(:error)
        expect { @arm_server_instance.run }.to raise_error(SystemExit)
      end

      it "azure_vm_name" do
        Chef::Config[:knife].delete(:azure_vm_name)
        expect(@arm_server_instance.ui).to receive(:error)
        expect { @arm_server_instance.run }.to raise_error(SystemExit)
      end

      it "vm name validation success for Linux" do
        Chef::Config[:knife][:azure_vm_name] = "test-vm1234"
        Chef::Config[:knife][:ssh_public_key] = "ssh_public_key"
        allow(@arm_server_instance).to receive(:is_image_windows?).and_return(false)
        expect { @arm_server_instance.validate_params! }.not_to raise_error
      end

      it "vm name validation success for Windows" do
        Chef::Config[:knife][:azure_vm_name] = "test-vm1234"
        Chef::Config[:knife][:connection_password] = "connection_password"
        allow(@arm_server_instance).to receive(:is_image_windows?).and_return(true)
        expect { @arm_server_instance.validate_params! }.not_to raise_error
      end

      it "vm name validation failure for name containing special characters for Linux" do
        Chef::Config[:knife][:azure_vm_name] = "test_vm1234!@#"
        allow(@arm_server_instance).to receive(:is_image_windows?).and_return(false)
        expect { @arm_server_instance.validate_params! }.to raise_error(ArgumentError)
      end

      it "vm name validation failure for name containing special characters for Windows" do
        Chef::Config[:knife][:azure_vm_name] = "test_vm1234!@#"
        allow(@arm_server_instance).to receive(:is_image_windows?).and_return(true)
        expect { @arm_server_instance.validate_params! }.to raise_error(ArgumentError)
      end

      it "vm name validation failure for name containing more than 15 characters for Windows" do
        Chef::Config[:knife][:azure_vm_name] = "testvm123123123123"
        allow(@arm_server_instance).to receive(:is_image_windows?).and_return(true)
        expect { @arm_server_instance.validate_params! }.to raise_error(ArgumentError)
      end

      it "vm name validation failure for name containing more than 64 characters for Linux" do
        Chef::Config[:knife][:azure_vm_name] = "testvm123123123123123123123123123123123123123123123123123123123123123123123123123123123123123"
        allow(@arm_server_instance).to receive(:is_image_windows?).and_return(false)
        expect { @arm_server_instance.validate_params! }.to raise_error(ArgumentError)
      end

      it "azure_service_location" do
        Chef::Config[:knife].delete(:azure_service_location)
        expect(@arm_server_instance.ui).to receive(:error)
        expect { @arm_server_instance.run }.to raise_error(SystemExit)
      end

      it "azure_image_reference_publisher" do
        Chef::Config[:knife].delete(:azure_image_reference_publisher)
        expect(@arm_server_instance.ui).to receive(:error)
        expect { @arm_server_instance.run }.to raise_error(SystemExit)
      end

      it "azure_image_reference_offer" do
        Chef::Config[:knife].delete(:azure_image_reference_offer)
        expect(@arm_server_instance.ui).to receive(:error)
        expect { @arm_server_instance.run }.to raise_error(SystemExit)
      end

      it "azure_image_reference_sku" do
        Chef::Config[:knife].delete(:azure_image_reference_sku)
        expect(@arm_server_instance.ui).to receive(:error)
        expect { @arm_server_instance.run }.to raise_error(SystemExit)
      end

      it "winrm user and password error if not provided for windows image" do
        Chef::Config[:knife].delete(:connection_user)
        Chef::Config[:knife].delete(:connection_password)
        allow(@arm_server_instance).to receive(:is_image_windows?).and_return(true)
        expect { @arm_server_instance.validate_params! }.to raise_error(ArgumentError)
      end

      it "exits when incorrect Ohai Hints are given by the user" do
        @arm_server_instance.config[:ohai_hints] = "vm_name,mac_address"
        expect(@arm_server_instance.ui).to receive(:error)
        expect { @arm_server_instance.run }.to raise_error(SystemExit)
      end
    end

    context "optional parameters" do
      context "when not given by user" do
        before do
          @vm_name_with_no_special_chars = "testvm"
          Chef::Config[:knife][:connection_password] = "connection_password"
          @azure_vm_size_default_value = "Small"
          @xplat_creds_cmd = double(run_command: double)
          @result = double(stdout: "")
          allow(Mixlib::ShellOut).to receive(:new).and_return(@xplat_creds_cmd)
          allow(@xplat_creds_cmd).to receive(:run_command).and_return(@result)
          allow(@result).to receive(:stdout).and_return("")
          @arm_server_instance.instance_variable_set(:@azure_prefix, "azure")
          allow(File).to receive(:exist?).and_return(true)
        end

        it "azure_tenant_id not provided for Linux platform" do
          allow(Chef::Platform).to receive(:windows?).and_return(false)
          Chef::Config[:knife].delete(:azure_tenant_id)
          allow(File).to receive(:exist?).and_return(false)
          expect { @arm_server_instance.run }.to raise_error(SystemExit)
        end

        it "azure_client_id not provided for Linux platform" do
          allow(Chef::Platform).to receive(:windows?).and_return(false)
          Chef::Config[:knife].delete(:azure_client_id)
          allow(File).to receive(:exist?).and_return(false)
          expect { @arm_server_instance.run }.to raise_error(SystemExit)
        end

        it "azure_client_secret not provided for Linux platform" do
          allow(Chef::Platform).to receive(:windows?).and_return(false)
          Chef::Config[:knife].delete(:azure_client_secret)
          allow(File).to receive(:exist?).and_return(false)
          expect { @arm_server_instance.run }.to raise_error(SystemExit)
        end

        it "azure_tenant_id not provided for Windows platform" do
          allow(Chef::Platform).to receive(:windows?).and_return(true)
          Chef::Config[:knife].delete(:azure_tenant_id)
          allow(File).to receive(:exist?).and_return(false)
          expect { @arm_server_instance.run }.to raise_error(SystemExit)
        end

        it "azure_client_id not provided for Windows platform" do
          allow(Chef::Platform).to receive(:windows?).and_return(true)
          Chef::Config[:knife].delete(:azure_client_id)
          allow(File).to receive(:exist?).and_return(false)
          expect { @arm_server_instance.run }.to raise_error(SystemExit)
        end

        it "azure_client_secret not provided for windows platform" do
          allow(Chef::Platform).to receive(:windows?).and_return(true)
          Chef::Config[:knife].delete(:azure_client_secret)
          allow(File).to receive(:exist?).and_return(false)
          expect { @arm_server_instance.run }.to raise_error(SystemExit)
        end

        it "azure_storage_account not provided by user so vm_name gets assigned to it" do
          Chef::Config[:knife].delete(:azure_storage_account)
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_storage_account]).to be == @vm_name_with_no_special_chars
        end

        it "azure_os_disk_name not provided by user so vm_name gets assigned to it" do
          Chef::Config[:knife].delete(:azure_os_disk_name)
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_os_disk_name]).to be == @vm_name_with_no_special_chars
        end

        it "azure_vnet_name not provided by user so vm_name gets assigned to it" do
          Chef::Config[:knife].delete(:azure_vnet_name)
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_vnet_name]).to be == "test-vm"
        end

        it "azure_vnet_subnet_name not provided by user so vm_name gets assigned to it" do
          Chef::Config[:knife].delete(:azure_vnet_subnet_name)
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_vnet_subnet_name]).to be == "test-vm"
        end

        it "should assign default value 1 to the server_count when not provided by the user" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:server_count]).to be == 1
        end

        after do
          Chef::Config[:knife].delete(:connection_password)
        end
      end

      shared_context "and other common parameters" do
        before do
          @vm_name_with_no_special_chars = "testvm"
          Chef::Config[:knife][:azure_storage_account] = "azure_storage_account"
          @storage_account_name_with_no_special_chars = "azurestorageaccount"
          Chef::Config[:knife][:azure_os_disk_name] = "azure_os_disk_name"
          @os_disk_name_with_no_special_chars = "azureosdiskname"
          Chef::Config[:knife][:azure_vnet_name] = "azure_vnet_name"
          Chef::Config[:knife][:azure_vnet_subnet_name] = "azure_vnet_subnet_name"
          Chef::Config[:knife][:azure_vm_size] = "Medium"
          Chef::Config[:knife][:server_count] = 3
          allow(File).to receive(:exist?).and_return(true)
        end

        it "azure_storage_account provided by user so vm_name does not get assigned to it" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_storage_account]).to be == @storage_account_name_with_no_special_chars
        end

        it "azure_os_disk_name provided by user so vm_name does not get assigned to it" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_os_disk_name]).to be == @os_disk_name_with_no_special_chars
        end

        it "azure_vnet_name provided by user so vm_name does not get assigned to it" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_vnet_name]).to be == "azure_vnet_name"
        end

        it "azure_vnet_subnet_name provided by user so vm_name does not get assigned to it" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_vnet_subnet_name]).to be == "azure_vnet_subnet_name"
        end

        context "azure_vnet_name provided by user but azure_vnet_subnet_name not provided by user" do
          before do
            Chef::Config[:knife].delete(:azure_vnet_subnet_name)
          end

          it "assigns vm_name to the azure_vnet_subnet_name" do
            @server_params = @arm_server_instance.create_server_def
            expect(@server_params[:azure_vnet_subnet_name]).to be == "test-vm"
          end
        end

        context "azure_vnet_subnet_name provided by user but azure_vnet_name not provided by user" do
          before do
            Chef::Config[:knife].delete(:azure_vnet_name)
          end

          it "raises error" do
            expect { @arm_server_instance.validate_params! }.to raise_error(
              ArgumentError, "When --azure-vnet-subnet-name is specified, the --azure-vnet-name must also be specified."
            )
          end
        end

        context "raise node_ssl_verify_mode error for wrong value" do
          before do
            Chef::Config[:knife][:node_ssl_verify_mode] = "MyValue"
          end

          it "raises error" do
            expect { @arm_server_instance.validate_params! }.to raise_error(
              ArgumentError, "Invalid value '#{Chef::Config[:knife][:node_ssl_verify_mode]}' for --node-ssl-verify-mode. Use Valid values i.e 'none', 'peer'."
            )
          end
        end

        context "GatewaySubnet name provided by user as the name for azure_vnet_subnet_name option" do
          it "raises error" do
            Chef::Config[:knife][:azure_vnet_name] = "MyVnet"
            Chef::Config[:knife][:azure_vnet_subnet_name] = "GatewaySubnet"
            expect { @arm_server_instance.validate_params! }.to raise_error(
              ArgumentError, "GatewaySubnet cannot be used as the name for --azure-vnet-subnet-name option. GatewaySubnet can only be used for virtual network gateways."
            )
          end
        end

        it "azure_vm_size provided by user so default value does not get assigned to it" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:azure_vm_size]).to be == "Medium"
        end

        it "should set the value of server_count as provided by the user" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:server_count]).to be == 3
        end

        after do
          Chef::Config[:knife].delete(:connection_password)
          Chef::Config[:knife].delete(:ssh_public_key)
          Chef::Config[:knife].delete(:azure_storage_account)
          Chef::Config[:knife].delete(:azure_os_disk_name)
          Chef::Config[:knife].delete(:azure_vnet_name)
          Chef::Config[:knife].delete(:azure_vnet_subnet_name)
          Chef::Config[:knife].delete(:azure_vm_size)
          Chef::Config[:knife].delete(:server_count)
        end
      end

      context "when given by user" do
        context "for windows nodes with --connection-password" do
          before do
            Chef::Config[:knife][:connection_password] = "connection_password"
            # @arm_server_instance.config[:azure_image_os_type] = "windows"
            allow(@arm_server_instance).to receive(:is_image_windows?).and_return(true)
          end

          include_context "and other common parameters"

          it "does not disable the passwod authentication" do
            @server_params = @arm_server_instance.create_server_def
            allow(File).to receive(:read).and_call_original
            expect(@server_params[:chef_extension_private_param][:validation_key]).to be == "foo"
            expect(@server_params[:disablePasswordAuthentication]).to be == "false"
          end

          it "raises error if invalid daemon value is provided" do
            Chef::Config[:knife][:daemon] = "foo"
            expect { @arm_server_instance.validate_params! }.to raise_error(
              ArgumentError, "Invalid value for --daemon option. Use valid daemon values i.e 'none', 'service' and 'task'."
            )
          end

          %w{service task none}.each do |daemon|
            it "does not raises error if valid daemon option is provided" do
              Chef::Config[:knife][:daemon] = daemon
              expect { @arm_server_instance.validate_params! }.not_to raise_error(
                ArgumentError, "The daemon option is only support for Windows nodes."
              )
              expect { @arm_server_instance.validate_params! }.not_to raise_error(
                ArgumentError, "Invalid value for --daemon option. Use valid daemon values i.e 'none', 'service' and 'task'."
              )
            end
          end
        end

        context "for other than windows nodes with --ssh-public-key" do
          before do
            Chef::Config[:knife][:ssh_public_key] = File.dirname(__FILE__) + "/assets/key_rsa.pub"
            # @arm_server_instance.config[:azure_image_os_type] = "ubuntu"
            allow(@arm_server_instance).to receive(:is_image_windows?).and_return(false)
          end

          include_context "and other common parameters"

          it "disable the passwod authentication" do
            @server_params = @arm_server_instance.create_server_def
            allow(File).to receive(:read).and_call_original
            expect(@server_params[:chef_extension_private_param][:validation_key]).to be == "foo"
            expect(@server_params[:disablePasswordAuthentication]).to be == "true"
          end

          it "raises error if daemon option is provided" do
            Chef::Config[:knife][:daemon] = "service"
            expect { @arm_server_instance.validate_params! }.to raise_error(
              ArgumentError, "The daemon option is only support for Windows nodes."
            )
          end
        end
      end
    end
  end

  describe "server create" do
    before do
      Chef::Config[:knife][:connection_password] = "connection_password"
      Chef::Config[:knife][:connection_password] = "connection_password"

      @resource_client = double("ResourceManagementClient")
      @compute_client = double("ComputeManagementClient")
      @storage_client = double("StorageManagementClient")
      @network_client = double("NetworkResourceClient")

      @resource_promise = double("ResourcePromise")
      @compute_promise = double("ComputePromise")

      allow(@service).to receive(
        :resource_management_client
      ).and_return(
        @resource_client
      )
      allow(@service).to receive(
        :compute_management_client
      ).and_return(
        @compute_client
      )
      allow(@service).to receive(
        :storage_management_client
      ).and_return(
        @storage_client
      )
      allow(@service).to receive(
        :network_resource_client
      ).and_return(
        @network_client
      )
      allow(@arm_server_instance).to receive(
        :msg_server_summary
      )
      allow(@arm_server_instance).to receive(
        :set_default_image_reference!
      )
    end

    describe "security_group_exist" do
      module Azure
        module ARM
          class DummyClass < Azure::ResourceManagement::ARMInterface
          end
        end
      end

      before do
        @dummy_class = Azure::ARM::DummyClass.new
      end

      context "given security group exist under the given resource group" do
        before do
          @resource_group_name = "rgrp-2"
          @vnet_name = "vnet-2"
          @sec_grp_name = "sec_grp_2"
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            stub_network_resource_client(nil, @resource_group_name, @vnet_name, @sec_grp_name)
          )
        end

        it "returns true" do
          response = @dummy_class.security_group_exist?(@resource_group_name, @sec_grp_name)
          expect(response).to be == true
        end
      end

      context "given security group does not exist under the given resource group" do
        before do
          @resource_group_name = "rgrp-2"
          @sec_grp_name = "sec_grp_2"
          request = {}
          response = OpenStruct.new(
            "body" => '{"error": {"code": "ResourceNotFound"}}'
          )
          body = "MsRestAzure::AzureOperationError"
          error = MsRestAzure::AzureOperationError.new(request, response, body)
          network_resource_client = double("NetworkResourceClient",
            network_security_groups: double)
          allow(network_resource_client.network_security_groups).to receive(
            :get
          ).and_raise(error)
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            network_resource_client
          )
        end

        it "returns false" do
          response = @dummy_class.security_group_exist?(@resource_group_name, @sec_grp_name)
          expect(response).to be == false
        end
      end

      context "security group get api call raises some unknown exception" do
        before do
          @resource_group_name = "rgrp-2"
          @sec_grp_name = "sec_grp_2"
          request = {}
          response = OpenStruct.new(
            "body" => '{"error": {"code": "SomeProblemOccurred"}}'
          )
          body = "MsRestAzure::AzureOperationError"
          @error = MsRestAzure::AzureOperationError.new(request, response, body)
          network_resource_client = double("NetworkResourceClient",
            network_security_groups: double)
          allow(network_resource_client.network_security_groups).to receive(
            :get
          ).and_raise(@error)
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            network_resource_client
          )
        end

        it "raises error" do
          expect do
            @dummy_class.security_group_exist?(@resource_group_name, @sec_grp_name)
          end.to raise_error(@error)
        end
      end
    end

    describe "resource group" do
      before do
        allow(@service).to receive(:security_group_exist?).and_return(true)
        allow(@service).to receive(:virtual_machine_exist?).and_return(true)
      end

      it "create resource group when it does not exist already" do
        expect(@resource_client).to receive_message_chain(
          :resource_groups, :check_existence
        ).and_return(false)
        expect(@service).to receive(
          :create_resource_group
        ).exactly(1).and_return(
          stub_resource_group_create_response
        )
        @arm_server_instance.run
      end

      it "skip resource group creation when it does exist already" do
        expect(@resource_client).to receive_message_chain(
          :resource_groups, :check_existence
        ).and_return(true)
        expect(@service).to_not receive(:create_resource_group)
        @arm_server_instance.run
      end
    end

    describe "virtual machine" do
      context "for Linux" do
        before do
          {
            azure_image_reference_publisher: "OpenLogic",
            azure_image_reference_offer: "CentOS",
            azure_image_reference_sku: "6.5",
            azure_image_reference_version: "latest",
            connection_user: "connection_user",
            azure_chef_extension_version: "1210.12",
          }.each do |key, value|
            Chef::Config[:knife][key] = value
          end

          expect(@arm_server_instance).to receive(
            :is_image_windows?
          ).at_least(:twice).and_return(false)

          allow(@resource_client).to receive_message_chain(
            :resource_groups, :check_existence
          ).and_return(false)
          allow(@service).to receive(
            :create_resource_group
          ).and_return(
            stub_resource_group_create_response
          )
        end

        it "create virtual machine when it does not exist already and does not show chef-client run logs when extended_logs is false" do
          allow(@service).to receive(:security_group_exist?).and_return(true)
          expect(@service).to receive(:virtual_machine_exist?).and_return(false)
          expect(@service).to receive(:create_vnet_config)
          expect(@service).to receive(:create_virtual_machine_using_template).exactly(1).and_return(stub_deployments_create_response)
          expect(@service).to_not receive(:print)
          expect(@service).to_not receive(:fetch_chef_client_logs)
          expect(@service.ui).to receive(:log).exactly(9).times
          expect(@service).to receive(:show_server).with("MyVM", "test-rgrp")
          @arm_server_instance.run
        end

        it "create virtual machine when it does not exist already and also shows chef-client run logs when extended_logs is true" do
          @arm_server_instance.config[:extended_logs] = true
          allow(@service).to receive(:security_group_exist?).and_return(true)
          expect(@service).to receive(:virtual_machine_exist?).and_return(false)
          expect(@service).to receive(:create_vnet_config)
          expect(@service).to receive(:create_virtual_machine_using_template).exactly(1).and_return(stub_deployments_create_response)
          expect(@service).to receive(:print).exactly(1).times
          expect(@service).to receive(:fetch_chef_client_logs).exactly(1).times
          expect(@service.ui).to receive(:log).exactly(9).times
          expect(@service).to receive(:show_server).with("MyVM", "test-rgrp")
          @arm_server_instance.run
        end

        it "skip virtual machine creation when it does exist already" do
          expect(@service).to receive(:virtual_machine_exist?).and_return(true)
          expect(@service).to_not receive(:create_vnet_config)
          expect(@service).to_not receive(:security_group_exist?)
          expect(@service).to_not receive(:create_virtual_machine_using_template)
          expect(@service).to_not receive(:show_server)
          @arm_server_instance.run
        end
      end

      context "for Windows" do
        before do
          {
            azure_image_reference_publisher: "MicrosoftWindowsServer",
            azure_image_reference_offer: "WindowsServer",
            azure_image_reference_sku: "2012-R2-Datacenter",
            azure_image_reference_version: "latest",
            connection_user: "connection_user",
          }.each do |key, value|
            Chef::Config[:knife][key] = value
          end

          expect(@arm_server_instance).to receive(
            :is_image_windows?
          ).at_least(:twice).and_return(true)

          allow(@resource_client).to receive_message_chain(
            :resource_groups, :check_existence
          ).and_return(false)
          allow(@service).to receive(
            :create_resource_group
          ).and_return(
            stub_resource_group_create_response
          )
        end

        it "skip virtual machine creation when it does exist already" do
          expect(@service).to receive(:virtual_machine_exist?).and_return(true)
          expect(@service).to_not receive(:create_vnet_config)
          expect(@service).to_not receive(:security_group_exist?)
          expect(@service).to_not receive(:create_virtual_machine_using_template)
          expect(@service).to_not receive(:show_server)
          @arm_server_instance.run
        end
      end

      context "for multiple VM creation" do
        before do
          Chef::Config[:knife][:server_count] = 3
          Chef::Config[:knife][:azure_chef_extension_version] = "1210.12"

          expect(@arm_server_instance).to receive(
            :is_image_windows?
          ).at_least(:twice).and_return(false)

          allow(@resource_client).to receive_message_chain(
            :resource_groups, :check_existence
          ).and_return(false)
          allow(@service).to receive(
            :create_resource_group
          ).and_return(
            stub_resource_group_create_response
          )

          allow(@service).to receive(:security_group_exist?).and_return(false)
          allow(@service).to receive(:virtual_machine_exist?).and_return(false)
        end

        it "uses template for VM creation and does not show chef-client run logs to user when extended_logs is false" do
          deployment = double("deployment", name: "name", id: "id", properties: double)
          @deploy1 = double("deploy1", resource_type: "Microsoft.Compute/virtualMachines", resource_name: "MyVM0", id: "/subscriptions/e00d2b3f-3b94-4dfc-ae8e-ca34c8ba1a99/resourceGroups/vjgroup/providers/Microsoft.Compute/virtualMachines/MyVM0")
          @deploy2 = double("deploy2", resource_type: "Microsoft.Compute/virtualMachines", resource_name: "MyVM1", id: "/subscriptions/e00d2b3f-3b94-4dfc-ae8e-ca34c8ba1a99/resourceGroups/vjgroup/providers/Microsoft.Compute/virtualMachines/MyVM1")
          @deploy3 = double("deploy3", resource_type: "Microsoft.Compute/virtualMachines", resource_name: "MyVM2", id: "/subscriptions/e00d2b3f-3b94-4dfc-ae8e-ca34c8ba1a99/resourceGroups/vjgroup/providers/Microsoft.Compute/virtualMachines/MyVM2")
          allow(deployment.properties).to receive(:dependencies).and_return([@deploy1, @deploy2, @deploy3])
          allow(@service.ui).to receive(:log).at_least(:once)
          expect(@service).to receive(:create_vnet_config)
          expect(@service).to receive(:create_virtual_machine_using_template).and_return(deployment)
          expect(@service).to_not receive(:print)
          expect(@service).to_not receive(:fetch_chef_client_logs)
          expect(@service.ui).to receive(:log).exactly(17).times
          expect(@service).to receive(:show_server).thrice
          expect(@service).not_to receive(:create_vm_extension)
          expect(@service).not_to receive(:vm_details)
          @arm_server_instance.run
        end

        it "uses template for VM creation and also shows chef-client run logs to user when extended_logs is true" do
          @arm_server_instance.config[:extended_logs] = true
          deployment = double("deployment", name: "name", id: "id", properties: double)
          @deploy1 = double("deploy1", resource_type: "Microsoft.Compute/virtualMachines", resource_name: "MyVM0", id: "/subscriptions/e00d2b3f-3b94-4dfc-ae8e-ca34c8ba1a99/resourceGroups/vjgroup/providers/Microsoft.Compute/virtualMachines/MyVM0")
          @deploy2 = double("deploy2", resource_type: "Microsoft.Compute/virtualMachines", resource_name: "MyVM1", id: "/subscriptions/e00d2b3f-3b94-4dfc-ae8e-ca34c8ba1a99/resourceGroups/vjgroup/providers/Microsoft.Compute/virtualMachines/MyVM1")
          @deploy3 = double("deploy3", resource_type: "Microsoft.Compute/virtualMachines", resource_name: "MyVM2", id: "/subscriptions/e00d2b3f-3b94-4dfc-ae8e-ca34c8ba1a99/resourceGroups/vjgroup/providers/Microsoft.Compute/virtualMachines/MyVM2")
          allow(deployment.properties).to receive(:dependencies).and_return([@deploy1, @deploy2, @deploy3])
          allow(@service.ui).to receive(:log).at_least(:once)
          expect(@service).to receive(:create_vnet_config)
          expect(@service).to receive(:create_virtual_machine_using_template).and_return(deployment)
          expect(@service).to receive(:print).exactly(3).times
          expect(@service).to receive(:fetch_chef_client_logs).exactly(3).times
          expect(@service.ui).to receive(:log).exactly(17).times
          expect(@service).to receive(:show_server).thrice
          expect(@service).not_to receive(:create_vm_extension)
          expect(@service).not_to receive(:vm_details)
          @arm_server_instance.run
        end

        after do
          Chef::Config[:knife].delete(:server_count)
        end
      end
    end

    describe "create_resource_group" do
      it "successfully returns resource group create response" do
        expect(@service).to receive(:resource_management_client).and_return(
          stub_resource_management_client
        )
        response = @service.create_resource_group(@params)

        expect(response.name).to_not be nil
        expect(response.id).to_not be nil
        expect(response.location).to_not be nil
      end
    end

    describe "create_single_virtual_machine_using_template" do
      it "creates deployment template and deployment parameters" do
        expect(@service).to receive(:create_deployment_template).with(@params)
        expect(@service).to receive(:create_deployment_parameters)
        expect(@service).to receive(:resource_management_client).and_return(
          stub_resource_management_client
        )
        @service.create_virtual_machine_using_template(@params)
      end

      it "successfully returns virtual machine create response" do
        @platform = "Linux"
        allow(@service).to receive(:set_platform).and_return("Linux")
        expect(@service).to receive(:resource_management_client).and_return(
          stub_resource_management_client
        )
        response = @service.create_virtual_machine_using_template(@params)
        expect(response).to_not be nil
      end

      context "when VM size is given by user" do
        before do
          allow(@service).to receive(:resource_management_client).and_return(@resource_client)
        end

        it "If VM size is valid, successfully returns virtual machine create response" do
          @params[:azure_vm_size] = "Standard_F2"
          expect(@service).to receive(:create_deployment_template).with(@params)
          expect(@service).to receive(:create_deployment_parameters)
          expect(@service).to receive(:resource_management_client).and_return(
            stub_resource_management_client
          )
          @service.create_virtual_machine_using_template(@params)
        end

        it "If VM size is invalid, raises an exception" do
          @params[:azure_vm_size] = "abcdf"
          expect(@service).to receive(:create_deployment_template).with(@params)
          expect(@service).to receive(:create_deployment_parameters)
          allow(@resource_client).to receive_message_chain(
            :deployments, :create_or_update
          ).and_raise(Exception)
          expect { @service.create_virtual_machine_using_template(@params) }.to raise_error(Exception)
        end
      end
    end

    describe "vm_public_ip" do
      it "successfully returns vm public ip response" do
        expect(@service).to receive(:network_resource_client).and_return(stub_network_resource_client("Windows"))
        response = @service.vm_public_ip(@params)
        expect(response).to be == "1.2.3.4"
      end
    end

    describe "vm_default_port" do
      context "for Linux" do
        before do
          @platform = "Linux"
        end

        it "successfully returns vm default port response" do
          expect(@service).to receive(:network_resource_client).and_return(stub_network_resource_client(@platform))
          response = @service.vm_default_port(@params)
          expect(response).to be == "22"
        end
      end

      context "for Windows" do
        before do
          @platform = "Windows"
        end

        it "successfully returns vm default port response" do
          expect(@service).to receive(:network_resource_client).and_return(stub_network_resource_client(@platform))
          response = @service.vm_default_port(@params)
          expect(response).to be == "3389"
        end
      end
    end

    describe "create_vm_extension" do
      context "when user has supplied chef extension version value" do
        it "successfully creates virtual machine extension with the user supplied version value" do
          expect(@service).to receive(:compute_management_client).and_return(stub_compute_management_client("yes"))
          expect(@service).to_not receive(:get_latest_chef_extension_version)
          response = @service.create_vm_extension(@params)
          expect(response.name).to be == "test-vm-ext"
          expect(response.id).to_not be nil
          expect(response.type).to be == "Microsoft.Compute/virtualMachines/extensions"
          expect(response.location).to_not be nil
          expect(response.properties).to_not be nil
          expect(response.properties.publisher).to be == "Ext_Publisher"
          expect(response.properties.type).to be == "Ext_Type"
          expect(response.properties.type_handler_version).to be == "11.10.1"
          expect(response.properties.provisioning_state).to be == "Succeeded"
        end
      end

      context "when user has not supplied chef extension version value" do
        before do
          @params.delete(:chef_extension_version)
        end

        it "successfully creates virtual machine extension with the latest version" do
          expect(@service).to receive(:get_latest_chef_extension_version)
          expect(@service).to receive(:compute_management_client).and_return(stub_compute_management_client("no"))
          response = @service.create_vm_extension(@params)
          expect(response.name).to be == "test-vm-ext"
          expect(response.id).to_not be nil
          expect(response.type).to be == "Microsoft.Compute/virtualMachines/extensions"
          expect(response.location).to_not be nil
          expect(response.properties).to_not be nil
          expect(response.properties.publisher).to be == "Ext_Publisher"
          expect(response.properties.type).to be == "Ext_Type"
          expect(response.properties.type_handler_version).to be == "1210.12"
          expect(response.properties.provisioning_state).to be == "Succeeded"
        end
      end
    end

    describe "get_latest_chef_extension_version" do
      it "successfully returns latest Chef Extension version" do
        expect(@service).to receive(:compute_management_client).and_return(
          stub_compute_management_client("NA")
        )
        response = @service.get_latest_chef_extension_version(@params)
        expect(response).to be == "1210.12"
      end
    end

    describe "bootstrap protocol cloud-api" do
      before do
        allow(@arm_server_instance).to receive(:msg_server_summary)
        Chef::Config[:knife][:run_list] = ["getting-started"]
        Chef::Config[:knife][:validation_client_name] = "testorg-validator"
        Chef::Config[:knife][:chef_server_url] = "https://api.opscode.com/organizations/testorg"
      end

      after do
        Chef::Config[:knife].delete(:run_list)
        Chef::Config[:knife].delete(:validation_client_name)
        Chef::Config[:knife].delete(:chef_server_url)
      end

      context "parameters test" do
        context "for chef_extension parameter" do
          before do
            allow(@arm_server_instance).to receive(
              :is_image_windows?
            ).and_return(false)
          end

          it "sets correct value for Linux platform" do
            allow(@arm_server_instance).to receive(
              :is_image_windows?
            ).and_return(false)
            @server_params = @arm_server_instance.create_server_def
            expect(@server_params[:chef_extension]).to be == "LinuxChefClient"
          end

          it "sets correct value for Windows platform" do
            allow(@arm_server_instance).to receive(
              :is_image_windows?
            ).and_return(true)
            @server_params = @arm_server_instance.create_server_def
            expect(@server_params[:chef_extension]).to be == "ChefClient"
          end
        end

        it "sets correct value for chef_extension_publisher parameter" do
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:chef_extension_publisher]).to be == "Chef.Bootstrap.WindowsAzure"
        end

        it "sets user supplied value for chef_extension_version parameter" do
          Chef::Config[:knife][:azure_chef_extension_version] = "1210.12"
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:chef_extension_version]).to be == "1210.12"
        end

        it "sets nil value for chef_extension_version parameter when user has not supplied any value for it" do
          Chef::Config[:knife].delete(:azure_chef_extension_version)
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:chef_extension_version]).to be nil
        end

        it "sets correct config for chef_extension_public_param parameter" do
          allow(@arm_server_instance).to receive(
            :get_chef_extension_public_params
          ).and_return(
            "public_params"
          )
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:chef_extension_public_param]).to be == "public_params"
        end

        it "sets correct config for chef_extension_private_param parameter" do
          allow(@arm_server_instance).to receive(
            :get_chef_extension_private_params
          ).and_return(
            "private_params"
          )
          @server_params = @arm_server_instance.create_server_def
          expect(@server_params[:chef_extension_private_param]).to be == "private_params"
        end
      end

      describe "get_chef_extension_name" do
        context "for Linux" do
          it "successfully returns chef extension name for Linux platform" do
            allow(@arm_server_instance).to receive(
              :is_image_windows?
            ).and_return(false)
            response = @arm_server_instance.get_chef_extension_name
            expect(response).to be == "LinuxChefClient"
          end
        end

        context "for Windows" do
          it "successfully returns chef extension name for Windows platform" do
            allow(@arm_server_instance).to receive(
              :is_image_windows?
            ).and_return(true)
            response = @arm_server_instance.get_chef_extension_name
            expect(response).to be == "ChefClient"
          end
        end
      end

      describe "get_chef_extension_publisher" do
        it "successfully returns chef extension publisher" do
          response = @arm_server_instance.get_chef_extension_publisher
          expect(response).to be == "Chef.Bootstrap.WindowsAzure"
        end
      end

      context "get_chef_extension_public_params" do
        it "sets bootstrapVersion variable in public_config" do
          @arm_server_instance.config[:bootstrap_version] = "12.4.2"
          public_config = { client_rb: "chef_server_url \t \"https://localhost:443\"\nvalidation_client_name\t\"chef-validator\"", runlist: '"getting-started"', extendedLogs: "false", custom_json_attr: {}, hints: %w{vm_name public_fqdn platform}, bootstrap_options: { chef_server_url: "https://localhost:443", validation_client_name: "chef-validator", bootstrap_version: "12.4.2" } }

          response = @arm_server_instance.get_chef_extension_public_params
          expect(response).to be == public_config
        end

        it "should set extendedLogs flag to true" do
          @arm_server_instance.config[:extended_logs] = true
          public_config = { client_rb: "chef_server_url \t \"https://localhost:443\"\nvalidation_client_name\t\"chef-validator\"", runlist: '"getting-started"', extendedLogs: "true", custom_json_attr: {}, hints: %w{vm_name public_fqdn platform}, bootstrap_options: { chef_server_url: "https://localhost:443", validation_client_name: "chef-validator" } }
          response = @arm_server_instance.get_chef_extension_public_params
          expect(response).to be == public_config
        end

        context "service is an instance_of ARM" do
          it "invokes ohai_hints method" do
            expect(@arm_server_instance).to receive(:ohai_hints)
            @arm_server_instance.get_chef_extension_public_params
          end
        end

        context "service is not an instance_of ARM" do
          before do
            allow(@service).to receive(:instance_of?).and_return(false)
          end

          it "does not invoke ohai_hints method" do
            expect(@arm_server_instance).to_not receive(:ohai_hints)
            @arm_server_instance.get_chef_extension_public_params
          end
        end

        it "sets chefServiceInterval variable in public_config" do
          @arm_server_instance.config[:chef_daemon_interval] = "0"
          public_config = { client_rb: "chef_server_url \t \"https://localhost:443\"\nvalidation_client_name\t\"chef-validator\"", runlist: '"getting-started"', extendedLogs: "false", custom_json_attr: {}, hints: %w{vm_name public_fqdn platform}, chef_daemon_interval: "0", bootstrap_options: { chef_server_url: "https://localhost:443", validation_client_name: "chef-validator" } }

          response = @arm_server_instance.get_chef_extension_public_params
          expect(response).to be == public_config
        end

        it "sets daemon variable in public config" do
          @arm_server_instance.config[:daemon] = "service"
          allow(@arm_server_instance).to receive(:is_image_windows?).and_return(true)
          public_config = { client_rb: "chef_server_url \t \"https://localhost:443\"\nvalidation_client_name\t\"chef-validator\"", runlist: '"getting-started"', extendedLogs: "false", custom_json_attr: {}, hints: %w{vm_name public_fqdn platform}, daemon: "service", bootstrap_options: { chef_server_url: "https://localhost:443", validation_client_name: "chef-validator" } }
          response = @arm_server_instance.get_chef_extension_public_params
          expect(response).to be == public_config
        end
      end

      shared_context "private config contents" do
        before do
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:read).and_return("my_validation_key")
        end

        it "calls get chef extension private params and sets private config properly" do
          response = @arm_server_instance.get_chef_extension_private_params
          expect(response).to be == private_config
        end
      end

      context "when validation key is not present", :chef_gte_12_only do
        context "when encrypted_data_bag_secret option is passed" do
          let(:private_config) do
            { validation_key: "my_validation_key",
              encrypted_data_bag_secret: "my_encrypted_data_bag_secret" }
          end

          before do
            @arm_server_instance.config[:encrypted_data_bag_secret] = "my_encrypted_data_bag_secret"
          end

          include_context "private config contents"
        end

        context "when encrypted_data_bag_secret_file option is passed" do
          let(:private_config) do
            { validation_key: "my_validation_key",
              encrypted_data_bag_secret: "PgIxStCmMDsuIw3ygRhmdMtStpc9EMiWisQXoP" }
          end

          before do
            @arm_server_instance.config[:encrypted_data_bag_secret_file] = File.dirname(__FILE__) + "/assets/secret_file"
          end

          include_context "private config contents"
        end
      end

      context "when SSL certificate file option is passed but file does not exist physically" do
        before do
          allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:run)
          allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:client_path).and_return(File.dirname(__FILE__) + "/assets/client.pem")
          @arm_server_instance.config[:cert_path] = "~/tmp/my_cert.crt"
        end

        it "raises an error and exits" do
          expect(@arm_server_instance.ui).to receive(:error).with("Specified SSL certificate does not exist.")
          expect { @arm_server_instance.get_chef_extension_private_params }.to raise_error(SystemExit)
        end
      end

      context "when SSL certificate file option is passed and file exist physically" do
        before do
          allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:run)
          allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:client_path)
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:read).and_return("foo")
          @arm_server_instance.config[:cert_path] = "~/my_cert.crt"
        end

        it "copies SSL certificate contents into chef_server_crt attribute of extension's private params" do
          pri_config = { validation_key: "foo", chef_server_crt: "foo", encrypted_data_bag_secret: nil }
          response = @arm_server_instance.get_chef_extension_private_params
          expect(response).to be == pri_config
        end
      end

      context "when validation key is not present, using chef 11", :chef_lt_12_only do
        before do
          allow(File).to receive(:exist?).and_return(false)
        end

        it "raises an exception if validation_key is not present in chef 11" do
          expect(@arm_server_instance.ui).to receive(:error).twice
          expect { @arm_server_instance.run }.to raise_error(SystemExit)
        end
      end
    end
  end

  describe "set_default_image_reference" do
    it "calls validation for all 4 image reference parameters when os_type without sku is specified by user" do
      @arm_server_instance.config[:azure_image_os_type] = "ubuntu"
      expect(@arm_server_instance).to receive(:validate_arm_keys!).with(
        :azure_image_reference_publisher,
        :azure_image_reference_offer,
        :azure_image_reference_sku,
        :azure_image_reference_version
      )
      expect(@arm_server_instance.ui).to_not receive(:error)
      @arm_server_instance.send(:set_default_image_reference!)
    end

    it "calls validation for all 4 image reference parameters when os_type with sku is specified by user" do
      @arm_server_instance.config[:azure_image_os_type] = "ubuntu"
      @arm_server_instance.config[:azure_image_reference_sku] = "14.04.2-LTS"
      expect(@arm_server_instance).to receive(:validate_arm_keys!).with(
        :azure_image_reference_publisher,
        :azure_image_reference_offer,
        :azure_image_reference_sku,
        :azure_image_reference_version
      )
      expect(@arm_server_instance.ui).to_not receive(:error)
      @arm_server_instance.send(:set_default_image_reference!)
    end

    it "validate_arm_keys! raises error and exits if azure_image_os_type is not specified" do
      @arm_server_instance.config.delete(:azure_image_os_type)
      expect(@arm_server_instance.ui).to receive(:error)
      expect do
        @arm_server_instance.validate_arm_keys!(
          :azure_image_os_type
        )
      end .to raise_error(SystemExit)
    end

    it "validate_arm_keys! raises error and exits if image reference parameters are not specified" do
      expect(@arm_server_instance.ui).to receive(:error).thrice
      expect do
        @arm_server_instance.validate_arm_keys!(
          :azure_image_reference_publisher,
          :azure_image_reference_offer,
          :azure_image_reference_sku,
          :azure_image_reference_version
        )
      end .to raise_error(SystemExit)
    end

    it "calls validation for azure_image_os_type if azure_image_os_type and other image reference parameters are not given" do
      @arm_server_instance.config.delete(:azure_image_os_type)
      @arm_server_instance.config.delete(:azure_image_reference_version)
      @arm_server_instance.default_config.delete(:azure_image_reference_version)
      expect { @arm_server_instance.send(:set_default_image_reference!) }.to raise_error(SystemExit)
    end

    it "raises error and exits if azure_image_os_type or other image reference parameters are not specified" do
      @arm_server_instance.config.delete(:azure_image_os_type)
      expect(@arm_server_instance.ui).to receive(:error)
      expect { @arm_server_instance.send(:set_default_image_reference!) }.to raise_error(SystemExit)
    end

    it "raises error and exits if both azure_image_os_type and other image reference parameters like publisher or offer are specified" do
      @arm_server_instance.config[:azure_image_os_type] = "ubuntu"
      @arm_server_instance.config[:azure_image_reference_publisher] = "azure_image_reference_publisher"
      expect(@arm_server_instance.ui).to receive(:error)
      expect { @arm_server_instance.send(:set_default_image_reference!) }.to raise_error(SystemExit)
    end

    it "sets default image reference parameters for azure_image_os_type=ubuntu" do
      @arm_server_instance.config[:azure_image_os_type] = "ubuntu"
      @arm_server_instance.send(:set_default_image_reference!)
      expect(@arm_server_instance.config[:azure_image_reference_publisher]).to be == "Canonical"
      expect(@arm_server_instance.config[:azure_image_reference_offer]).to be == "UbuntuServer"
      expect(@arm_server_instance.config[:azure_image_reference_sku]).to be == "14.04.2-LTS"
      expect(@arm_server_instance.default_config[:azure_image_reference_version]).to be == "latest"
    end

    it "sets default image reference parameters for azure_image_os_type=centos" do
      @arm_server_instance.config[:azure_image_os_type] = "centos"
      @arm_server_instance.config[:azure_image_reference_version] = "6.5"
      @arm_server_instance.send(:set_default_image_reference!)
      expect(@arm_server_instance.config[:azure_image_reference_publisher]).to be == "OpenLogic"
      expect(@arm_server_instance.config[:azure_image_reference_offer]).to be == "CentOS"
      expect(@arm_server_instance.config[:azure_image_reference_sku]).to be == "7.1"
      expect(@arm_server_instance.config[:azure_image_reference_version]).to be == "6.5"
    end

    it "sets default image reference parameters for azure_image_os_type=rhel" do
      @arm_server_instance.config[:azure_image_os_type] = "rhel"
      @arm_server_instance.send(:set_default_image_reference!)
      expect(@arm_server_instance.config[:azure_image_reference_publisher]).to be == "RedHat"
      expect(@arm_server_instance.config[:azure_image_reference_offer]).to be == "RHEL"
      expect(@arm_server_instance.config[:azure_image_reference_sku]).to be == "7.2"
      expect(@arm_server_instance.default_config[:azure_image_reference_version]).to be == "latest"
    end

    it "sets default image reference parameters for azure_image_os_type=debian" do
      @arm_server_instance.config[:azure_image_os_type] = "debian"
      @arm_server_instance.send(:set_default_image_reference!)
      expect(@arm_server_instance.config[:azure_image_reference_publisher]).to be == "credativ"
      expect(@arm_server_instance.config[:azure_image_reference_offer]).to be == "Debian"
      expect(@arm_server_instance.config[:azure_image_reference_sku]).to be == "7"
      expect(@arm_server_instance.default_config[:azure_image_reference_version]).to be == "latest"
    end

    it "sets default image reference parameters for azure_image_os_type=windows" do
      @arm_server_instance.config[:azure_image_os_type] = "windows"
      @arm_server_instance.send(:set_default_image_reference!)
      expect(@arm_server_instance.config[:azure_image_reference_publisher]).to be == "MicrosoftWindowsServer"
      expect(@arm_server_instance.config[:azure_image_reference_offer]).to be == "WindowsServer"
      expect(@arm_server_instance.config[:azure_image_reference_sku]).to be == "2012-R2-Datacenter"
      expect(@arm_server_instance.default_config[:azure_image_reference_version]).to be == "latest"
    end

    it "overrides sku value for os_type when both azure_image_os_type and azure_image_reference_sku are given" do
      @arm_server_instance.config[:azure_image_os_type] = "windows"
      @arm_server_instance.config[:azure_image_reference_sku] = "2008-R2-SP1"
      @arm_server_instance.send(:set_default_image_reference!)
      expect(@arm_server_instance.config[:azure_image_reference_publisher]).to be == "MicrosoftWindowsServer"
      expect(@arm_server_instance.config[:azure_image_reference_offer]).to be == "WindowsServer"
      expect(@arm_server_instance.config[:azure_image_reference_sku]).to be == "2008-R2-SP1"
      expect(@arm_server_instance.default_config[:azure_image_reference_version]).to be == "latest"
    end

    it "uses all 4 user supplied values for image reference parameters when os_type is not given" do
      @arm_server_instance.config.delete(:azure_image_os_type)
      @arm_server_instance.config[:azure_image_reference_publisher] = "OpenLogic"
      @arm_server_instance.config[:azure_image_reference_offer] = "CentOS"
      @arm_server_instance.config[:azure_image_reference_sku] = "6.7"
      @arm_server_instance.config[:azure_image_reference_version] = "6.7.20150815"
      @arm_server_instance.send(:set_default_image_reference!)
      expect(@arm_server_instance.config[:azure_image_reference_publisher]).to be == "OpenLogic"
      expect(@arm_server_instance.config[:azure_image_reference_offer]).to be == "CentOS"
      expect(@arm_server_instance.config[:azure_image_reference_sku]).to be == "6.7"
      expect(@arm_server_instance.config[:azure_image_reference_version]).to be == "6.7.20150815"
    end

    it "uses default value for version when other 3 image reference parameters are given by user except os_type" do
      @arm_server_instance.config.delete(:azure_image_os_type)
      @arm_server_instance.config.delete(:azure_image_reference_version)
      @arm_server_instance.config[:azure_image_reference_publisher] = "Canonical"
      @arm_server_instance.config[:azure_image_reference_offer] = "UbuntuServer"
      @arm_server_instance.config[:azure_image_reference_sku] = "12.04.5-LTS"
      @arm_server_instance.send(:set_default_image_reference!)
      expect(@arm_server_instance.config[:azure_image_reference_publisher]).to be == "Canonical"
      expect(@arm_server_instance.config[:azure_image_reference_offer]).to be == "UbuntuServer"
      expect(@arm_server_instance.config[:azure_image_reference_sku]).to be == "12.04.5-LTS"
      expect(@arm_server_instance.default_config[:azure_image_reference_version]).to be == "latest"
    end

    it "throws error if invalid azure_image_os_type is given" do
      @arm_server_instance.config[:azure_image_os_type] = "abc"
      @arm_server_instance.config.delete(:azure_image_reference_publisher)
      @arm_server_instance.config.delete(:azure_image_reference_offer)
      @arm_server_instance.config.delete(:azure_image_reference_sku)
      @arm_server_instance.config.delete(:azure_image_reference_version)
      expect(@arm_server_instance.ui).to receive(:error)
      expect { @arm_server_instance.send(:set_default_image_reference!) }.to raise_error(SystemExit)
    end
  end

  describe "create_multiple_virtual_machine_using_template" do
    before do
      @params[:server_count] = 3
      allow(@service).to receive(:resource_management_client).and_return(@resource_client)
    end

    it "creates deployment template and deployment parameters" do
      expect(@service).to receive(:create_deployment_template).with(@params)
      expect(@service).to receive(:create_deployment_parameters)
      expect(@service).to receive(:resource_management_client).and_return(
        stub_resource_management_client
      )
      @service.create_virtual_machine_using_template(@params)
    end

    it "raises exception if deployment is not successful" do
      expect(@service).to receive(:create_deployment_template).with(@params)
      expect(@service).to receive(:create_deployment_parameters)
      allow(@resource_client).to receive_message_chain(
        :deployments, :create_or_update
      ).and_raise(Exception)
      expect { @service.create_virtual_machine_using_template(@params) }.to raise_error(Exception)
    end

    after do
      @params.delete(:server_count)
    end
  end

  describe "create_deployment_template" do
    before do
      bootstrap_options = { chef_server_url: "url",
                            validation_client_name: "client_name",
                            bootstrap_proxy: "http://test.com",
                            node_ssl_verify_mode: "true",
                            node_verify_api_cert: "hfyreiur374294nehfdishf",
                            environment: "development" }
      @params[:chef_extension_public_param] = { hints: %w{vm_name public_fqdn platform},
                                                bootstrap_options: bootstrap_options,
                                                extendedLogs: "true" }
      {
        azure_image_reference_publisher: "OpenLogic",
        azure_image_reference_offer: "CentOS",
        azure_image_reference_sku: "6.5",
        azure_image_reference_version: "latest",
        connection_user: "connection_user",
        server_count: 3,
        vm_size: "Standard_A1_v2",
      }.each do |key, value|
        @params[key] = value
      end

      @hints_json = { "vm_name" => "[reference(resourceId('Microsoft.Compute/virtualMachines', concat(variables('vmName'),copyIndex()))).osProfile.computerName]",
                      "public_fqdn" => "[reference(resourceId('Microsoft.Network/publicIPAddresses',concat(variables('publicIPAddressName'),copyIndex()))).dnsSettings.fqdn]",
                      "platform" => "[concat(reference(resourceId('Microsoft.Compute/virtualMachines', concat(variables('vmName'),copyIndex()))).storageProfile.imageReference.offer, concat(' ', reference(resourceId('Microsoft.Compute/virtualMachines', concat(variables('vmName'),copyIndex()))).storageProfile.imageReference.sku))]" }
      @params[:chef_extension_private_param] = {
        encrypted_data_bag_secret: "rihrfwe739085928592nehrweirwefjsndwe",
      }
    end

    it "sets the parameters which are passed in the template" do
      template = @service.create_deployment_template(@params)

      expect(template["variables"]["imagePublisher"]).to be == "OpenLogic"
      expect(template["variables"]["imageOffer"]).to be == "CentOS"
      expect(template["variables"]["OSDiskName"]).to be == "azureosdiskname"
      expect(template["variables"]["nicName"]).to be == "test-vm"
      expect(template["variables"]["subnetName"]).to be == "azure_subnet_name"
      expect(template["variables"]["storageAccountType"]).to be == "azure_storage_account_type"
      expect(template["variables"]["publicIPAddressName"]).to be == "test-vm"
      expect(template["variables"]["vmStorageAccountContainerName"]).to be == "test-vm"
      expect(template["variables"]["vmName"]).to be == "test-vm"
      expect(template["variables"]["vmSize"]).to be == "Standard_A1_v2"
      expect(template["variables"]["virtualNetworkName"]).to be == "vnet1"
      expect(template["variables"]["vmExtensionName"]).to be == "chef_extension"

      extension = ""
      template["resources"].each do |resource|
        extension = resource if resource["type"] == "Microsoft.Compute/virtualMachines/extensions"
      end
      expect(extension["name"]).to be == "[concat(variables('vmName'),copyIndex(),'/', variables('vmExtensionName'))]"
      expect(extension["properties"]["publisher"]).to be == "chef_extension_publisher"
      expect(extension["properties"]["type"]).to be == "chef_extension"
      expect(extension["properties"]["typeHandlerVersion"]).to be == "11.10.1"
      expect(extension["properties"]["settings"]["bootstrap_options"]["chef_node_name"]).to be(nil)
      expect(extension["properties"]["settings"]["bootstrap_options"]["chef_server_url"]).to be == "[parameters('chef_server_url')]"
      expect(extension["properties"]["settings"]["bootstrap_options"]["validation_client_name"]).to be == "[parameters('validation_client_name')]"
      expect(extension["properties"]["settings"]["runlist"]).to be == "[parameters('runlist')]"
      expect(extension["properties"]["settings"]["hints"]).to be == @hints_json
      expect(extension["properties"]["settings"]["bootstrap_version"]).to be == "[parameters('bootstrap_version')]"
      expect(extension["properties"]["settings"]["bootstrap_options"]["bootstrap_proxy"]).to be == "[parameters('bootstrap_proxy')]"
      expect(extension["properties"]["settings"]["bootstrap_options"]["node_ssl_verify_mode"]).to be == "[parameters('node_ssl_verify_mode')]"
      expect(extension["properties"]["settings"]["bootstrap_options"]["node_verify_api_cert"]).to be == "[parameters('node_verify_api_cert')]"
      expect(extension["properties"]["settings"]["extendedLogs"]).to be == "true"
      expect(extension["properties"]["settings"]["bootstrap_options"]["environment"]).to be == "[parameters('environment')]"

      expect(extension["properties"]["protectedSettings"]["encrypted_data_bag_secret"]).to be == "[parameters('encrypted_data_bag_secret')]"
    end

    it "does not set extendedLogs parameter under extension config in the template" do
      @params[:chef_extension_public_param][:extendedLogs] = "false"
      template = @service.create_deployment_template(@params)

      extension = ""
      template["resources"].each do |resource|
        extension = resource if resource["type"] == "Microsoft.Compute/virtualMachines/extensions"
      end

      expect(extension["properties"]["settings"].key?("extendedLogs")).to be == false
    end

    context "chef_daemon_interval option" do
      context "is passed by the user" do
        before do
          @params[:chef_extension_public_param][:chef_daemon_interval] = "19"
        end

        it "sets the chef_daemon_interval parameter under extension config in the template" do
          template = @service.create_deployment_template(@params)

          extension = nil
          template["resources"].each do |resource|
            extension = resource if resource["type"] == "Microsoft.Compute/virtualMachines/extensions"
          end

          expect(extension["properties"]["settings"].key?("chef_daemon_interval")).to be == true
          expect(extension["properties"]["settings"]["chef_daemon_interval"]).to be == "19"
        end
      end

      context "is not passed by the user" do
        before do
          @params[:chef_extension_public_param][:chef_daemon_interval] = nil
        end

        it "does not set the chef_daemon_interval parameter under extension config in the template" do
          template = @service.create_deployment_template(@params)

          extension = nil
          template["resources"].each do |resource|
            extension = resource if resource["type"] == "Microsoft.Compute/virtualMachines/extensions"
          end

          expect(extension["properties"]["settings"].key?("chef_daemon_interval")).to be == false
        end
      end
    end

    context "daemon option" do
      context "is passed by the user" do
        before do
          @params[:chef_extension_public_param][:daemon] = "service"
        end

        it "sets the daemon parameter under extension config in the template" do
          template = @service.create_deployment_template(@params)

          extension = nil
          template["resources"].each do |resource|
            extension = resource if resource["type"] == "Microsoft.Compute/virtualMachines/extensions"
          end

          expect(extension["properties"]["settings"].key?("daemon")).to be == true
          expect(extension["properties"]["settings"]["daemon"]).to be == "service"
        end
      end

      context "is not passed by the user" do
        before do
          @params[:chef_extension_public_param][:daemon] = nil
        end

        it "does not set the daemon parameter under extension config in the template" do
          template = @service.create_deployment_template(@params)

          extension = nil
          template["resources"].each do |resource|
            extension = resource if resource["type"] == "Microsoft.Compute/virtualMachines/extensions"
          end

          expect(extension["properties"]["settings"].key?("daemon")).to be == false
        end
      end
    end

    after do
      @params.delete(:server_count)
    end
  end

  describe "create_deployment_parameters" do
    before do
      bootstrap_options = { chef_server_url: "url",
                            validation_client_name: "client_name",
                            bootstrap_proxy: "http://test.com",
                            node_ssl_verify_mode: "true",
                            node_verify_api_cert: "hfyreiur374294nehfdishf",
                            chef_node_name: "test-vm",
                            environment: "development" }
      @params[:chef_extension_public_param] = { bootstrap_options: bootstrap_options }
      @params[:chef_extension_private_param] = {
        validation_key: "validation_key",
        encrypted_data_bag_secret: "rihrfwe739085928592nehrweirwefjsndwe",
      }
      {
        azure_image_reference_publisher: "OpenLogic",
        azure_image_reference_offer: "CentOS",
        azure_image_reference_sku: "6.5",
        azure_image_reference_version: "latest",
        connection_user: "connection_user",
        connection_password: "connection_password",
        server_count: 3,
        client_rb: "contents_of_client_rb",
        custom_json_attr: '"{name: test}"',
      }.each do |key, value|
        @params[key] = value
      end
    end

    it "sets the parameters which are passed in the template" do
      parameters = @service.create_deployment_parameters(@params)
      expect(parameters["adminUserName"]["value"]).to be == "connection_user"
      expect(parameters["adminPassword"]["value"]).to be == "connection_password"
      expect(parameters["dnsLabelPrefix"]["value"]).to be == "test-vm"
      expect(parameters["imageSKU"]["value"]).to be == "6.5"
      expect(parameters["numberOfInstances"]["value"]).to be == 3
      expect(parameters["validation_key"]["value"]).to be == "validation_key"
      expect(parameters["chef_server_url"]["value"]).to be == "url"
      expect(parameters["validation_client_name"]["value"]).to be == "client_name"
      expect(parameters["runlist"]["value"]).to be == ""
      expect(parameters["encrypted_data_bag_secret"]["value"]).to be == "rihrfwe739085928592nehrweirwefjsndwe"
      expect(parameters["bootstrap_proxy"]["value"]).to be == "http://test.com"
      expect(parameters["node_ssl_verify_mode"]["value"]).to be == "true"
      expect(parameters["node_verify_api_cert"]["value"]).to be == "hfyreiur374294nehfdishf"
      expect(parameters["chef_node_name"]["value"]).to be == "test-vm"
      expect(parameters["environment"]["value"]).to be == "development"
    end

    context "--ssh-public-key option is provided " do
      before do
        @params[:ssh_public_key] = "foo"
        @params[:disablePasswordAuthentication] = "true"
      end

      it "sets ssh-key data and sets disablePasswordAuthentication to true" do
        parameters = @service.create_deployment_parameters(@params)
        expect(parameters["sshKeyData"]["value"]).to be == "foo"
        expect(parameters["disablePasswordAuthentication"]["value"]).to be == "true"
      end

      it "not sets the ssh_key and disablePasswordAuthentication param if windows" do
        parameters = @service.create_deployment_parameters(@params)
        expect(parameters["sshKeyData"]["value"]).to be == "foo"
        expect(parameters["disablePasswordAuthentication"]["value"]).to be == "true"
      end
    end

    after do
      @params.delete(:server_count)
    end
  end

  describe "supported_ohai_hints" do
    it "returns the list of supported values" do
      response = @arm_server_instance.supported_ohai_hints
      expect(response).to be == ohai_hints_values
    end
  end

  describe "format_ohai_hints" do
    context "no input given by user" do
      it "formats the default input for Ohai Hints where the expected result is same as the default value" do
        response = @arm_server_instance.format_ohai_hints("default")
        expect(response).to be == "default"
      end
    end

    context "input given by user in correct format" do
      it "formats the user input for Ohai Hints where the expected result is same as the user's input" do
        response = @arm_server_instance.format_ohai_hints("public_fqdn,vm_name")
        expect(response).to be == "public_fqdn,vm_name"
      end
    end

    context "input given by user with incorrect syntax" do
      it "formats the user input for Ohai Hints where the expected result is the value with correct syntax" do
        response = @arm_server_instance.format_ohai_hints("public_fqdn,vm_name,")
        expect(response).to be == "public_fqdn,vm_name"
      end
    end

    context "input given by user in incorrect syntax and incorrect format" do
      it "formats the user input for Ohai Hints where the expected result is the value in correct syntax and correct format" do
        response = @arm_server_instance.format_ohai_hints("public_fqdn , vm_name, platform ,,")
        expect(response).to be == "public_fqdn,vm_name,platform"
      end
    end

    context "input given by user in incorrect format" do
      it "formats the user input for Ohai Hints where the expected result is the value in correct format" do
        response = @arm_server_instance.format_ohai_hints(" public_fqdn ,platform , vm_name ")
        expect(response).to be == "public_fqdn,platform,vm_name"
      end
    end
  end

  describe "is_supported_ohai_hint?" do
    context "supported value given by user" do
      it "returns true" do
        response = @arm_server_instance.is_supported_ohai_hint?("platform")
        expect(response).to be true
      end
    end

    context "unsupported value given by user" do
      it "returns false" do
        response = @arm_server_instance.is_supported_ohai_hint?("mac_address")
        expect(response).to be false
      end
    end
  end

  describe "validate_ohai_hints" do
    context "correct input by user" do
      before do
        @arm_server_instance.config[:ohai_hints] = "vm_name,platform"
      end

      it "does not raise error" do
        expect { @arm_server_instance.validate_ohai_hints }.to_not raise_error
      end
    end

    context "incorrect input by user" do
      before do
        @arm_server_instance.default_config[:ohai_hints] = "public_fqdn,vm_name,platform,mac_address"
      end

      it "do raise error" do
        expect { @arm_server_instance.validate_ohai_hints }.to raise_error(
          ArgumentError
        )
      end
    end
  end

  describe "default_hint_options" do
    it "returns the list of default hint values" do
      response = @arm_server_instance.default_hint_options
      expect(response).to be == ohai_hints_values
    end
  end

  describe "ohai_hints in bootstrapper" do
    context "no input given by user" do
      it "returns default values for Ohai Hints" do
        response = @arm_server_instance.ohai_hints
        expect(response).to be == ohai_hints_values
      end
    end

    context "input given by user" do
      before do
        @arm_server_instance.config[:ohai_hints] = "platform,vm_name"
      end

      it "returns the input given by user" do
        response = @arm_server_instance.ohai_hints
        expect(response[0]).to be == "platform"
        expect(response[1]).to be == "vm_name"
      end
    end
  end

  describe "ohai_hints in arm_deployment_template" do
    before do
      @hint_names = ohai_hints_values
      @resource_ids = { "vmId" =>
        "resourceId('Microsoft.Compute/virtualMachines', variables('vmName'))",
                        "pubId" => "resourceId('Microsoft.Network/publicIPAddresses',variables('publicIPAddressName'))" }
    end

    it "returns the json for the given hint names to be set in the template for Ohai Hints configuration" do
      response = @service.ohai_hints(@hint_names, @resource_ids)
      expect(response["vm_name"]).to be == "[reference(resourceId('Microsoft.Compute/virtualMachines', variables('vmName'))).osProfile.computerName]"
      expect(response["public_fqdn"]).to be == "[reference(resourceId('Microsoft.Network/publicIPAddresses',variables('publicIPAddressName'))).dnsSettings.fqdn]"
      expect(response["platform"]).to be == "[concat(reference(resourceId('Microsoft.Compute/virtualMachines', variables('vmName'))).storageProfile.imageReference.offer, concat(' ', reference(resourceId('Microsoft.Compute/virtualMachines', variables('vmName'))).storageProfile.imageReference.sku))]"
    end
  end

  describe "parse_substatus_code" do
    it "returns substatus' name field" do
      response = @service.parse_substatus_code("ComponentStatus/Chef Client run logs/succeeded", 1)
      expect(response).to be == "Chef Client run logs"
    end

    it "returns substatus' status field" do
      response = @service.parse_substatus_code("ComponentStatus/Chef Client run logs/failed/0", 2)
      expect(response).to be == "failed"
    end
  end

  describe "fetch_substatus" do
    context "no substatuses returned" do
      before do
        allow(@service).to receive(:compute_management_client).and_return(
          stub_compute_management_client("substatuses_not_found")
        )
      end

      it "returns nil" do
        response = @service.fetch_substatus(@params[:azure_resource_group_name],
          @params[:azure_vm_name],
          @params[:chef_extension])

        expect(response).to be_nil
      end
    end

    context "substatuses returned" do
      context "but it does not contain chef-client run logs substatus" do
        before do
          allow(@service).to receive(:compute_management_client).and_return(
            stub_compute_management_client("substatuses_found_with_no_chef_client_run_logs")
          )
        end

        it "returns nil" do
          response = @service.fetch_substatus(@params[:azure_resource_group_name],
            @params[:azure_vm_name],
            @params[:chef_extension])

          expect(response).to be_nil
        end
      end

      context "and it do not contain chef-client run logs substatus" do
        before do
          allow(@service).to receive(:compute_management_client).and_return(
            stub_compute_management_client("substatuses_found_with_chef_client_run_logs")
          )
        end

        it "returns substatus hash for chef-client run logs" do
          response = @service.fetch_substatus(@params[:azure_resource_group_name],
            @params[:azure_vm_name],
            @params[:chef_extension])

          expect(response).to_not be_nil
          expect(response.code).to be == "ComponentStatus/Chef Client run logs/succeeded"
          expect(response.message).to be == "chef_client_run_logs"
        end
      end
    end
  end

  describe "fetch_chef_client_logs" do
    context "chef-client run logs substatus not available yet" do
      before do
        allow(@service).to receive(:fetch_substatus).and_return(nil)
        @start_time = Time.now
      end

      context "wait time has not exceeded wait timeout limit" do
        it "sleeps for some time and re-invokes the fetch_chef_client_logs method recursively" do
          @service.instance_eval do
            class << self
              alias fetch_chef_client_logs_mocked fetch_chef_client_logs
            end
          end

          expect(@service).to receive(:print).exactly(1).times
          expect(@service).to receive(:sleep).with(30)
          expect(@service).to receive(:fetch_chef_client_logs).with(@params[:azure_resource_group_name],
            @params[:azure_vm_name],
            @params[:chef_extension],
            @start_time,
            30)

          @service.fetch_chef_client_logs_mocked(@params[:azure_resource_group_name],
            @params[:azure_vm_name],
            @params[:chef_extension],
            @start_time)
        end
      end

      context "wait time has exceeded wait timeout limit" do
        it "displays wait timeout exceeded message" do
          expect(@service.ui).to receive(:error).with(
            "\nchef-client run logs could not be fetched since fetch process exceeded wait timeout of -1 minutes.\n"
          )
          @service.fetch_chef_client_logs(@params[:azure_resource_group_name],
            @params[:azure_vm_name],
            @params[:chef_extension],
            @start_time,
            -1)
        end
      end
    end

    context "chef-client run logs substatus available now" do
      before do
        substatus = OpenStruct.new(
          code: "ComponentStatus/Chef Client run logs/succeeded",
          level: "Info",
          display_status: "Provisioning succeeded",
          message: "chef_client_run_logs",
          time: "chef_client_run_logs_write_time"
        )
        allow(@service).to receive(:fetch_substatus).and_return(substatus)
        @start_time = Time.now
      end

      it "displays chef-client run logs and exit status to the user" do
        expect(@service).to receive(:puts).exactly(4).times
        expect(@service).to receive(:print).exactly(1).times
        @service.fetch_chef_client_logs(@params[:azure_resource_group_name],
          @params[:azure_vm_name],
          @params[:chef_extension],
          @start_time)
      end
    end
  end

  def ohai_hints_values
    %w{
      vm_name
      public_fqdn
      platform
    }
  end

  def stub_client_builder
    client_builder_mock = double("ClientBuilder")
    key = "/key.pem"
    allow(@arm_server_instance).to receive(:client_builder).and_return client_builder_mock
    allow(client_builder_mock).to receive(:run).and_return "client"
    allow(client_builder_mock).to receive(:client_path).and_return key
    allow(@arm_server_instance).to receive(:create_node_and_client_pem).and_return key
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(key).and_return(true)
  end
end
