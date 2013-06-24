# Copyright: Copyright (c) 2012 Opscode, Inc.
# License: Apache License, Version 2.0
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

# Author:: Siddheshwar More (<siddheshwar.more@clogeny.com>)

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def get_gem_file_name
  "knife-azure-" + Knife::Azure::VERSION + ".gem"
end

def append_azure_creds(is_list_cmd = false, is_identity_file = false, is_publishsettings_file= false)
  azure_config = YAML.load(File.read(File.expand_path("../config/environment.yml", __FILE__)))
  
  if(is_publishsettings_file)
    azure_creds_cmd = " --azure-publish-settings-file #{temp_dir}/azure.publishsettings"
  else
    azure_creds_cmd = " --azure-subscription-id #{azure_config['development']['azure_subscription_id']} --azure-api-host-name #{azure_config['development']['azure_api_host_name']}"
    azure_creds_cmd = azure_creds_cmd + " --azure-mgmt-cert #{temp_dir}/ManagementCertificate.pem"
  end

  azure_creds_cmd = azure_creds_cmd + " --config #{temp_dir}/knife.rb"
  
  azure_creds_cmd = azure_creds_cmd + " --azure-service-location #{azure_config['development']['azure_service_location']}" if !is_list_cmd
  
  azure_creds_cmd = azure_creds_cmd + " --identity-file #{temp_dir}/id_rsa" if is_identity_file
  
  azure_creds_cmd
end

def append_azure_creds_for_linux(*options)

  is_list_cmd = options.include?(:is_list_cmd) ? true : false
  is_ssh_user = options.include?(:is_ssh_user) ? false : true
  is_ssh_password = options.include?(:is_ssh_password) ? true : false
  is_identity_file = options.include?(:is_identity_file) ?  false : true
  is_publishsettings_file = options.include?(:is_publishsettings_file) ?  true : false
  
  azure_config = YAML.load(File.read(File.expand_path("../config/environment.yml", __FILE__)))
  azure_creds_cmd = append_azure_creds(is_list_cmd, is_identity_file, is_publishsettings_file)
  azure_creds_cmd = azure_creds_cmd + " --ssh-user #{azure_config['development']['ssh_user']}" if is_ssh_user
  azure_creds_cmd = azure_creds_cmd + " --ssh-password #{azure_config['development']['ssh_password']}" if is_ssh_password
  azure_creds_cmd
end

def append_azure_creds_for_windows(*options)
  
  is_list_cmd = options.include?(:is_list_cmd) ? true : false
  is_winrm_user = options.include?(:is_winrm_user) ? false : true
  is_winrm_password = options.include?(:is_winrm_password) ? false : true
  is_identity_file = options.include?(:is_identity_file) ?  true : false
  is_publishsettings_file = options.include?(:is_publishsettings_file) ?  true : false
  
  azure_config = YAML.load(File.read(File.expand_path("../config/environment.yml", __FILE__)))
  azure_creds_cmd = append_azure_creds(is_list_cmd, is_identity_file, is_publishsettings_file)
  azure_creds_cmd = azure_creds_cmd + " --winrm-user #{azure_config['development']['winrm_user']}" if is_winrm_user
  azure_creds_cmd = azure_creds_cmd + " --winrm-password #{azure_config['development']['winrm_password']}" if is_winrm_password
  azure_creds_cmd
end

def delete_instance_cmd(vm_name)
  "knife azure server delete #{vm_name}" 
end

def create_node_name()
  @name_node  = "azure-#{SecureRandom.hex(4)}"
end

def create_dns_name()
  @dns_name  = "dns-#{SecureRandom.hex(4)}"
end

def create_vm_name()
  @vm_name  = "vm-#{SecureRandom.hex(4)}"
end

