require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/query_azure_mock")

module Azure
  class Certificate
    class Random
      def self.rand(_var)
        1
      end
    end
    class Time
      def self.now
        1
      end
    end
  end
end

describe "roles" do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    @server_instance = Chef::Knife::AzureServerCreate.new
    {
      azure_subscription_id: "azure_subscription_id",
      azure_mgmt_cert: @cert_file,
      azure_api_host_name: "preview.core.windows-int.net",
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    stub_query_azure @server_instance.service.connection
    @connection = @server_instance.service.connection
  end

  context "delete a role" do
    context "when the role is not the only one in a deployment" do
      it "should pass in correct name, verb, and body" do
        @connection.roles.delete(name: "vm002", preserve_azure_os_disk: true)
        expect(@deletename).to be == "hostedservices/service001/deployments/deployment001/roles/vm002"
        expect(@deleteverb).to be == "delete"
        expect(@deletebody).to be nil
      end
    end
  end

  context "delete a role" do
    context "when the role is the only one in a deployment" do
      it "should pass in correct name, verb, and body" do
        @connection.roles.delete(name: "vm01", preserve_azure_os_disk: true)
        expect(@deletename).to be == "hostedservices/service002/deployments/testrequest"
        expect(@deleteverb).to be == "delete"
        expect(@deletebody).to be nil
      end
    end
  end

  context "create a new role" do
    it "should pass in expected body" do
      params = {
        azure_dns_name: "service001",
        azure_api_host_name: "management.core.windows.net",
        azure_vm_name: "vm01",
        connection_user: "jetstream",
        connection_password: "jetstream1!",
        media_location_prefix: "auxpreview104",
        azure_os_disk_name: "disk004Test",
        azure_source_image: "SUSE__OpenSUSE64121-03192012-en-us-15GB",
        azure_vm_size: "ExtraSmall",
        tcp_endpoints: "80:80, 3389:3389, 993:993, 44: 45",
        udp_endpoints: "65:65,75",
        azure_storage_account: "storageaccount001",
        connection_protocol: "ssh",
        os_type: "Linux",
        port: "22",

      }

      deploy = @connection.deploys.create(params)
      expect(readFile("create_role.xml")).to eq(@receivedXML)
    end
  end

  describe "assign tcp endpoint name" do
    before do
      @params = {
        azure_dns_name: "service001",
        azure_api_host_name: "management.core.windows.net",
        azure_vm_name: "vm01",
        connection_user: "jetstream",
        connection_password: "jetstream1!",
        media_location_prefix: "auxpreview104",
        azure_source_image: "SUSE__OpenSUSE64121-03192012-en-us-15GB",
        azure_vm_size: "ExtraSmall",
        azure_storage_account: "storageaccount001",
        connection_protocol: "ssh",
      }
    end

    context "tcp_endpoint 80:80" do
      it "assigns tcp endpoint name HTTP" do
        @params[:tcp_endpoints] = "80:80"
        @connection.deploys.create(@params)
        doc = Nokogiri::XML::Document.parse(@receivedXML)
        doc.remove_namespaces!
        endpoints = doc.xpath("//InputEndpoints/InputEndpoint")
        endpoints[1].children.each do |node|
          expect(node.children.text).to eq("HTTP") if node.name == "Name"
        end
      end
    end

    context "tcp_endpoint 44:45" do
      it "generates tcp endpoint name as TCPEndpoint_chef_<port_number>" do
        @params[:tcp_endpoints] = "44:45"
        @connection.deploys.create(@params)
        doc = Nokogiri::XML::Document.parse(@receivedXML)
        doc.remove_namespaces!
        endpoints = doc.xpath("//InputEndpoints/InputEndpoint")
        endpoints[1].children.each do |node|
          expect(node.children.text).to eq("TCPEndpoint_chef_44") if node.name == "Name"
        end
      end
    end
  end

  context "create a new deployment" do
    it "should pass in expected body" do
      params = {
        azure_dns_name: "unknown_yet",
        azure_api_host_name: "management.core.windows.net",
        azure_vm_name: "vm01",
        connection_user: "jetstream",
        connection_password: "jetstream1!",
        media_location_prefix: "auxpreview104",
        azure_os_disk_name: "disk004Test",
        azure_source_image: "SUSE__OpenSUSE64121-03192012-en-us-15GB",
        azure_vm_size: "ExtraSmall",
        azure_storage_account: "storageaccount001",
        connection_protocol: "ssh",
        os_type: "Linux",
        port: "22",
      }

      deploy = @connection.deploys.create(params)
      expect(readFile("create_deployment.xml")).to eq(@receivedXML)
    end
    it "create request with virtual network" do
      params = {
        azure_dns_name: "unknown_yet",
        azure_api_host_name: "management.core.windows.net",
        azure_vm_name: "vm01",
        connection_user: "jetstream",
        connection_password: "jetstream1!",
        media_location_prefix: "auxpreview104",
        azure_os_disk_name: "disk004Test",
        azure_source_image: "SUSE__OpenSUSE64121-03192012-en-us-15GB",
        azure_vm_size: "ExtraSmall",
        azure_storage_account: "storageaccount001",
        connection_protocol: "ssh",
        os_type: "Linux",
        port: "22",
        azure_network_name: "test-network",
        azure_subnet_name: "test-subnet",
      }

      deploy = @connection.deploys.create(params)
      expect(readFile("create_deployment_virtual_network.xml")).to eq(@receivedXML)
    end

    it "with ssh key" do
      params = {
        azure_dns_name: "unknown_yet",
        azure_api_host_name: "management.core.windows.net",
        azure_vm_name: "vm01",
        connection_user: "jetstream",
        ssh_identity_file: File.dirname(__FILE__) + "/assets/key_rsa",
        media_location_prefix: "auxpreview104",
        azure_os_disk_name: "disk004Test",
        azure_source_image: "SUSE__OpenSUSE64121-03192012-en-us-15GB",
        azure_vm_size: "ExtraSmall",
        azure_storage_account: "storageaccount001",
        connection_protocol: "ssh",
        os_type: "Linux",
        port: "22",
      }

      deploy = @connection.deploys.create(params)
      expect(readFile("create_deployment_key.xml")).to eq(@receivedXML)
    end

    describe "WinRM bootstrapping" do
      it "customizes the WinRM config" do
        params = {
          azure_dns_name: "unknown_yet",
          azure_vm_name: "vm01",
          azure_api_host_name: "management.core.windows.net",
          connection_user: "build",
          admin_password: "foobar",
          ssl_cert_fingerprint: "7FCCD713CC390E3488290BF7A106AD267B5AC2A5",
          azure_os_disk_name: "disk_ce92083f-0041-4825-84b3-6ae8b3525b29",
          azure_source_image: "a699494373c04fc0bc8f2bb1389d6106__Win2K8R2SP1-Datacenter-201502.01-en.us-127GB.vhd",
          azure_vm_size: "Medium",
          azure_storage_account: "chefci",
          os_type: "Windows",
          connection_protocol: "winrm",
          winrm_ssl: true,
          winrm_max_timeout: 1_800_000,
          winrm_max_memory_per_shell: 600,
        }

        deploy = @connection.deploys.create(params)
        expect(readFile("create_deployment_winrm.xml")).to eq(@receivedXML)
      end
    end
  end
end
