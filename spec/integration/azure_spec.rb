#
# Author:: Siddheshwar More (<siddheshwar.more@clogeny.com>)
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

def append_azure_creds(*options)
  is_publishsettings_file = options.include?("publishsettings_file") ? true : false
  is_list_cmd = options.include?("list_cmd") ? true : false

  if is_publishsettings_file
    azure_creds_cmd = " --azure-publish-settings-file '#{ENV["AZURE_PUBLISH_SETTINGS_FILE"]}'"
  else
    azure_creds_cmd = " --azure-subscription-id '#{ENV["AZURE_SUBSCRIPTION_ID"]}' --azure-api-host-name '#{ENV["AZURE_API_HOST_NAME"]}' --azure-mgmt-cert '#{ENV["AZURE_MGMT_CERT"]}'"
  end

  azure_creds_cmd += " --config #{temp_dir}/knife.rb"

  azure_creds_cmd += " --azure-service-location #{@azure_service_location}" unless is_list_cmd

  azure_creds_cmd
end

def get_ssh_credentials
  " --connection-user #{@az_ssh_user} --connection-password #{@az_ssh_password}"
end

def get_winrm_credentials
  " --connection-user #{@az_winrm_user} --connection-password #{@az_winrm_password}"
end

def get_ssh_credentials_for_windows_image
  " --connection-user #{@az_windows_ssh_user} --connection-password #{@az_windows_ssh_password}"
end

# get azure active instance_id for knife azure show command run
def get_active_instance_id
  server_list_output = run("knife azure server list " + append_azure_creds("list_cmd"))
  # Check command exitstatus. Non zero exitstatus indicates command execution fails.
  if server_list_output.exitstatus != 0
    puts "Please check azure config is correct. Error: #{list_output.stderr}."
    return false
  else
    servers = server_list_output.stdout
  end

  servers.each_line do |line|
    if line.include?("ready")
      instance_id = line.split(" ")[1]
      return instance_id
    end
  end
  false
end

def create_dns_name
  @dns_name = "az-testdns#{SecureRandom.hex(2)}"
end

def create_vm_name(name = "linux")
  @vm_name = (name == "linux") ? "az-testlnx#{SecureRandom.hex(2)}" : "az-testwin#{SecureRandom.hex(2)}"
end