def init_azure_test
  require 'nokogiri'
  require 'base64'
  require 'openssl'
  require 'uri'
  
  init_test

  begin
    data_to_write = File.read(File.expand_path("../config/azure.publishsettings", __FILE__))
    File.open("#{temp_dir}/azure.publishsettings", 'w') {|f| f.write(data_to_write)}
  rescue
    puts "Error while creating file - Publishsettings file"
  end

  begin
    data_to_write = File.read(File.expand_path("../config/id_rsa", __FILE__))
    File.open("#{temp_dir}/id_rsa", 'w') {|f| f.write(data_to_write)}
  rescue
    puts "Error while creating file - identity_file"
  end

  begin
    doc = Nokogiri::XML(File.open("#{temp_dir}/azure.publishsettings"))
    profile = doc.at_css("PublishProfile")
    subscription = profile.at_css("Subscription")
    #check given PublishSettings XML file format.Currently PublishSettings file have two different XML format
    if profile.attribute("SchemaVersion").nil?
      management_cert = OpenSSL::PKCS12.new(Base64.decode64(profile.attribute("ManagementCertificate").value))
    elsif profile.attribute("SchemaVersion").value == "2.0"
      management_cert = OpenSSL::PKCS12.new(Base64.decode64(subscription.attribute("ManagementCertificate").value))
    else
      ui.error("Publish settings file Schema not supported - " + filename)
    end

    File.open("#{temp_dir}/ManagementCertificate.pem", 'w') {|f| f.write(management_cert.certificate.to_pem + management_cert.key.to_pem)}
  rescue
    ui.error("Incorrect publish settings file - " + filename)
    exit 1
  end
end

