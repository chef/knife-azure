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

describe Chef::Knife::BootstrapAzure do
  include AzureSpecHelper
  include QueryAzureMock
  include AzureUtility

  before do
    @bootstrap_azure_instance = create_instance(Chef::Knife::BootstrapAzure)
    @service = @bootstrap_azure_instance.service
    Chef::Config[:knife][:azure_dns_name] = "test-dns-01"
    @bootstrap_azure_instance.name_args = ["test-vm-01"]
    @server_role = Azure::Role.new("connection")
    allow(@bootstrap_azure_instance.ui).to receive(:info)
    allow(@bootstrap_azure_instance).to receive(:puts)
    allow(@bootstrap_azure_instance).to receive(:check_license)
  end

  describe "parameters validation" do
    it "raises error when azure_subscription_id is not specified" do
      Chef::Config[:knife].delete(:azure_subscription_id)
      expect(@bootstrap_azure_instance.ui).to receive(:error)
      expect { @bootstrap_azure_instance.run }.to raise_error(SystemExit)
    end

    it "raises error when azure_mgmt_cert is not specified" do
      Chef::Config[:knife].delete(:azure_mgmt_cert)
      expect(@bootstrap_azure_instance.ui).to receive(:error)
      expect { @bootstrap_azure_instance.run }.to raise_error(SystemExit)
    end

    it "raises error when azure_api_host_name is not specified" do
      Chef::Config[:knife].delete(:azure_api_host_name)
      expect(@bootstrap_azure_instance.ui).to receive(:error)
      expect { @bootstrap_azure_instance.run }.to raise_error(SystemExit)
    end

    it "raises error when server name is not specified" do
      @bootstrap_azure_instance.name_args = []
      expect(@service).to_not receive(:add_extension)
      expect(@bootstrap_azure_instance.ui).to receive(
        :error
      ).with("Please specify the SERVER name which needs to be bootstrapped via the Chef Extension.")
      expect(Chef::Log).to receive(:debug).at_least(:once)
      expect { @bootstrap_azure_instance.run }.to raise_error(SystemExit)
    end

    it "raises error when more than one server name is specified" do
      @bootstrap_azure_instance.name_args = %w{test-vm-01 test-vm-02 test-vm-03}
      expect(@bootstrap_azure_instance.name_args.length).to be == 3
      expect(@service).to_not receive(:add_extension)
      expect(@bootstrap_azure_instance.ui).to receive(
        :error
      ).with("Please specify only one SERVER name which needs to be bootstrapped via the Chef Extension.")
      expect(Chef::Log).to receive(:debug).at_least(:once)
      expect { @bootstrap_azure_instance.run }.to raise_error(SystemExit)
    end

    it "raises error when server name specified does not exist under the given hosted service" do
      expect(@bootstrap_azure_instance.name_args.length).to be == 1
      expect(@service).to_not receive(:add_extension)
      expect(@service).to receive(
        :find_server
      ).and_return([])
      expect(@bootstrap_azure_instance.ui).to receive(
        :error
      ).with("Server test-vm-01 does not exist under the hosted service test-dns-01.")
      expect(Chef::Log).to receive(:debug).at_least(:once)
      expect { @bootstrap_azure_instance.run }.to raise_error(SystemExit)
    end

    it "raises error when hosted service specified does not exist" do
      expect(@bootstrap_azure_instance.name_args.length).to be == 1
      expect(@service).to_not receive(:add_extension)
      expect(@service).to receive(
        :find_server
      ).and_return(nil)
      expect(@bootstrap_azure_instance.ui).to receive(
        :error
      ).with("Hosted service test-dns-01 does not exist.")
      expect(Chef::Log).to receive(:debug).at_least(:once)
      expect { @bootstrap_azure_instance.run }.to raise_error(SystemExit)
    end

    it "raises error when hosted service name is not given but invalid server name is given" do
      Chef::Config[:knife].delete(:azure_dns_name)
      expect(@bootstrap_azure_instance.name_args.length).to be == 1
      expect(@service).to_not receive(:add_extension)
      expect(@service).to receive(
        :find_server
      ).and_return(nil)
      expect(@bootstrap_azure_instance.ui).to receive(
        :error
      ).with("Server test-vm-01 does not exist.")
      expect(Chef::Log).to receive(:debug).at_least(:once)
      expect { @bootstrap_azure_instance.run }.to raise_error(SystemExit)
    end

    context "server name specified do exist" do
      context "hosted service name is specified in Chef::Config[:knife] object" do
        before do
          @server_role.hostedservicename = "my_new_dns"
          allow(@server_role).to receive_message_chain(
            :os_type, :downcase
          ).and_return("windows")
          allow(@server_role).to receive(
            :deployname
          ).and_return("")
          allow(@server_role).to receive(:role_xml).and_return("")
          allow(@bootstrap_azure_instance).to receive(
            :get_chef_extension_version
          )
          allow(@bootstrap_azure_instance).to receive(
            :get_chef_extension_public_params
          )
          allow(@bootstrap_azure_instance).to receive(
            :get_chef_extension_private_params
          )
        end

        it "does not raise error when server name do exist and does not re-initializes azure_dns_name in bootstrap_azure_instance's config using server object" do
          expect(@bootstrap_azure_instance.name_args.length).to be == 1
          expect(@service).to receive(:add_extension)
          expect(@service).to receive(
            :find_server
          ).and_return(@server_role)
          expect { @bootstrap_azure_instance.run }.not_to raise_error
          expect(Chef::Config[:knife][:azure_dns_name]).to be == "test-dns-01"
          expect(@bootstrap_azure_instance.config[:azure_dns_name]).to be_nil
        end
      end

      context "hosted service name is not specified in Chef::Config[:knife] object or anywhere else" do
        before do
          Chef::Config[:knife].delete(:azure_dns_name)
          @server_role.hostedservicename = "my_new_dns"
          allow(@server_role).to receive_message_chain(
            :os_type, :downcase
          ).and_return("windows")
          allow(@server_role).to receive(
            :deployname
          ).and_return("")
          allow(@server_role).to receive(:role_xml).and_return("")
          allow(@bootstrap_azure_instance).to receive(
            :get_chef_extension_version
          )
          allow(@bootstrap_azure_instance).to receive(
            :get_chef_extension_public_params
          )
          allow(@bootstrap_azure_instance).to receive(
            :get_chef_extension_private_params
          )
        end

        it "does not raise error when server name do exist and initializes azure_dns_name in bootstrap_azure_instance's config using server object" do
          expect(@bootstrap_azure_instance.name_args.length).to be == 1
          expect(@service).to receive(:add_extension)
          expect(@service).to receive(
            :find_server
          ).and_return(@server_role)
          expect { @bootstrap_azure_instance.run }.not_to raise_error
          expect(@bootstrap_azure_instance.config[:azure_dns_name]).to be == "my_new_dns"
          expect(Chef::Config[:knife][:azure_dns_name]).to be_nil
        end
      end
    end
  end

  describe "extended_logs functionality" do
    context "when extended_logs is false" do
      it "deploys the Chef Extension on the server but then does not wait and fetch the chef-client run logs" do
        expect(@bootstrap_azure_instance.name_args.length).to be == 1
        expect(@bootstrap_azure_instance).to receive(:set_ext_params)
        expect(@service).to receive(:add_extension)
        expect(@bootstrap_azure_instance).to_not receive(:print)
        expect(@bootstrap_azure_instance).to_not receive(:wait_until_extension_available)
        expect(@bootstrap_azure_instance).to_not receive(:fetch_chef_client_logs)
        @bootstrap_azure_instance.run
      end
    end

    context "when extended_logs is true" do
      before do
        Chef::Config[:knife][:extended_logs] = true
      end

      it "deploys the Chef Extension on the server and also waits and fetch the chef-client run logs" do
        expect(@bootstrap_azure_instance.name_args.length).to be == 1
        expect(@bootstrap_azure_instance).to receive(:set_ext_params)
        expect(@service).to receive(:add_extension)
        expect(@bootstrap_azure_instance).to receive(:print).exactly(2).times
        expect(@bootstrap_azure_instance).to receive(:wait_until_extension_available)
        expect(@bootstrap_azure_instance).to receive(:fetch_chef_client_logs)
        @bootstrap_azure_instance.run
      end

      context "when Chef Extension becomes available/ready within the prescribed timeout" do
        it "successfully deploys the Chef Extension on the server and also successfully fetches the chef-client run logs without raising any error" do
          expect(@bootstrap_azure_instance.name_args.length).to be == 1
          expect(@bootstrap_azure_instance).to receive(:set_ext_params)
          expect(@service).to receive(:add_extension)
          expect(@bootstrap_azure_instance).to receive(:print).exactly(2).times
          expect(@bootstrap_azure_instance).to receive(:wait_until_extension_available)
          expect(@bootstrap_azure_instance).to receive(:fetch_chef_client_logs)
          expect { @bootstrap_azure_instance.run }.to_not raise_error
        end
      end

      context "when Chef Extension does not become available/ready within the prescribed timeout" do
        it "successfully deploys the Chef Extension on the server but fails to fetch the chef-client run logs as extension is unavailable and so it raises error and exits" do
          expect(@bootstrap_azure_instance.name_args.length).to be == 1
          expect(@bootstrap_azure_instance).to receive(:set_ext_params)
          expect(@service).to receive(:add_extension)
          expect(@bootstrap_azure_instance).to receive(:print).exactly(1).times
          allow(@bootstrap_azure_instance).to receive(
            :wait_until_extension_available
          ).and_raise(
            "\nUnable to fetch chef-client run logs as Chef Extension seems to be unavailable even after 11 minutes of its deployment.\n"
          )
          expect(@bootstrap_azure_instance).to_not receive(:fetch_chef_client_logs)
          expect(@bootstrap_azure_instance.ui).to receive(:error).with(
            "\nUnable to fetch chef-client run logs as Chef Extension seems to be unavailable even after 11 minutes of its deployment.\n"
          )
          expect { @bootstrap_azure_instance.run }.to raise_error(SystemExit)
        end
      end
    end
  end

  describe "os_type and os_version support validation" do
    context "invalid os_type for the given server" do
      before do
        allow(@server_role).to receive(
          :os_type
        ).and_return("Abc")
      end

      it "raises an error" do
        expect(@service).to receive(
          :find_server
        ).and_return(@server_role)
        expect(@bootstrap_azure_instance.ui).to receive(
          :error
        ).with("OS type Abc is not supported.")
        expect(Chef::Log).to receive(:debug).at_least(:once)
        expect { @bootstrap_azure_instance.run }.to raise_error(SystemExit)
      end
    end

    context "invalid os_version for the given Linux server" do
      before do
        allow(@server_role).to receive(
          :os_type
        ).and_return("Linux")
        allow(@server_role).to receive(
          :os_version
        ).and_return("Suse")
      end

      it "raises an error" do
        expect(@service).to receive(
          :find_server
        ).and_return(@server_role)
        expect(@bootstrap_azure_instance.ui).to receive(
          :error
        ).with("OS version Suse for OS type Linux is not supported.")
        expect(Chef::Log).to receive(:debug).at_least(:once)
        expect { @bootstrap_azure_instance.run }.to raise_error(SystemExit)
      end
    end

    context "valid os_type and valid os_version" do
      before do
        allow(@server_role).to receive(
          :deployname
        ).and_return("test-deploy-01")
        allow(@server_role).to receive(
          :role_xml
        ).and_return("vm-role-xml")
        allow(@bootstrap_azure_instance).to receive(
          :get_chef_extension_version
        ).and_return("1210.*")
        allow(@bootstrap_azure_instance).to receive(
          :get_chef_extension_public_params
        ).and_return(
          "chef_ext_public_params"
        )
        allow(@bootstrap_azure_instance).to receive(
          :get_chef_extension_private_params
        ).and_return(
          "chef_ext_private_params"
        )
      end

      context "for Linux" do
        before do
          allow(@server_role).to receive(
            :os_type
          ).and_return("Linux")
          allow(@server_role).to receive(
            :os_version
          ).and_return("CentOS")
        end

        it "sets the extension parameters for Linux platform" do
          expect(@service).to receive(
            :find_server
          ).and_return(@server_role)
          response = @bootstrap_azure_instance.set_ext_params
          expect(response[:chef_extension]).to be == "LinuxChefClient"
          expect(response[:azure_dns_name]).to be == "test-dns-01"
          expect(response[:deploy_name]).to be == "test-deploy-01"
          expect(response[:role_xml]).to be == "vm-role-xml"
          expect(response[:azure_vm_name]).to be == "test-vm-01"
          expect(response[:chef_extension_publisher]).to be == "Chef.Bootstrap.WindowsAzure"
          expect(response[:chef_extension_version]).to be == "1210.*"
          expect(response[:chef_extension_public_param]).to be == "chef_ext_public_params"
          expect(response[:chef_extension_private_param]).to be == "chef_ext_private_params"
        end
      end

      context "for Windows" do
        before do
          allow(@server_role).to receive(
            :os_type
          ).and_return("Windows")
        end

        it "sets the extension parameters for Windows platform" do
          expect(@service).to receive(
            :find_server
          ).and_return(@server_role)
          response = @bootstrap_azure_instance.set_ext_params
          expect(response[:chef_extension]).to be == "ChefClient"
          expect(response[:azure_dns_name]).to be == "test-dns-01"
          expect(response[:deploy_name]).to be == "test-deploy-01"
          expect(response[:role_xml]).to be == "vm-role-xml"
          expect(response[:azure_vm_name]).to be == "test-vm-01"
          expect(response[:chef_extension_publisher]).to be == "Chef.Bootstrap.WindowsAzure"
          expect(response[:chef_extension_version]).to be == "1210.*"
          expect(response[:chef_extension_public_param]).to be == "chef_ext_public_params"
          expect(response[:chef_extension_private_param]).to be == "chef_ext_private_params"
        end
      end
    end
  end

  describe "parse role list xml" do
    it "reads os_type and os_version from role list 1 xml" do
      role_list_1_xml = Nokogiri::XML(readFile("bootstrap_azure_role_xmls/parse_role_list_xml/role_list_1.xml"))
      role = Azure::Role.new("connection")
      role.parse_role_list_xml(role_list_1_xml)
      expect(role.role_xml).to be == role_list_1_xml
      expect(role.os_type).to be == "Linux"
      expect(role.os_version).to be == "842c8b9c6cvxzcvxzcv048xvbvge2323qe4c3__OpenLogic-CentOS-67-20140205"
    end

    it "reads os_type and os_version from role list 2 xml" do
      role_list_2_xml = Nokogiri::XML(readFile("bootstrap_azure_role_xmls/parse_role_list_xml/role_list_2.xml"))
      role = Azure::Role.new("connection")
      role.parse_role_list_xml(role_list_2_xml)
      expect(role.role_xml).to be == role_list_2_xml
      expect(role.os_type).to be == "Windows"
      expect(role.os_version).to be == "a6dfsdfwerfdfc0bc8f24rwefsd4ds01__Windows-Server-2012-R2-20141128-en.us-127GB.vhd"
    end
  end

  describe "add_extension" do
    it "calls role update and prints success message on successful completion" do
      expect(@service.ui).to receive(:info).with(
        "Started with Chef Extension deployment on the server test-vm-01..."
      )
      expect(@service).to receive_message_chain(
        :connection, :roles, :update
      )
      expect(@service.ui).to receive(:info).with(
        "\nSuccessfully deployed Chef Extension on the server test-vm-01."
      )
      @service.add_extension(@bootstrap_azure_instance.name_args[0])
    end

    it "calls role update and raises error on unsuccessful completion" do
      expect(@service).to receive_message_chain(
        :connection, :roles, :update
      ).and_raise
      expect(Chef::Log).to receive(:error)
      expect(Chef::Log).to receive(:debug).at_least(:once)
      @service.add_extension(@bootstrap_azure_instance.name_args[0])
    end
  end

  describe "roles_update" do
    before do
      @roles = Azure::Roles.new("connection")
      @role = double("Role")
      allow(Azure::Role).to receive(:new).and_return(@role)
    end

    it "calls setup_extension and update methods of Role class" do
      expect(@role).to receive(
        :setup_extension
      ).with({}).and_return(nil)
      expect(@role).to receive(:update).with(
        @bootstrap_azure_instance.name_args[0], {}, nil
      )
      @roles.update(@bootstrap_azure_instance.name_args[0], {})
    end
  end

  describe "setup_extension" do
    before do
      @role = Azure::Role.new("connection")
      updated_role_xml = Nokogiri::XML(readFile("bootstrap_azure_role_xmls/setup_extension/updated_role.xml"))
      allow(@role).to receive(:update_role_xml_for_extension).and_return(updated_role_xml)
      @update_role_xml_for_extension = Nokogiri::XML(readFile("bootstrap_azure_role_xmls/setup_extension/update_role.xml"))
      allow(@role).to receive(:puts)
    end

    it "creates new xml for update role" do
      response = @role.setup_extension({})
      expect(response).to eq(@update_role_xml_for_extension.to_xml)
    end
  end

  describe "update_role_xml_for_extension" do
    before do
      @params = {
        chef_extension_publisher: "Chef.Bootstrap.WindowsAzure",
        chef_extension_version: "1210.12",
        chef_extension_public_param: "MyPublicParamsValue",
        chef_extension_private_param: "MyPrivateParamsValue",
        azure_dns_name: Chef::Config[:knife][:azure_dns_name],
      }
      @role = Azure::Role.new("connection")
    end

    context "ResourceExtensionReferences node is not present in role xml" do
      before do
        @input_role_1_xml = Nokogiri::XML(readFile("bootstrap_azure_role_xmls/update_role_xml_for_extension/input_role_1.xml"))
        @output_role_1_xml = Nokogiri::XML(readFile("bootstrap_azure_role_xmls/update_role_xml_for_extension/output_role_1.xml"))
        @params[:chef_extension] = "LinuxChefClient"
      end

      it "adds ResourceExtensionReferences node with ChefExtension config" do
        response = @role.update_role_xml_for_extension(@input_role_1_xml.at_css("Role"), @params)
        expect(response.to_xml).to eq(@output_role_1_xml.at_css("Role").to_xml)
      end
    end

    context "ResourceExtensionReferences node is present in xml but it is empty" do
      before do
        @input_role_2_xml = Nokogiri::XML(readFile("bootstrap_azure_role_xmls/update_role_xml_for_extension/input_role_2.xml"))
        @output_role_2_xml = Nokogiri::XML(readFile("bootstrap_azure_role_xmls/update_role_xml_for_extension/output_role_2.xml"))
        @params[:chef_extension] = "ChefClient"
      end

      it "updates ResourceExtensionReferences node with ChefExtension config" do
        response = @role.update_role_xml_for_extension(@input_role_2_xml.at_css("Role"), @params)
        expect(response.to_xml).to eq(@output_role_2_xml.at_css("Role").to_xml)
      end
    end

    context "ResourceExtensionReferences node is present in role xml but ChefExtension is not installed on the server" do
      before do
        @input_role_3_xml = Nokogiri::XML(readFile("bootstrap_azure_role_xmls/update_role_xml_for_extension/input_role_3.xml"))
        @output_role_3_xml = Nokogiri::XML(readFile("bootstrap_azure_role_xmls/update_role_xml_for_extension/output_role_3.xml"))
        @params[:chef_extension] = "ChefClient"
      end

      it "adds ChefExtension config in ResourceExtensionReferences node" do
        response = @role.update_role_xml_for_extension(@input_role_3_xml.at_css("Role"), @params)
        expect(response.to_xml).to eq(@output_role_3_xml.at_css("Role").to_xml)
      end
    end

    context "ResourceExtensionReferences node is present in role xml and ChefExtension is already installed on the server" do
      before do
        @input_role_4_xml = Nokogiri::XML(readFile("bootstrap_azure_role_xmls/update_role_xml_for_extension/input_role_4.xml"))
        @params[:chef_extension] = "LinuxChefClient"
        @params[:azure_vm_name] = "test-vm-01"
      end

      it "raises an error with message as 'ChefExtension is already installed on the server'" do
        expect { @role.update_role_xml_for_extension(@input_role_4_xml.at_css("Role"), @params) }.to raise_error("Chef Extension is already installed on the server test-vm-01.")
      end
    end
  end

  describe "role_update" do
    before do
      @role = Azure::Role.new("connection")
      @role.connection = double("Connection")
      allow(@role).to receive(:puts)
    end

    it "does not raise error on update role success" do
      expect(@role.connection).to receive(:query_azure)
      expect(@role).to receive(:error_from_response_xml).and_return(["", ""])
      expect(Chef::Log).to_not receive(:debug)
      expect { @role.update(@bootstrap_azure_instance.name_args[0], {}, "") }.not_to raise_error
    end

    it "raises an error on update role failure" do
      expect(@role.connection).to receive(:query_azure)
      expect(@role).to receive(:error_from_response_xml)
        .and_return(["InvalidXmlRequest", "The request body's XML was invalid or not correctly specified."])
      expect(Chef::Log).to receive(:debug).at_least(:once)
      expect { @role.update(@bootstrap_azure_instance.name_args[0], {}, "") }.to raise_error("Unable to update role:InvalidXmlRequest : The request body's XML was invalid or not correctly specified.")
    end
  end

  describe "get_chef_extension_version" do
    before do
      allow(@service).to receive(:instance_of?).with(
        Azure::ResourceManagement::ARMInterface
      ).and_return(false)
      allow(@service).to receive(:instance_of?).with(
        Azure::ServiceManagement::ASMInterface
      ).and_return(true)
    end

    context "when extension version is set in knife.rb" do
      before do
        Chef::Config[:knife][:azure_chef_extension_version] = "1012.10"
      end

      it "will pick up the extension version from knife.rb" do
        response = @bootstrap_azure_instance.get_chef_extension_version("MyChefClient")
        expect(response).to be == "1012.10"
      end
    end

    context "when extension version is not set in knife.rb" do
      before do
        Chef::Config[:knife].delete(:azure_chef_extension_version)
        extensions_list_xml = Nokogiri::XML(readFile("bootstrap_azure_role_xmls/extensions_list.xml"))
        allow(@service).to receive(
          :get_extension
        ).and_return(extensions_list_xml)
      end

      it "will pick up the latest version of the extension" do
        expect(@service).to_not receive(:get_latest_chef_extension_version)
        response = @bootstrap_azure_instance.get_chef_extension_version("MyChefClient")
        expect(response).to be == "1210.*"
      end
    end
  end

  describe "wait_until_extension_available" do
    context "extension_availaibility_wait_time has exceeded the extension_availaibility_wait_timeout" do
      before do
        @start_time = Time.now
      end

      it "raises error saying unable to fetch chef-client run logs" do
        expect { @bootstrap_azure_instance.wait_until_extension_available(@start_time, -1) }.to raise_error(
          "\nUnable to fetch chef-client run logs as Chef Extension seems to be unavailable even after -1 minutes of its deployment.\n"
        )
      end
    end

    context "extension_availaibility_wait_time has not exceeded the extension_availaibility_wait_timeout" do
      context "deployment not available" do
        before do
          @start_time = Time.now
          deployment = Nokogiri::XML("")
          allow(@bootstrap_azure_instance).to receive(:fetch_deployment).and_return(deployment)
        end

        it "goes to sleep and then re-invokes the wait_until_extension_available method recursively" do
          mock_recursive_call
          expect(@bootstrap_azure_instance).to receive(:print).exactly(1).times
          expect(@bootstrap_azure_instance).to receive(:sleep).with(30)
          expect(@bootstrap_azure_instance).to receive(
            :wait_until_extension_available
          ).with(@start_time, 10)
          @bootstrap_azure_instance.wait_until_extension_available_mocked(@start_time, 10)
        end
      end

      context "deployment available" do
        context "given role not available" do
          before do
            @start_time = Time.now
            deployment = Nokogiri::XML readFile("extension_deployment_xml.xml")
            allow(@bootstrap_azure_instance).to receive(:fetch_deployment).and_return(deployment)
          end

          it "goes to sleep and then re-invokes the wait_until_extension_available method recursively" do
            mock_recursive_call
            expect(@bootstrap_azure_instance).to receive(:print).exactly(1).times
            expect(@bootstrap_azure_instance).to receive(:sleep).with(30)
            expect(@bootstrap_azure_instance).to receive(
              :wait_until_extension_available
            ).with(@start_time, 10)
            @bootstrap_azure_instance.wait_until_extension_available_mocked(@start_time, 10)
          end
        end

        context "given role available" do
          context "GuestAgent not ready" do
            before do
              @bootstrap_azure_instance.name_args = ["vm05"]
              @start_time = Time.now
              deployment = Nokogiri::XML readFile("extension_deployment_xml.xml")
              allow(@bootstrap_azure_instance).to receive(:fetch_deployment).and_return(deployment)
            end

            it "goes to sleep and then re-invokes the wait_until_extension_available method recursively" do
              mock_recursive_call
              expect(@bootstrap_azure_instance).to receive(:print).exactly(1).times
              expect(@bootstrap_azure_instance).to receive(:sleep).with(30)
              expect(@bootstrap_azure_instance).to receive(
                :wait_until_extension_available
              ).with(@start_time, 10)
              @bootstrap_azure_instance.wait_until_extension_available_mocked(@start_time, 10)
            end
          end

          context "GuestAgent ready" do
            context "none of the extension status available" do
              before do
                @bootstrap_azure_instance.name_args = ["vm06"]
                @start_time = Time.now
                deployment = Nokogiri::XML readFile("extension_deployment_xml.xml")
                allow(@bootstrap_azure_instance).to receive(:fetch_deployment).and_return(deployment)
              end

              it "goes to sleep and then re-invokes the wait_until_extension_available method recursively" do
                mock_recursive_call
                expect(@bootstrap_azure_instance).to receive(:print).exactly(1).times
                expect(@bootstrap_azure_instance).to receive(:sleep).with(30)
                expect(@bootstrap_azure_instance).to receive(
                  :wait_until_extension_available
                ).with(@start_time, 10)
                @bootstrap_azure_instance.wait_until_extension_available_mocked(@start_time, 10)
              end
            end

            context "extension status(es) available apart from extension status for Chef Extension" do
              context "example-1" do
                before do
                  @bootstrap_azure_instance.name_args = ["vm01"]
                  @start_time = Time.now
                  deployment = Nokogiri::XML readFile("extension_deployment_xml.xml")
                  allow(@bootstrap_azure_instance).to receive(:fetch_deployment).and_return(deployment)
                end

                it "goes to sleep and then re-invokes the wait_until_extension_available method recursively" do
                  mock_recursive_call
                  expect(@bootstrap_azure_instance).to receive(:print).exactly(1).times
                  expect(@bootstrap_azure_instance).to receive(:sleep).with(30)
                  expect(@bootstrap_azure_instance).to receive(
                    :wait_until_extension_available
                  ).with(@start_time, 10)
                  @bootstrap_azure_instance.wait_until_extension_available_mocked(@start_time, 10)
                end
              end

              context "example-2" do
                before do
                  @bootstrap_azure_instance.name_args = ["vm07"]
                  @start_time = Time.now
                  deployment = Nokogiri::XML readFile("extension_deployment_xml.xml")
                  allow(@bootstrap_azure_instance).to receive(:fetch_deployment).and_return(deployment)
                end

                it "goes to sleep and then re-invokes the wait_until_extension_available method recursively" do
                  mock_recursive_call
                  expect(@bootstrap_azure_instance).to receive(:print).exactly(1).times
                  expect(@bootstrap_azure_instance).to receive(:sleep).with(30)
                  expect(@bootstrap_azure_instance).to receive(
                    :wait_until_extension_available
                  ).with(@start_time, 10)
                  @bootstrap_azure_instance.wait_until_extension_available_mocked(@start_time, 10)
                end
              end
            end

            context "extension status(es) available including extension status for Chef Extension" do
              context "example-1" do
                before do
                  @bootstrap_azure_instance.name_args = ["vm02"]
                  @start_time = Time.now
                  deployment = Nokogiri::XML readFile("extension_deployment_xml.xml")
                  allow(@bootstrap_azure_instance).to receive(:fetch_deployment).and_return(deployment)
                end

                it "does not go to sleep and does not re-invoke the wait_until_extension_available method recursively" do
                  mock_recursive_call
                  expect(@bootstrap_azure_instance).to_not receive(:print)
                  expect(@bootstrap_azure_instance).to_not receive(:sleep).with(30)
                  expect(@bootstrap_azure_instance).to_not receive(
                    :wait_until_extension_available
                  ).with(@start_time, 10)
                  @bootstrap_azure_instance.wait_until_extension_available_mocked(@start_time, 10)
                end
              end

              context "example-2" do
                before do
                  @bootstrap_azure_instance.name_args = ["vm03"]
                  @start_time = Time.now
                  deployment = Nokogiri::XML readFile("extension_deployment_xml.xml")
                  allow(@bootstrap_azure_instance).to receive(:fetch_deployment).and_return(deployment)
                end

                it "does not go to sleep and does not re-invoke the wait_until_extension_available method recursively" do
                  mock_recursive_call
                  expect(@bootstrap_azure_instance).to_not receive(:print)
                  expect(@bootstrap_azure_instance).to_not receive(:sleep).with(30)
                  expect(@bootstrap_azure_instance).to_not receive(
                    :wait_until_extension_available
                  ).with(@start_time, 10)
                  @bootstrap_azure_instance.wait_until_extension_available_mocked(@start_time, 10)
                end
              end

              context "example-3" do
                before do
                  @bootstrap_azure_instance.name_args = ["vm08"]
                  @start_time = Time.now
                  deployment = Nokogiri::XML readFile("extension_deployment_xml.xml")
                  allow(@bootstrap_azure_instance).to receive(:fetch_deployment).and_return(deployment)
                end

                it "does not go to sleep and does not re-invoke the wait_until_extension_available method recursively" do
                  mock_recursive_call
                  expect(@bootstrap_azure_instance).to_not receive(:print)
                  expect(@bootstrap_azure_instance).to_not receive(:sleep).with(30)
                  expect(@bootstrap_azure_instance).to_not receive(
                    :wait_until_extension_available
                  ).with(@start_time, 10)
                  @bootstrap_azure_instance.wait_until_extension_available_mocked(@start_time, 10)
                end
              end
            end
          end
        end
      end
    end
  end

  describe "fetch_deployment" do
    before do
      allow(@bootstrap_azure_instance.service).to receive(
        :deployment_name
      ).and_return("deploymentExtension")
      deployment = Nokogiri::XML readFile("extension_deployment_xml.xml")
      allow(@bootstrap_azure_instance.service).to receive(
        :deployment
      ).and_return(deployment)
    end

    it "returns the deployment" do
      response = @bootstrap_azure_instance.fetch_deployment
      expect(response).to_not be nil
      expect(response.at_css("Deployment Name").text).to be == "deploymentExtension"
      expect(response.css("RoleInstanceList RoleInstance RoleName").class).to be == Nokogiri::XML::NodeSet
      expect(response.css("RoleInstanceList RoleInstance RoleName").children.count).to be == 8
    end
  end

  def mock_recursive_call
    @bootstrap_azure_instance.instance_eval do
      class << self
        alias wait_until_extension_available_mocked wait_until_extension_available
      end
    end
  end
end