describe "knife-azure integration test", if: is_config_present do
  include KnifeTestBed
  include RSpec::KnifeTestUtils

  before(:all) do
    expect(run("gem build knife-azure.gemspec").exitstatus).to be(0)
    expect(run("gem install #{get_gem_file_name}").exitstatus).to be(0)
    init_azure_test
  end

  after(:all) do
    run("gem uninstall knife-azure -v '#{Knife::Azure::VERSION}'")
    cleanup_test_data
  end

  describe "display help for command" do
    %w{server\ create server\ delete server\ list image\ list server\ show vnet\ create vnet\ list ag\ create ag\ list}.each do |command|
      context "when --help option used with #{command} command" do
        let(:command) { "knife azure #{command} --help" }
        run_cmd_check_stdout("--help")
      end
    end
  end

  describe "display server list" do
    context "when standard options specified" do
      let(:command) { "knife azure server list" + append_azure_creds("list_cmd") }
      run_cmd_check_status_and_output("succeed", "VM Name")
    end
  end

  describe "display image list" do
    context "when standard options specified" do
      let(:command) { "knife azure image list" + append_azure_creds("list_cmd") }
      run_cmd_check_status_and_output("succeed", "Name")
    end
  end

  describe "display vnet list" do
    context "when standard options specified" do
      let(:command) { "knife azure vnet list" + append_azure_creds("list_cmd") }
      run_cmd_check_status_and_output("succeed", "Name")
    end
  end

  describe "display ag list" do
    context "when standard options specified" do
      let(:command) { "knife azure ag list" + append_azure_creds("list_cmd") }
      run_cmd_check_status_and_output("succeed", "Name")
    end
  end

  describe "server show" do
    context "with valid instance_id" do
      before(:each) do
        @instance_id = get_active_instance_id
      end
      let(:command) { "knife azure server show #{@instance_id}" + append_azure_creds("list_cmd") }
      run_cmd_check_status_and_output("succeed", "Role name")
    end
  end

  describe "create and bootstrap Linux Server" do
    before(:each) { rm_known_host }
    context "when standard options specified and --azure-dns-name option" do
      before(:all) { create_dns_name }

      let(:command) do
        "knife azure server create --azure-dns-name #{@dns_name}" +
          append_azure_creds + " --azure-source-image #{@az_linux_image}" + get_ssh_credentials +
          " --template-file " + get_linux_template_file_path +
          " --server-url http://localhost:8889" + " --yes"
      end
      run_cmd_check_status_and_output("succeed", "#{@dns_name}")
    end

    context "delete Linux server by using server name and standard option" do
      let(:command) { delete_instance_cmd(@dns_name) + append_azure_creds("list_cmd") }
      run_cmd_check_status_and_output("succeed", "#{@dns_name}")
    end

    context "when publishsettings file specified and --azure-dns-name option" do
      before(:all) { create_dns_name }

      let(:command) do
        "knife azure server create --azure-dns-name #{@dns_name}" +
          append_azure_creds("publishsettings_file") + " --azure-source-image #{@az_linux_image}" +
          " --template-file " + get_linux_template_file_path + get_ssh_credentials +
          " --server-url http://localhost:8889" + " --yes"
      end

      run_cmd_check_status_and_output("succeed", "#{@dns_name}")
    end

    context "delete Linux server by using server name and publishsettings file" do
      let(:command) { delete_instance_cmd(@dns_name) + append_azure_creds("publishsettings_file", "list_cmd") }
      run_cmd_check_status_and_output("succeed", "#{@dns_name}")
    end

    context "skip user specified --tcp-endpoints if its external port is same as ssh external port" do
      before(:all) { create_dns_name }
      after(:all) { run(delete_instance_cmd + append_azure_creds("list_cmd")) }
      let(:command) do
        "knife azure server create --azure-dns-name #{@dns_name}" +
          append_azure_creds("publishsettings_file") + get_ssh_credentials +
          " --azure-source-image #{@az_linux_image}" + " --template-file " +
          get_linux_template_file_path + " --server-url http://localhost:8889" +
          " --tcp-endpoints 22:22,1234:1234" + " --yes"
      end

      run_cmd_check_status_and_output("succeed", "#{@dns_name}")
    end

    context "when azure-connect-to-existing-dns option" do
      before(:all) { create_dns_name; create_vm_name }
      context "create Linux VM for azure-connect-to-existing-dns" do
        let(:command) do
          "knife azure server create --azure-dns-name #{@dns_name}" +
            append_azure_creds + " --azure-source-image #{@az_linux_image}" + get_ssh_credentials +
            " --template-file " + get_linux_template_file_path +
            " --server-url http://localhost:8889" + " --yes"
        end
        run_cmd_check_status_and_output("succeed", "#{@dns_name}")
      end

      context "create Linux VM by using standard option and connect-to-existing-dns" do
        let(:command) do
          "knife azure server create --azure-vm-name #{@vm_name} --azure-dns-name #{@dns_name}" +
            append_azure_creds + " --azure-source-image #{@az_linux_image}" + get_ssh_credentials +
            " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" +
            " --yes --azure-connect-to-existing-dns"
        end
        run_cmd_check_status_and_output("succeed", "#{@vm_name}")
      end

      context "delete Linux server, Chef node, Chef client by using --purge" do
        let(:command) do
          delete_instance_cmd(@dns_name) +
            append_azure_creds("list_cmd") + " --purge"
        end
        run_cmd_check_status_and_output("succeed", "#{@dns_name}")
      end

      context "delete Linux server, Chef node, Chef client by using --purge and preserve dns" do
        let(:command) do
          delete_instance_cmd(@vm_name) +
            append_azure_creds("list_cmd") + " --yes --purge --preserve-azure-dns-name"
        end
        run_cmd_check_status_and_output("succeed", "#{@vm_name}")
      end

      context "when having duplicate ssh port " do
        before(:each) do
          run("knife azure server create --azure-vm-name #{@dns_name} --azure-dns-name #{@dns_name}" + append_azure_creds + " --azure-source-image #{@az_linux_image}" + get_ssh_credentials +
         " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" +
         " --connection-port 245 --yes --azure-connect-to-existing-dns")
        end

        after(:each)  { run(delete_instance_cmd(@dns_name) + append_azure_creds("list_cmd") + " --purge") }

        let(:command) do
          "knife azure server create --azure-vm-name #{@vm_name} --azure-dns-name #{@dns_name}" +
            append_azure_creds + " --azure-source-image #{@az_linux_image}" + get_ssh_credentials +
            " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" +
            " --connection-port 245 --yes --azure-connect-to-existing-dns"
        end
        run_cmd_check_status_and_output("fail", "")
      end

      context "when having out of range ssh port" do
        let(:command) do
          "knife azure server create --azure-dns-name #{@dns_name}" +
            append_azure_creds + " --azure-source-image #{@az_linux_image}" +
            " --template-file " + get_linux_template_file_path + get_ssh_credentials +
            " --server-url http://localhost:8889" + " --connection-port 900000 --yes"
        end
        run_cmd_check_status_and_output("fail", "")
      end

      context "when having duplicate dns name option" do
        let(:command) do
          "knife azure server create --azure-dns-name #{@dns_name}" +
            append_azure_creds("publishsettings_file") + " --azure-source-image #{@az_linux_image}" +
            " --template-file " + get_linux_template_file_path + get_ssh_credentials +
            " --server-url http://localhost:8889" + " --yes"
        end
        run_cmd_check_status_and_output("fail", "")
      end

      context "when standard option and over write default ssh port " do
        after(:each)  { run(delete_instance_cmd(@vm_name) + append_azure_creds("list_cmd")) }

        let(:command) do
          "knife azure server create --azure-vm-name #{@vm_name} --azure-dns-name #{@dns_name}" +
            append_azure_creds + " --azure-source-image #{@az_linux_image}" + get_ssh_credentials +
            " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" +
            " --connection-port 3245 --yes --azure-connect-to-existing-dns"
        end

        run_cmd_check_status_and_output("succeed", "#{@vm_name}")
      end
    end
  end

  describe "create and bootstrap Windows Server" do
    before(:each) { rm_known_host }

    context "create Windows VM by using standard and --azure-dns-name option" do
      before(:all) { create_dns_name }
      let(:command) do
        "knife azure server create --azure-dns-name #{@dns_name}" +
          append_azure_creds + " --azure-source-image #{@az_windows_image}" + get_winrm_credentials +
          " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" + " --yes"
      end

      run_cmd_check_status_and_output("succeed", @dns_name)
    end

    context "delete Windows server by using server name and standard option" do
      let(:command) { delete_instance_cmd(@dns_name) + append_azure_creds("list_cmd") }
      run_cmd_check_status_and_output("succeed", "#{@dns_name}")
    end

    context "create Windows VM by using publishsettings file and skip user specified --tcp-endpoints if its external port is same as winrm external port" do
      before(:all) { create_dns_name }
      after(:each) { run(delete_instance_cmd(@dns_name) + append_azure_creds("list_cmd")) }
      let(:command) do
        "knife azure server create --azure-dns-name #{@dns_name}" +
          append_azure_creds("publishsettings_file") + " --azure-source-image #{@az_windows_image}" +
          get_winrm_credentials + " --template-file " + get_windows_msi_template_file_path +
          " --server-url http://localhost:8889" + " --tcp-endpoints 5985:5985,1234:1234" + " --yes"
      end

      run_cmd_check_status_and_output("succeed", "#{@dns_name}")
    end

    context "when azure-connect-to-existing-dns" do
      before(:all) { create_dns_name; create_vm_name("windows") }

      context "create Windows VM for azure-connect-to-existing-dns" do

        let(:command) do
          "knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds +
            " --azure-source-image #{@az_windows_image}" + " --template-file " + get_windows_msi_template_file_path +
            " --server-url http://localhost:8889" + get_winrm_credentials + " --yes"
        end
        run_cmd_check_status_and_output("succeed", "#{@dns_name}")
      end

      context "create Windows VM by using standard option and connect-to-existing-dns and having duplicate winrm port" do
        after(:each)  do
          run(delete_instance_cmd(@dns_name) + append_azure_creds("list_cmd") +
        " --purge --preserve-azure-dns-name")
        end
        let(:command) do
          "knife azure server create --azure-vm-name #{@vm_name} --azure-dns-name #{@dns_name}" +
            append_azure_creds + " --azure-source-image #{@az_windows_image}" + get_winrm_credentials +
            " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" +
            " --connection-port 5682 --yes --azure-connect-to-existing-dns"
        end
        run_cmd_check_status_and_output("fail", "")
      end

      context "create Windows VM by using standard option and connect-to-existing-dns and over write default winrm port " do
        after(:each)  { run(delete_instance_cmd(@vm_name) + append_azure_creds("list_cmd")) }
        let(:command) do
          "knife azure server create --azure-vm-name #{@vm_name} --azure-dns-name #{@dns_name}" + append_azure_creds_for_windows + " --azure-source-image #{@az_windows_image}" + get_winrm_credentials +
            " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" + " --connection-port 5682 --yes --azure-connect-to-existing-dns"
        end
        run_cmd_check_status_and_output("succeed", "#{@vm_name}")
      end
    end
  end
end
