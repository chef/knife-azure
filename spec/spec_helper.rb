$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "chef/knife/azure_ag_create"
require "chef/knife/azure_ag_list"
require "chef/knife/azure_image_list"
require "chef/knife/azure_internal-lb_create"
require "chef/knife/azure_internal-lb_list"
require "chef/knife/azure_server_create"
require "chef/knife/azure_server_delete"
require "chef/knife/azure_server_show"
require "chef/knife/azure_server_list"
require "chef/knife/azure_vnet_create"
require "chef/knife/azure_vnet_list"

require "chef/knife/azurerm_server_list"
require "chef/knife/azurerm_server_show"
require "chef/knife/azurerm_server_delete"
require "chef/knife/azurerm_server_create"
require "chef/knife/bootstrap_azure"

require "chef/knife/bootstrap_azurerm"

if Chef::Platform.windows?
  require "azure/resource_management/windows_credentials"
end

require "fileutils"
require "securerandom"
require "knife-azure/version"

def temp_dir
  @_temp_dir ||= Dir.mktmpdir
end

def tmpFile(filename)
  temp_dir + "/" + filename
end

RSpec.configure do |c|
  c.before(:each) do
    Chef::Config.reset
  end

  c.before(:all) do
    # Create an empty mock certificate file
    @cert_file = tmpFile("AzureLinuxCert.pem")
    FileUtils.touch(@cert_file)
    Chef::Log.init(tmpFile("debug.log"))
    Chef::Log.level = :debug
  end

  c.after(:all) do
    # Cleanup files and dirs
    FileUtils.rm_rf("#{temp_dir}")
  end
end

TEST_PARAMS = {
  azure_subscription_id: "YOUR_SUBSCRIPTION_ID_HERE",
  azure_mgmt_cert: @cert_file,
  azure_api_host_name: "management-preview.core.windows-int.net",
}.freeze

module AzureSpecHelper
  def readFile(filename)
    File.read(File.dirname(__FILE__) + "/unit/assets/#{filename}")
  end

  def get_publish_settings_file_path(filename)
    File.dirname(__FILE__) + "/unit/assets/publish-settings-files/#{filename}"
  end
end

def is_config_present
  unless ENV["RUN_INTEGRATION_TESTS"]
    puts("\nPlease set RUN_INTEGRATION_TESTS environment variable to run integration tests")
    return false
  end

  unset_env_var = []
  unset_config_options = []
  is_config = true
  config_file_exist = File.exist?(File.expand_path("../integration/config/environment.yml", __FILE__))
  azure_config = YAML.load(File.read(File.expand_path("../integration/config/environment.yml", __FILE__))) if config_file_exist

  %w{AZURE_PUBLISH_SETTINGS_FILE AZURE_MGMT_CERT AZURE_SUBSCRIPTION_ID AZURE_API_HOST_NAME}.each do |az_env_var|
    if ENV[az_env_var].nil?
      unset_env_var << az_env_var
      is_config = false
    end
  end

  err_msg = "\nPlease set #{unset_env_var.join(", ")} environment"
  err_msg = err_msg + ( unset_env_var.length > 1 ? " variables " : " variable " ) + "for integration tests."
  puts err_msg unless unset_env_var.empty?

  %w{AZ_SSH_USER AZ_SSH_PASSWORD AZ_WINDOWS_SSH_USER AZ_WINDOWS_SSH_PASSWORD AZ_WINRM_USER AZ_WINRM_PASSWORD AZ_LINUX_IMAGE AZ_LINUX_VM_SIZE AZ_INVALID_VM_SIZE AZ_WINDOWS_VM_SIZE AZ_WINDOWS_IMAGE AZ_WINDOWS_SSH_IMAGE AZURE_SERVICE_LOCATION}.each do |os_config_opt|
    option_value = ENV[os_config_opt] || (azure_config[os_config_opt] if azure_config)
    if option_value.nil?
      unset_config_options << os_config_opt
      is_config = false
    end
  end

  config_err_msg = "\nPlease set #{unset_config_options.join(", ")} config"
  config_err_msg = config_err_msg + ( unset_config_options.length > 1 ? " options in ../spec/integration/config/environment.yml or as environment variables" : " option in ../spec/integration/config/environment.yml or as environment variable" ) + " for integration tests."
  puts config_err_msg unless unset_config_options.empty?

  is_config
end

def get_gem_file_name
  "knife-azure-" + Knife::Azure::VERSION + ".gem"
end

def find_instance_id(instance_name, file)
  file.lines.each do |line|
    if line.include?("#{instance_name}")
      return "#{line}".split(" ")[2].strip
    end
  end
end

def delete_instance_cmd(vm_name)
  "knife azure server delete #{vm_name}  --yes"
end

def create_node_name(name)
  @name_node = (name == "linux") ? "az-lnxtest#{SecureRandom.hex(4)}" : "az-wintest-#{SecureRandom.hex(4)}"
end

def init_azure_test
  init_test

  begin
    %w{azure_invalid.publishsettings}.each do |file_name|
      data_to_write = File.read(File.expand_path("../integration/config/#{file_name}", __FILE__))
      File.open("#{temp_dir}/#{file_name}", "w") { |f| f.write(data_to_write) }
    end
  rescue
    puts "Error while creating file - azure invalid"
  end

  config_file_exist = File.exist?(File.expand_path("../integration/config/environment.yml", __FILE__))
  azure_config = YAML.load(File.read(File.expand_path("../integration/config/environment.yml", __FILE__))) if config_file_exist

  %w{AZ_SSH_USER AZ_SSH_PASSWORD AZ_WINDOWS_SSH_USER AZ_WINDOWS_SSH_PASSWORD AZ_WINRM_USER AZ_WINRM_PASSWORD AZ_LINUX_IMAGE AZ_LINUX_VM_SIZE AZ_INVALID_VM_SIZE AZ_WINDOWS_VM_SIZE AZ_WINDOWS_IMAGE AZ_WINDOWS_SSH_IMAGE AZURE_SERVICE_LOCATION}.each do |az_config_opt|
    instance_variable_set("@#{az_config_opt.downcase}", (azure_config[az_config_opt] if azure_config) || ENV[az_config_opt])
  end
end

def chef_gte_12?
  Chef::VERSION.split(".").first.to_i >= 12
end

def chef_lt_12?
  Chef::VERSION.split(".").first.to_i < 12
end

def is_windows?
  (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
end

RSpec.configure do |config|
  config.filter_run_excluding chef_gte_12_only: true unless chef_gte_12?
  config.filter_run_excluding chef_lt_12_only: true unless chef_lt_12?
  config.filter_run_excluding windows_only: true unless is_windows?
end
