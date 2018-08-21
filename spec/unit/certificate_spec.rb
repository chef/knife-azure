require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/query_azure_mock")

describe "certificates" do
  include AzureSpecHelper
  include QueryAzureMock

  before do
    @server_instance = Chef::Knife::AzureServerCreate.new
    {
      :azure_subscription_id => "azure_subscription_id",
      :azure_mgmt_cert => @cert_file,
      :azure_api_host_name => "preview.core.windows-int.net"
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    stub_query_azure(@server_instance.service.connection)
    @connection = @server_instance.service.connection
  end

  describe "get_certificate" do
    it "gets certificates for given dns name and fingerprint" do
      certificate = @connection.certificates.get_certificate("unknown_yet", "7dbcac68f670a27cf5d9a4e6c4a8d097bff645e2")
      expect(certificate).not_to be_empty
    end

    it "it returns empty array if certificate not found" do
      certificate = @connection.certificates.get_certificate("unknown_yet", "9dbcac68f670a27cf5d9a4e6c4a8d097bff645e2")
      expect(certificate).to be_empty
    end
  end
end
