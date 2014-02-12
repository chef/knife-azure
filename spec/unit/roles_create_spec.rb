require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')

class Azure
  class Certificate
    class Random
      def self.rand(var)
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
    setup_query_azure_mock
  end
  context 'delete a role' do
    context 'when the role is not the only one in a deployment' do
      it 'should pass in correct name, verb, and body' do
        @connection.roles.delete('vm002', {:preserve_azure_os_disk => true});
        @deletename.should == 'hostedservices/service001/deployments/deployment001/roles/vm002'
        @deleteverb.should == 'delete'
        @deletebody.should == nil
      end
    end
  end
  context 'delete a role' do
    context 'when the role is the only one in a deployment' do
      it 'should pass in correct name, verb, and body' do
        @connection.roles.delete('vm01', {:preserve_azure_os_disk => true});
        @deletename.should == 'hostedservices/service002/deployments/testrequest'
        @deleteverb.should == 'delete'
        @deletebody.should == nil
      end
    end
  end
  context 'create a new role' do
    it 'should pass in expected body' do
      submittedXML=Nokogiri::XML readFile('create_role.xml')
      params = {
        :azure_dns_name=>'service001',
        :azure_vm_name=>'vm01',
        :ssh_user=>'jetstream',
        :ssh_password=>'jetstream1!',
        :media_location_prefix=>'auxpreview104',
        :azure_os_disk_name=>'disk004Test',
        :azure_source_image=>'SUSE__OpenSUSE64121-03192012-en-us-15GB',
        :azure_vm_size=>'ExtraSmall',
        :tcp_endpoints=>'44:45,55:55',
        :udp_endpoints=>'65:65,75',
        :azure_storage_account=>'storageaccount001',
        :bootstrap_proto=>'ssh',
        :os_type=>'Linux',
        :port=>'22'

      }
      deploy = @connection.deploys.create(params)
      #this is a cheesy workaround to make equivalent-xml happy
      # write and then re-read the xml
      File.open(tmpFile('newRoleRcvd.xml'), 'w') {|f| f.write(@receivedXML) }
      File.open(tmpFile('newRoleSbmt.xml'), 'w') {|f| f.write(submittedXML.to_xml) }
      rcvd = Nokogiri::XML File.open(tmpFile('newRoleRcvd.xml'))
      sbmt = Nokogiri::XML File.open(tmpFile('newRoleSbmt.xml'))
      rcvd.should be_equivalent_to(sbmt).respecting_element_order.with_whitespace_intact
    end
  end
  context 'create a new deployment' do
    it 'should pass in expected body' do
      submittedXML=Nokogiri::XML readFile('create_deployment.xml')
      params = {
        :azure_dns_name=>'unknown_yet',
        :azure_vm_name=>'vm01',
        :ssh_user=>'jetstream',
        :ssh_password=>'jetstream1!',
        :media_location_prefix=>'auxpreview104',
        :azure_os_disk_name=>'disk004Test',
        :azure_source_image=>'SUSE__OpenSUSE64121-03192012-en-us-15GB',
        :azure_vm_size=>'ExtraSmall',
        :azure_storage_account=>'storageaccount001',
        :bootstrap_proto=>'ssh',
        :os_type=>'Linux',
        :port=>'22'
      }
      deploy = @connection.deploys.create(params)
      #this is a cheesy workaround to make equivalent-xml happy
      # write and then re-read the xml
      File.open(tmpFile('newDeployRcvd.xml'), 'w') {|f| f.write(@receivedXML) }
      File.open(tmpFile('newDeploySbmt.xml'), 'w') {|f| f.write(submittedXML.to_xml) }
      rcvd = Nokogiri::XML File.open(tmpFile('newDeployRcvd.xml'))
      sbmt = Nokogiri::XML File.open(tmpFile('newDeploySbmt.xml'))
      rcvd.should be_equivalent_to(sbmt).respecting_element_order
    end
    it 'create request with virtual network' do
      submittedXML=Nokogiri::XML readFile('create_deployment_virtual_network.xml')
      params = {
        :azure_dns_name=>'unknown_yet',
        :azure_vm_name=>'vm01',
        :ssh_user=>'jetstream',
        :ssh_password=>'jetstream1!',
        :media_location_prefix=>'auxpreview104',
        :azure_os_disk_name=>'disk004Test',
        :azure_source_image=>'SUSE__OpenSUSE64121-03192012-en-us-15GB',
        :azure_vm_size=>'ExtraSmall',
        :azure_storage_account=>'storageaccount001',
        :bootstrap_proto=>'ssh',
        :os_type=>'Linux',
        :port=>'22',
        :azure_network_name=>'test-network',
        :azure_subnet_name=>'test-subnet'
      }
      deploy = @connection.deploys.create(params)
      #this is a cheesy workaround to make equivalent-xml happy
      # write and then re-read the xml
      File.open(tmpFile('newDeployRcvd.xml'), 'w') {|f| f.write(@receivedXML) }
      File.open(tmpFile('newDeploySbmt.xml'), 'w') {|f| f.write(submittedXML.to_xml) }
      rcvd = Nokogiri::XML File.open(tmpFile('newDeployRcvd.xml'))
      sbmt = Nokogiri::XML File.open(tmpFile('newDeploySbmt.xml'))
      rcvd.should be_equivalent_to(sbmt).respecting_element_order
    end

    it 'with ssh key' do
      submittedXML=Nokogiri::XML readFile('create_deployment_key.xml')
      params = {
        :azure_dns_name=>'unknown_yet',
        :azure_vm_name=>'vm01',
        :ssh_user=>'jetstream',
        :identity_file=> File.dirname(__FILE__) + '/assets/key_rsa',
        :media_location_prefix=>'auxpreview104',
        :azure_os_disk_name=>'disk004Test',
        :azure_source_image=>'SUSE__OpenSUSE64121-03192012-en-us-15GB',
        :azure_vm_size=>'ExtraSmall',
        :azure_storage_account=>'storageaccount001',
        :bootstrap_proto=>'ssh',
        :os_type=>'Linux',
        :port=>'22'
      }
      deploy = @connection.deploys.create(params)
      #this is a cheesy workaround to make equivalent-xml happy
      # write and then re-read the xml
      File.open(tmpFile('newDeployRcvd.xml'), 'w') {|f| f.write(@receivedXML) }
      File.open(tmpFile('newDeploySbmt.xml'), 'w') {|f| f.write(submittedXML.to_xml) }
      rcvd = Nokogiri::XML File.open(tmpFile('newDeployRcvd.xml'))
      sbmt = Nokogiri::XML File.open(tmpFile('newDeploySbmt.xml'))
      rcvd.should be_equivalent_to(sbmt).respecting_element_order
    end

    it 'with domain join options' do
      submittedXML=Nokogiri::XML readFile('create_deployment_domain.xml')
      params = {
        :azure_dns_name=>'unknown_yet',
        :azure_vm_name=>'vm-in-domain',
        :winrm_user=>'user2',
        :winrm_password=>'vm@123456',
        :azure_os_disk_name=>'somediskname',
        :azure_source_image=>'Windows-Server-2012-Datacenter-201310.01-en.us-127GB',
        :azure_vm_size=>'Medium',
        :azure_storage_account=>'storageaccount001',
        :bootstrap_proto=>'winrm',
        :os_type=>'Windows',
        :azure_subnet_name=>'Subnet-1',
        :azure_domain_name=>'vmtestad.com',
        :azure_domain_user=>'user2',
        :azure_domain_passwd=>'user2pass',
      }
      deploy = @connection.deploys.create(params)
      #this is a cheesy workaround to make equivalent-xml happy
      # write and then re-read the xml
      File.open(tmpFile('newDeployRcvd.xml'), 'w') {|f| f.write(@receivedXML) }
      File.open(tmpFile('newDeploySbmt.xml'), 'w') {|f| f.write(submittedXML.to_xml) }
      rcvd = Nokogiri::XML File.open(tmpFile('newDeployRcvd.xml'))
      sbmt = Nokogiri::XML File.open(tmpFile('newDeploySbmt.xml'))
      rcvd.should be_equivalent_to(sbmt).respecting_element_order
    end
  end
end