describe 'knife-azure' do
  include KnifeTestBed
  include RSpec::KnifeTestUtils
  before(:all) { init_azure_test }
  after(:all) { cleanup_test_data }
  context 'gem' do
    context 'build' do
      let(:command) { "gem build knife-azure.gemspec" }
      it 'should succeed' do
        match_status("should succeed")
      end
    end

    context 'install ' do
      let(:command) { "gem install " + get_gem_file_name  }
      it 'should succeed' do
        match_status("should succeed")
      end
    end

    describe 'knife' do
      context 'azure' do
        context 'image list --help' do
         let(:command) { "knife azure image list --help" }
           it 'should succeed' do
            match_stdout(/--help/)
          end
        end
      end
    end

    describe 'knife' , :if => is_config_present do
      context 'server' do
       before(:all) { create_dns_name }
        context 'create Windows VM by using standard and --azure-dns-name option' do
          let(:command) { "knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds_for_windows + ' --azure-source-image "clogeny_win2k8_winrm_enabled"' + " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" + " --yes" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'delete Windows server by using server name and standard option' do
          let(:command) { delete_instance_cmd(@dns_name) + append_azure_creds(is_list_cmd = true) + " --yes" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end
      end

      context 'server' do
        before(:all) { create_dns_name }
        context 'create Linux VM by using standard and --azure-dns-name option' do
          let(:command) { "knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds_for_linux + ' --azure-source-image "b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-12_10-amd64-server-20130414-en-us-30GB"' + " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" + " --yes" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'delete Linux server by using server name and standard option' do
          let(:command) { delete_instance_cmd(@dns_name) + append_azure_creds(is_list_cmd = true) + " --yes" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end
      end

      context 'server' do
        before(:all) { create_dns_name }
        context 'create Windows VM by using publishsettings file and  --azure-dns-name option' do
          let(:command) { "knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds_for_windows(:is_publishsettings_file) + ' --azure-source-image "clogeny_win2k8_winrm_enabled"' + " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" + " --yes" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'delete Windows server by using server name and publishsettings file' do
          let(:command) { delete_instance_cmd(@dns_name) + append_azure_creds(is_list_cmd = true, is_identity_file= false, is_publishsettings_file= true ) + " --yes"}
          it 'should succeed' do
            match_status("should succeed")
          end
        end
      end

      context 'server' do
        before(:all) { create_dns_name }
        context 'create Linux VM by using publishsettings file and  --azure-dns-name option' do
          let(:command) { "knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds_for_linux(:is_publishsettings_file) + ' --azure-source-image "b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-12_10-amd64-server-20130414-en-us-30GB"' + " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" + " --yes" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'delete Linux server by using server name and publishsettings file' do
          let(:command) { delete_instance_cmd(@dns_name) + append_azure_creds(is_list_cmd = true, is_identity_file= false, is_publishsettings_file= true ) + " --yes" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end
      end

      context 'server' do
        before(:all) { create_dns_name; create_vm_name }
        context 'create Windows VM by using standard option for azure-connect-to-existing-dns' do
          let(:command) { "knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds_for_windows + ' --azure-source-image "clogeny_win2k8_winrm_enabled"' + " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" + " --yes" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'create Windows VM by using standard option and connect-to-existing-dns' do
          let(:command) { "knife azure server create --azure-vm-name #{@vm_name} --azure-dns-name #{@dns_name}" + append_azure_creds_for_windows + ' --azure-source-image "clogeny_win2k8_winrm_enabled"' + " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" + " --yes --azure-connect-to-existing-dns" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'delete Windows server, Chef node, Chef client by using --purge' do
          let(:command) { delete_instance_cmd(@dns_name) + append_azure_creds(is_list_cmd = true) + " --yes --purge" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'delete Windows server, Chef node, Chef client by using --purge and preserve dns' do
          let(:command) { delete_instance_cmd(@vm_name) + append_azure_creds(is_list_cmd = true) + " --yes --purge --preserve-azure-dns-name"}
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'create Windows VM by using standard option and connect-to-existing-dns and over write default winrm port ' do
          after(:each)  { run(delete_instance_cmd(@vm_name) + append_azure_creds(is_list_cmd = true) + " --yes --purge --preserve-azure-dns-name") }
          let(:command) { "knife azure server create --azure-vm-name #{@vm_name} --azure-dns-name #{@dns_name}" + append_azure_creds_for_windows + ' --azure-source-image "clogeny_win2k8_winrm_enabled"' + " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" + " --winrm-port 5682 --yes --azure-connect-to-existing-dns" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'create Windows VM by using standard option and connect-to-existing-dns and having duplicate winrm port' do
          before(:each) {run ("knife azure server create --azure-vm-name #{@dns_name} --azure-dns-name #{@dns_name}" + append_azure_creds_for_windows + ' --azure-source-image "clogeny_win2k8_winrm_enabled"' + " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" + " --winrm-port 5682 --yes --azure-connect-to-existing-dns")}
          after(:each)  { run(delete_instance_cmd(@dns_name) + append_azure_creds(is_list_cmd = true) + " --yes --purge")}
          let(:command) { "knife azure server create --azure-vm-name #{@vm_name} --azure-dns-name #{@dns_name}" + append_azure_creds_for_windows + ' --azure-source-image "clogeny_win2k8_winrm_enabled"' + " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" + " --winrm-port 5682 --yes --azure-connect-to-existing-dns" }
          it 'should fail' do
            match_status("should fail")
          end
        end

        context 'create Windows VM by using standard option and connect-to-existing-dns and having out of range winrm port' do
          let(:command) { "knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds_for_windows + ' --azure-source-image "clogeny_win2k8_winrm_enabled"' + " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" + " --winrm-port 90000 --yes" }
          it 'should fail' do
            match_status("should fail")
          end
        end
      end

      context 'server' do
        before(:all) { create_dns_name; }
        before(:each) {run ("knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds_for_windows(:is_publishsettings_file) + ' --azure-source-image "clogeny_win2k8_winrm_enabled"' + " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" + " --yes")}
        after(:each) {run(delete_instance_cmd(@dns_name) + append_azure_creds(is_list_cmd = true, is_identity_file= false, is_publishsettings_file= true ) + " --yes --purge")}
        context 'create Windows VM by using publishsettings file and having duplicate dns name option' do
          let(:command) { "knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds_for_windows(:is_publishsettings_file) + ' --azure-source-image "clogeny_win2k8_winrm_enabled"' + " --template-file " + get_windows_msi_template_file_path + " --server-url http://localhost:8889" + " --yes" }
          it 'should fail' do
            match_status("should fail")
          end
        end
      end

      context 'server' do
        before(:all) { create_dns_name; create_vm_name }
        context 'create Linux VM by using standard option for azure-connect-to-existing-dns' do
          let(:command) { "knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds_for_linux + ' --azure-source-image "b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-12_10-amd64-server-20130414-en-us-30GB"' + " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" + " --yes" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'create Linux VM by using standard option and connect-to-existing-dns' do
          let(:command) { "knife azure server create --azure-vm-name #{@vm_name} --azure-dns-name #{@dns_name}" + append_azure_creds_for_linux + ' --azure-source-image "b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-12_10-amd64-server-20130414-en-us-30GB"' + " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" + " --yes --azure-connect-to-existing-dns" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'delete Linux server, Chef node, Chef client by using --purge' do
          let(:command) { delete_instance_cmd(@dns_name) + append_azure_creds(is_list_cmd = true) + " --yes --purge" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'delete Linux server, Chef node, Chef client by using --purge and preserve dns' do
          let(:command) { delete_instance_cmd(@vm_name) + append_azure_creds(is_list_cmd = true) + " --yes --purge --preserve-azure-dns-name"}
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'create Linux VM by using standard option and connect-to-existing-dns and over write default ssh port ' do
          after(:each)  { run(delete_instance_cmd(@vm_name) + append_azure_creds(is_list_cmd = true) + " --yes --purge --preserve-azure-dns-name") }
          let(:command) { "knife azure server create --azure-vm-name #{@vm_name} --azure-dns-name #{@dns_name}" + append_azure_creds_for_linux + ' --azure-source-image "b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-12_10-amd64-server-20130414-en-us-30GB"' + " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" + " --ssh-port 3245 --yes --azure-connect-to-existing-dns" }
          it 'should succeed' do
            match_status("should succeed")
          end
        end

        context 'create Linux VM by using standard option and connect-to-existing-dns having duplicate ssh port ' do
          before(:each) {run("knife azure server create --azure-vm-name #{@dns_name} --azure-dns-name #{@dns_name}" + append_azure_creds_for_linux + ' --azure-source-image "b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-12_10-amd64-server-20130414-en-us-30GB"' + " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" + " --ssh-port 245 --yes --azure-connect-to-existing-dns")}
          after(:each)  { run(delete_instance_cmd(@dns_name) + append_azure_creds(is_list_cmd = true) + " --yes --purge")}

          let(:command) { "knife azure server create --azure-vm-name #{@vm_name} --azure-dns-name #{@dns_name}" + append_azure_creds_for_linux + ' --azure-source-image "b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-12_10-amd64-server-20130414-en-us-30GB"' + " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" + " --ssh-port 245 --yes --azure-connect-to-existing-dns" }
          it 'should fail' do
            match_status("should fail")
          end
        end

        context 'create Linux VM by using standard option and connect-to-existing-dns having out of range ssh port' do
          let(:command) { "knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds_for_linux + ' --azure-source-image "b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-12_10-amd64-server-20130414-en-us-30GB"' + " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" + " --ssh-port 900000 --yes" }
          it 'should fail' do
            match_status("should fail")
          end
        end
      end

      context 'server' do
        before(:all) { create_dns_name; }
        before(:each) {run ("knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds_for_linux(:is_publishsettings_file) + ' --azure-source-image "b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-12_10-amd64-server-20130414-en-us-30GB"' + " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" + " --yes")}
        after(:each) {run(delete_instance_cmd(@dns_name) + append_azure_creds(is_list_cmd = true, is_identity_file= false, is_publishsettings_file= true ) + " --yes --purge")}
        context 'create Linux VM by using publishsettings file and having duplicate dns name option' do
          let(:command) { "knife azure server create --azure-dns-name #{@dns_name}" + append_azure_creds_for_linux(:is_publishsettings_file) + ' --azure-source-image "b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-12_10-amd64-server-20130414-en-us-30GB"' + " --template-file " + get_linux_template_file_path + " --server-url http://localhost:8889" + " --yes" }
          it 'should fail' do
            match_status("should fail")
          end
        end
      end

      context 'image list' do
        let(:command) { "knife azure image list" + append_azure_creds(is_list_cmd = true) }
        it 'should succeed' do
          match_status("should succeed")
        end
      end 

      context 'server list' do
        let(:command) { "knife azure server list" + append_azure_creds(is_list_cmd = true) }
        it 'should succeed' do
          match_status("should succeed")
        end
      end
    end
  end
end