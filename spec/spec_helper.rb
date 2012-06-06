#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
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

module AzureSpecHelper
  def readFile filename
    File.read(File.dirname(__FILE__) + "/unit/assets/#{filename}")
  end

  def test_params 
    params = {:azure_subscription_id => "155a9851-88a8-49b4-98e4-58055f08f412", :azure_pem_file => "AzureLinuxCert.pem",
      :azure_host_name => "management-preview.core.windows-int.net",
      :service_name => "hostedservices"}
  end
end
