$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rspec'
require 'equivalent-xml'
require 'chef'
require 'chef/log'

require 'azure/connection'
require 'azure/rest'
require 'azure/host'
require 'azure/image'
require 'azure/deploy'
require 'azure/role'
require 'azure/disk'

require 'chef/knife/azure_server_list'
require 'chef/knife/azure_server_delete'
require 'chef/knife/azure_server_create'
require 'chef/knife/azure_server_describe'
require 'chef/knife/azure_image_list'

def tmpFile filename
  tmpdir = 'tmp'
  Dir::mkdir tmpdir unless FileTest::directory?(tmpdir)
  tmpdir + '/' + filename
end

Chef::Log.init(tmpFile('debug.log'), 'daily')
Chef::Log.level=:debug

TEST_PARAMS = {
  :azure_subscription_id => "YOUR_SUBSCRIPTION_ID_HERE",
  :azure_mgmt_cert => "AzureManagement.pem",
  :azure_server_url => "management-preview.core.windows-int.net",
  :service_name => "hostedservices"
}

module AzureSpecHelper
  def readFile filename
    File.read(File.dirname(__FILE__) + "/unit/assets/#{filename}")
  end
end
