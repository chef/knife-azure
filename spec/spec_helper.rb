$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "chef/knife/azurerm_server_list"
require "chef/knife/azurerm_server_show"
require "chef/knife/azurerm_server_delete"
require "chef/knife/azurerm_server_create"
require "chef/knife/bootstrap_azurerm"

if Chef::Platform.windows?
  require "azure/resource_management/windows_credentials"
end

require "fileutils" unless defined?(FileUtils)
require "knife-azure/version"

def temp_dir
  @_temp_dir ||= Dir.mktmpdir
end

def tmpFile(filename)
  temp_dir + "/" + filename
end

class UnexpectedSystemExit < RuntimeError
  def self.from(system_exit)
    new(system_exit.message).tap { |e| e.set_backtrace(system_exit.backtrace) }
  end
end

RSpec.configure do |c|
  c.before(:each) do
    Chef::Config.reset

    # Set environment variables to bypass licensing (same as CI)
    ENV["CHEF_LICENSE"] = "accept-silent"

    # Mock license acceptance to prevent tomlrb parsing issues
    allow_any_instance_of(Chef::Knife::AzurermServerCreate).to receive(:check_license)
    allow_any_instance_of(Chef::Knife::AzurermServerCreate).to receive(:check_eula_license)
    allow_any_instance_of(Chef::Knife::BootstrapAzurerm).to receive(:check_license)
    allow_any_instance_of(Chef::Knife::BootstrapAzurerm).to receive(:check_eula_license)

    # Mock chef-licensing to prevent license file parsing
    allow(Chef::Utils::LicensingHandler).to receive(:validate!) if defined?(Chef::Utils::LicensingHandler)
    allow_any_instance_of(Chef::Knife::Bootstrap).to receive(:fetch_license) if defined?(Chef::Knife::Bootstrap)

    # Mock Chef::Config paths
    Chef::Config[:validation_key] = "/tmp/validation_key"
    Chef::Config[:client_key] = "/tmp/client_key.pem"

    # Less aggressive File mocking - only mock when files don't exist to prevent real file access
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:expand_path).and_call_original

    # Only mock non-existent files to prevent file system access during tests
    allow(File).to receive(:exist?).with(%r{/tmp/validation_key}).and_return(true)
    allow(File).to receive(:exist?).with(%r{/etc/chef/validation\.pem}).and_return(true)
    allow(File).to receive(:read).with(%r{/tmp/validation_key}).and_return("MOCK_VALIDATION_KEY")
    allow(File).to receive(:read).with(%r{/etc/chef/validation\.pem}).and_return("MOCK_VALIDATION_PEM")
  end

  c.after(:each) do
    # Clean up environment variables
    ENV.delete("CHEF_LICENSE")
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

  c.around(:example) do |ex|

    ex.run
  rescue SystemExit => e
    raise UnexpectedSystemExit.from(e)

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
  config_file_exist = File.exist?(File.expand_path("integration/config/environment.yml", __dir__))
  azure_config = YAML.load(File.read(File.expand_path("integration/config/environment.yml", __dir__))) if config_file_exist

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

  config_file_exist = File.exist?(File.expand_path("integration/config/environment.yml", __dir__))
  azure_config = YAML.load(File.read(File.expand_path("integration/config/environment.yml", __dir__))) if config_file_exist

  %w{AZ_SSH_USER AZ_SSH_PASSWORD AZ_WINDOWS_SSH_USER AZ_WINDOWS_SSH_PASSWORD AZ_WINRM_USER AZ_WINRM_PASSWORD AZ_LINUX_IMAGE AZ_LINUX_VM_SIZE AZ_INVALID_VM_SIZE AZ_WINDOWS_VM_SIZE AZ_WINDOWS_IMAGE AZ_WINDOWS_SSH_IMAGE AZURE_SERVICE_LOCATION}.each do |az_config_opt|
    instance_variable_set("@#{az_config_opt.downcase}", (azure_config[az_config_opt] if azure_config) || ENV[az_config_opt])
  end
end

def is_windows?
  (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
end

RSpec.configure do |config|
  config.filter_run_excluding windows_only: true unless is_windows?
end
