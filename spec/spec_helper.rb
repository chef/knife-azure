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

require 'chef/knife/azure_server_list'
require 'chef/knife/azure_server_delete'
require 'chef/knife/azure_server_create'
require 'chef/knife/azure_server_describe'
require 'chef/knife/azure_image_list'

require 'fileutils'
require "securerandom"
require 'knife-azure/version'
require 'test/knife-utils/test_bed'


#Create an empty mock certificate file
FileUtils.touch('AzureLinuxCert.pem')

def tmpFile filename
  tmpdir = 'tmp'
  Dir::mkdir tmpdir unless FileTest::directory?(tmpdir)
  tmpdir + '/' + filename
end

Chef::Log.init(tmpFile('debug.log'), 'daily')
Chef::Log.level=:debug

RSpec.configure do |c|
  c.before(:each) { Chef::Config[:knife].each do |key, value| Chef::Config[:knife].delete(key) end }
end

TEST_PARAMS = {
  :azure_subscription_id => "YOUR_SUBSCRIPTION_ID_HERE",
  :azure_mgmt_cert => "AzureLinuxCert.pem",
  :azure_api_host_name => "management-preview.core.windows-int.net",
}

module AzureSpecHelper
  def readFile filename
    File.read(File.dirname(__FILE__) + "/unit/assets/#{filename}")
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
