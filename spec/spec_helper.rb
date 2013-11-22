$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rspec'
require 'equivalent-xml'
require 'azure/connection'
require 'azure/rest'
require 'azure/host'
require 'azure/image'
require 'azure/deploy'
require 'azure/role'
require 'azure/disk'
require 'azure/utility'

require 'chef/knife/azure_ag_create'
require 'chef/knife/azure_ag_list'
require 'chef/knife/azure_image_list'
require 'chef/knife/azure_server_create'
require 'chef/knife/azure_server_delete'
require 'chef/knife/azure_server_describe'
require 'chef/knife/azure_server_list'
require 'chef/knife/azure_vnet_create'
require 'chef/knife/azure_vnet_list'

require 'fileutils'
require "securerandom"
require 'knife-azure/version'

def temp_dir
  @_temp_dir ||= Dir.mktmpdir
end

def tmpFile filename
  temp_dir + "/" + filename
end

RSpec.configure do |c|
  c.before(:each) do
    Chef::Config.reset
  end
  
  c.before(:all) do
    #Create an empty mock certificate file
    @cert_file = tmpFile('AzureLinuxCert.pem')
    FileUtils.touch(@cert_file)
    Chef::Log.init(tmpFile('debug.log'), 'daily')
    Chef::Log.level=:debug
  end

  c.after(:all) do
    #Cleanup files and dirs
    FileUtils.rm_rf("#{temp_dir}")
  end
end

TEST_PARAMS = {
  :azure_subscription_id => "YOUR_SUBSCRIPTION_ID_HERE",
  :azure_mgmt_cert => @cert_file,
  :azure_api_host_name => "management-preview.core.windows-int.net",
}

module AzureSpecHelper
  def readFile filename
    File.read(File.dirname(__FILE__) + "/unit/assets/#{filename}")
  end

  def get_publish_settings_file_path filename
    File.dirname(__FILE__) + "/unit/assets/publish-settings-files/#{filename}"
  end
end

def is_config_present 
  is_config_present = File.exist?(File.expand_path("../integration/config/environment.yml", __FILE__)) 
  if(!is_config_present)
    puts "\nSkipping the integration tests for knife azure commands"
    puts "\nPlease make sure environment.yml is present and set with valid credentials."
    puts "\nPlease look for a sample file at spec/integration/config/environment.yml.sample"
    puts "\nPlease make sure azure.publishsettings file is present and set with valid key pair content."
    puts "\nPlease make sure identity file id_rsa is present and set with valid key pair content."
  end
  is_config_present
end
