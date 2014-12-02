require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')

class Azure
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

describe 'roles' do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    setup_query_azure_mock
  end
  context 'delete a role' do
    context 'when the role is not the only one in a deployment' do
      it 'should pass in correct name, verb, and body' do
        @connection.roles.delete('vm002', preserve_azure_os_disk: true)
        expect(@deletename).to be == 'hostedservices/service001/deployments/deployment001/roles/vm002'
        expect(@deleteverb).to be == 'delete'
        expect(@deletebody).to be nil
      end
    end
  end
  context 'delete a role' do
    context 'when the role is the only one in a deployment' do
      it 'should pass in correct name, verb, and body' do
        @connection.roles.delete('vm01', preserve_azure_os_disk: true)
        expect(@deletename).to be == 'hostedservices/service002/deployments/testrequest'
        expect(@deleteverb).to be == 'delete'
        expect(@deletebody).to be nil
      end
    end
  end
  context 'create a new role' do
    it 'should pass in expected body' do
      params = {
        azure_dns_name: 'service001',
        azure_vm_name: 'vm01',
        ssh_user: 'jetstream',
        ssh_password: 'jetstream1!',
        media_location_prefix: 'auxpreview104',
        azure_os_disk_name: 'disk004Test',
        azure_source_image: 'SUSE__OpenSUSE64121-03192012-en-us-15GB',
        azure_vm_size: 'ExtraSmall',
        tcp_endpoints: '44:45,55:55',
        udp_endpoints: '65:65,75',
        azure_storage_account: 'storageaccount001',
        bootstrap_proto: 'ssh',
        os_type: 'Linux',
        port: '22'

      }

      deploy = @connection.deploys.create(params)
      expect(readFile('create_role.xml')).to eq(@receivedXML)
    end
  end
  context 'create a new deployment' do
    it 'should pass in expected body' do
      params = {
        azure_dns_name: 'unknown_yet',
        azure_vm_name: 'vm01',
        ssh_user: 'jetstream',
        ssh_password: 'jetstream1!',
        media_location_prefix: 'auxpreview104',
        azure_os_disk_name: 'disk004Test',
        azure_source_image: 'SUSE__OpenSUSE64121-03192012-en-us-15GB',
        azure_vm_size: 'ExtraSmall',
        azure_storage_account: 'storageaccount001',
        bootstrap_proto: 'ssh',
        os_type: 'Linux',
        port: '22'
      }

      deploy = @connection.deploys.create(params)
      expect(readFile('create_deployment.xml')).to eq(@receivedXML)
    end
    it 'create request with virtual network' do
      params = {
        azure_dns_name: 'unknown_yet',
        azure_vm_name: 'vm01',
        ssh_user: 'jetstream',
        ssh_password: 'jetstream1!',
        media_location_prefix: 'auxpreview104',
        azure_os_disk_name: 'disk004Test',
        azure_source_image: 'SUSE__OpenSUSE64121-03192012-en-us-15GB',
        azure_vm_size: 'ExtraSmall',
        azure_storage_account: 'storageaccount001',
        bootstrap_proto: 'ssh',
        os_type: 'Linux',
        port: '22',
        azure_network_name: 'test-network',
        azure_subnet_name: 'test-subnet'
      }

      deploy = @connection.deploys.create(params)
      expect(readFile('create_deployment_virtual_network.xml')).to eq(@receivedXML)
    end

    it 'with ssh key' do
      params = {
        azure_dns_name: 'unknown_yet',
        azure_vm_name: 'vm01',
        ssh_user: 'jetstream',
        identity_file: File.dirname(__FILE__) + '/assets/key_rsa',
        media_location_prefix: 'auxpreview104',
        azure_os_disk_name: 'disk004Test',
        azure_source_image: 'SUSE__OpenSUSE64121-03192012-en-us-15GB',
        azure_vm_size: 'ExtraSmall',
        azure_storage_account: 'storageaccount001',
        bootstrap_proto: 'ssh',
        os_type: 'Linux',
        port: '22'
      }

      deploy = @connection.deploys.create(params)
      expect(readFile('create_deployment_key.xml')).to eq(@receivedXML)
    end
  end
end
