#
# Author:: Mukta Aphale (<mukta.aphale@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')
require 'chef/knife/bootstrap'
require 'chef/knife/bootstrap_windows_winrm'
require 'chef/knife/bootstrap_windows_ssh'
require 'active_support/core_ext/hash/conversions'

describe Chef::Knife::AzureServerCreate do
  include AzureSpecHelper
  include QueryAzureMock
  include AzureUtility

  before do
    @server_instance = Chef::Knife::AzureServerCreate.new
    {
      :azure_subscription_id => 'azure_subscription_id',
      :azure_mgmt_cert => @cert_file,
      :azure_api_host_name => 'preview.core.windows-int.net',
      :azure_service_location => 'West Europe',
      :azure_source_image => 'SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd',
      :azure_dns_name => 'service001',
      :azure_vm_name => 'vm002',
      :azure_storage_account => 'ka001testeurope',
      :azure_vm_size => 'Small',
      :ssh_user => 'test-user'
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    stub_query_azure (@server_instance.connection)
    allow(@server_instance).to receive(:tcp_test_ssh).and_return(true)
    allow(@server_instance).to receive(:tcp_test_winrm).and_return(true)
    @server_instance.initial_sleep_delay = 0
    allow(@server_instance).to receive(:sleep).and_return(0)
    allow(@server_instance).to receive(:puts)
    allow(@server_instance).to receive(:print)
  end

  def test_params(testxml, chef_config, role_name, host_name)
    expect(xml_content(testxml, 'UserName')).to be == chef_config[:ssh_user]
    expect(xml_content(testxml, 'UserPassword')).to be == chef_config[:ssh_password]
    expect(xml_content(testxml, 'SourceImageName')).to be == chef_config[:azure_source_image]
    expect(xml_content(testxml, 'RoleSize')).to be == chef_config[:azure_vm_size]
    expect(xml_content(testxml, 'HostName')).to be == host_name
    expect(xml_content(testxml, 'RoleName')).to be == role_name
  end

  describe "parameter test:" do
    context "compulsory parameters" do
      it "azure_subscription_id" do
        Chef::Config[:knife].delete(:azure_subscription_id)
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      it "azure_mgmt_cert" do
        Chef::Config[:knife].delete(:azure_mgmt_cert)
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      it "azure_api_host_name" do
        Chef::Config[:knife].delete(:azure_api_host_name)
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      it "azure_source_image" do
        Chef::Config[:knife].delete(:azure_source_image)
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      it "azure_vm_size" do
        Chef::Config[:knife].delete(:azure_vm_size)
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      it "azure_service_location and azure_affinity_group not allowed" do
        Chef::Config[:knife][:azure_affinity_group] = 'test-affinity'
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      it "azure_service_location or azure_affinity_group must be provided" do
        Chef::Config[:knife].delete(:azure_service_location)
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end
    end
  end

  describe "parameter test:" do
    context "compulsory parameters" do
      it "azure_subscription_id" do
        Chef::Config[:knife].delete(:azure_subscription_id)
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      it "azure_mgmt_cert" do
        Chef::Config[:knife].delete(:azure_mgmt_cert)
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      it "azure_api_host_name" do
        Chef::Config[:knife].delete(:azure_api_host_name)
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      it "azure_source_image" do
        Chef::Config[:knife].delete(:azure_source_image)
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      it "azure_vm_size" do
        Chef::Config[:knife].delete(:azure_vm_size)
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      it "azure_service_location and azure_affinity_group not allowed" do
        Chef::Config[:knife][:azure_affinity_group] = 'test-affinity'
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      it "azure_service_location or azure_affinity_group must be provided" do
        Chef::Config[:knife].delete(:azure_service_location)
        expect(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end

      context "when winrm authentication protocol invalid" do
        it "raise error" do
          Chef::Config[:knife][:winrm_authentication_protocol] = "invalide"
          expect(@server_instance.ui).to receive(:error)
          expect {@server_instance.run}.to raise_error
        end
      end

      context "when winrm-transport ssl and missing thumbprint" do
        it "raise error on :winrm_ssl_verify_mode verify_peer" do
          Chef::Config[:knife][:winrm_transport] = 'ssl'
          Chef::Config[:knife][:winrm_ssl_verify_mode] = :verify_peer
          expect(@server_instance.ui).to receive(:error)
          expect {@server_instance.run}.to raise_error
        end
      end
    end

    context "timeout parameters" do
      it "uses correct values when not specified" do
        expect(@server_instance.options[:azure_vm_startup_timeout][:default].to_i).to eq(10)
        expect(@server_instance.options[:azure_vm_ready_timeout][:default].to_i).to eq(15)
      end

      it "matches the CLI options" do
        #Set params to non-default values
        Chef::Config[:knife][:azure_vm_startup_timeout] = 5
        Chef::Config[:knife][:azure_vm_ready_timeout] = 10
        expect(@server_instance.send(:locate_config_value, :azure_vm_startup_timeout).to_i).to eq(Chef::Config[:knife][:azure_vm_startup_timeout])
        expect(@server_instance.send(:locate_config_value, :azure_vm_ready_timeout).to_i).to eq(Chef::Config[:knife][:azure_vm_ready_timeout])
      end
    end

    context "server create options" do
      before do
        Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
        Chef::Config[:knife][:ssh_password] = 'ssh_password'
        Chef::Config[:knife][:ssh_user] = 'ssh_user'
        Chef::Config[:knife].delete(:azure_vm_name)
        Chef::Config[:knife].delete(:azure_storage_account)
        @bootstrap = Chef::Knife::Bootstrap.new
        allow(Chef::Knife::Bootstrap).to receive(:new).and_return(@bootstrap)
        expect(@bootstrap).to receive(:run)
        allow(@server_instance).to receive(:msg_server_summary)
      end

      it "quick create" do
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(false)
        Chef::Config[:knife][:azure_dns_name] = 'vmname' # service name to be used as vm name
        expect(@server_instance).to receive(:get_dns_name)
        @server_instance.run
        expect(@server_instance.config[:azure_vm_name]).to be == "vmname"
        testxml = Nokogiri::XML(@receivedXML)
        expect(xml_content(testxml, 'MediaLink')).to_not be nil
        expect(xml_content(testxml, 'DiskName')).to_not be nil
        test_params(testxml, Chef::Config[:knife], Chef::Config[:knife][:azure_dns_name],
        Chef::Config[:knife][:azure_dns_name])
      end

      it "quick create with wirm - API check" do
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(true)
        Chef::Config[:knife][:azure_dns_name] = 'vmname' # service name to be used as vm name
        Chef::Config[:knife][:winrm_user] = 'opscodechef'
        Chef::Config[:knife][:winrm_password] = 'Opscode123'
        Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
        expect(@server_instance).to receive(:get_dns_name)
        @server_instance.run
        expect(@server_instance.config[:azure_vm_name]).to be == "vmname"
        testxml = Nokogiri::XML(@receivedXML)
        expect(xml_content(testxml, 'WinRM')).to_not be nil
        expect(xml_content(testxml, 'Listeners')).to_not be nil
        expect(xml_content(testxml, 'Listener')).to_not be nil
        expect(xml_content(testxml, 'Protocol')).to be == "Http"
      end

      it "generate unique OS DiskName" do
        os_disks = []
        allow(@bootstrap).to receive(:run)
        allow(@server_instance).to receive(:validate!)
        Chef::Config[:knife][:azure_dns_name] = 'vmname'

        5.times do
          @server_instance.run
          testxml = Nokogiri::XML(@receivedXML)
          disklink = xml_content(testxml, 'MediaLink')
          expect(os_disks).to_not include(disklink)
          os_disks.push(disklink)
        end
      end

      it "skip user specified tcp-endpoints if its ports already use by ssh endpoint" do
        # Default external port for ssh endpoint is 22.
        @server_instance.config[:tcp_endpoints] = "12:22"
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(false)
        Chef::Config[:knife][:azure_dns_name] = 'vmname' # service name to be used as vm name
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        testxml.css('InputEndpoint Protocol:contains("TCP")').each do | port |
          # Test data in @server_instance.config[:tcp_endpoints]:=> "12:22" this endpoints external port 22 is already use by ssh endpoint. So it should skip endpoint "12:22".
          expect(port.parent.css("LocalPort").text).to_not eq("12")
        end
      end

      it "advanced create" do
        # set all params
        Chef::Config[:knife][:azure_dns_name] = 'service001'
        Chef::Config[:knife][:azure_vm_name] = 'vm002'
        Chef::Config[:knife][:azure_storage_account] = 'ka001testeurope'
        Chef::Config[:knife][:azure_os_disk_name] = 'os-disk'
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        expect(xml_content(testxml, 'MediaLink')).to be == 'http://ka001testeurope.blob.core.windows-int.net/vhds/os-disk.vhd'
        expect(xml_content(testxml, 'DiskName')).to be == Chef::Config[:knife][:azure_os_disk_name]
        test_params(testxml, Chef::Config[:knife], Chef::Config[:knife][:azure_vm_name],
        Chef::Config[:knife][:azure_vm_name])
      end

      it "create with availability set" do
        # set all params
        Chef::Config[:knife][:azure_dns_name] = 'service001'
        Chef::Config[:knife][:azure_vm_name] = 'vm002'
        Chef::Config[:knife][:azure_storage_account] = 'ka001testeurope'
        Chef::Config[:knife][:azure_os_disk_name] = 'os-disk'
        Chef::Config[:knife][:azure_availability_set] = 'test-availability-set'
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        expect(xml_content(testxml, 'AvailabilitySetName')).to be == 'test-availability-set'
      end

      it "server create with virtual network and subnet" do
        Chef::Config[:knife][:azure_dns_name] = 'vmname'
        Chef::Config[:knife][:azure_network_name] = 'test-network'
        Chef::Config[:knife][:azure_subnet_name] = 'test-subnet'
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        expect(xml_content(testxml, 'SubnetName')).to be == 'test-subnet'
      end

      it "creates new load balanced endpoints" do
        Chef::Config[:knife][:azure_dns_name] = 'vmname'
        @server_instance.config[:tcp_endpoints] = "80:80:EXTERNAL:lb_set,443:443:EXTERNAL:lb_set_ssl:/healthcheck" #TODO is this a good way of specifying this?
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(false)
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        endpoints = testxml.css('InputEndpoint')

        # Should be 3 endpoints, 1 for SSH, 1 for port 80 using LB set name lb_set, and 1 for port 443 using lb_set2 and with healtcheck path.
        expect(endpoints.count).to be  == 3

        # Convert it to a hash as it's easier to test.
        eps = []
        endpoints.each do | ep |
          eps << Hash.from_xml(ep.to_s)
        end

        expect(eps[0]['InputEndpoint']['Name']).to be == 'SSH'

        lb_set_ep = eps[1]['InputEndpoint']
        expect(lb_set_ep['LoadBalancedEndpointSetName']).to be == 'lb_set'
        expect(lb_set_ep['LocalPort']).to be == '80'
        expect(lb_set_ep['Port']).to be == '80'
        expect(lb_set_ep['Protocol']).to be == 'TCP'
        expect(lb_set_ep['LoadBalancerProbe']['Port']).to be == '80'
        expect(lb_set_ep['LoadBalancerProbe']['Protocol']).to be == 'TCP'

        lb_set2_ep = eps[2]['InputEndpoint']
        expect(lb_set2_ep['LoadBalancedEndpointSetName']).to be == 'lb_set_ssl'
        expect(lb_set2_ep['LocalPort']).to be == '443'
        expect(lb_set2_ep['Port']).to be == '443'
        expect(lb_set2_ep['Protocol']).to be == 'TCP'
        expect(lb_set2_ep['LoadBalancerProbe']['Path']).to be == '/healthcheck'
        expect(lb_set2_ep['LoadBalancerProbe']['Port']).to be == '443'
        expect(lb_set2_ep['LoadBalancerProbe']['Protocol']).to be == 'HTTP'
      end

      it "re-uses existing load balanced endpoints" do
        Chef::Config[:knife][:azure_dns_name] = 'vmname'
        @server_instance.config[:tcp_endpoints] = "443:443:EXTERNAL:lb_set2:/healthcheck"
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(false)

        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        endpoints = testxml.css('InputEndpoint')

        expect(endpoints.count).to be  == 2

        # Convert it to a hash as it's easier to test.
        eps = []
        endpoints.each do | ep |
          eps << Hash.from_xml(ep.to_s)
        end
        expect(eps[0]['InputEndpoint']['Name']).to be == 'SSH'

        lb_set2_ep = eps[1]['InputEndpoint']
        expect(lb_set2_ep['LoadBalancedEndpointSetName']).to be == 'lb_set2'
        expect(lb_set2_ep['LocalPort']).to be == '443'
        expect(lb_set2_ep['Port']).to be == '443'
        expect(lb_set2_ep['Protocol']).to be == 'tcp'
        expect(lb_set2_ep['LoadBalancerProbe']['Path']).to be == '/healthcheck2' # The existing one wins. The 'healthcheck2' value is defined in the stub.
        expect(lb_set2_ep['LoadBalancerProbe']['Port']).to be == '443'
        expect(lb_set2_ep['LoadBalancerProbe']['Protocol']).to be == 'http'

      end

      it "allows internal load balancer to be specified" do
        Chef::Config[:knife][:azure_dns_name] = 'vmname'
        @server_instance.config[:tcp_endpoints] = "80:80:internal-lb-name:lb_set" #TODO is this a good way of specifying this?
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(false)

        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        endpoints = testxml.css('InputEndpoint')
        expect(endpoints.count).to be  == 2

        # Convert it to a hash as it's easier to test.
        eps = []
        endpoints.each do | ep |
          eps << Hash.from_xml(ep.to_s)
        end
        expect(eps[0]['InputEndpoint']['Name']).to be == 'SSH'

        lb_set_ep = eps[1]['InputEndpoint']
        expect(lb_set_ep['LoadBalancedEndpointSetName']).to be == 'lb_set'
        expect(lb_set_ep['LocalPort']).to be == '80'
        expect(lb_set_ep['Port']).to be == '80'
        expect(lb_set_ep['Protocol']).to be == 'TCP'
        expect(lb_set_ep['LoadBalancerProbe']['Port']).to be == '80'
        expect(lb_set_ep['LoadBalancerProbe']['Protocol']).to be == 'TCP'
        expect(lb_set_ep['LoadBalancerName']).to be == 'internal-lb-name'
      end

      it "server create display server summary" do
        Chef::Config[:knife][:azure_dns_name] = 'vmname'
        expect(@server_instance).to receive(:msg_server_summary)
        @server_instance.run
      end

      it 'create with automatic certificates creation if winrm-transport=ssl' do
        pending "with automatic certificates creation if winrm-transport=ssl"
        # set all params
        Chef::Config[:knife][:azure_dns_name] = 'service001'
        Chef::Config[:knife][:azure_vm_name] = 'vm002'
        Chef::Config[:knife][:winrm_user] = 'opscodechef'
        Chef::Config[:knife][:winrm_password] = 'Opscode123'
        Chef::Config[:knife][:winrm_transport] = 'ssl'

        #Temp directory for certificate path and \n for domain name and certificate passphrase
        dir = Dir.mktmpdir
        expect(@server_instance.connection.certificates).to receive(:create_ssl_certificate).with(Chef::Config[:knife][:azure_dns_name]).and_call_original
        allow(STDIN).to receive(:gets).and_return(dir,"cloudapp.net","\n")
        @server_instance.run

        #check if certificates are created
        expect(File).to exist(File.join(dir, "winrm.pfx"))
        expect(File).to exist(File.join(dir, "winrm.b64"))
        expect(File).to exist(File.join(dir, "winrm.pem"))

        #Delete temp directory
        FileUtils.remove_entry_secure dir
      end

      context "Domain join:" do
        before do
          Chef::Config[:knife][:azure_dns_name] = 'vmname'
          @server_instance.stub(:is_image_windows?).and_return(true)
          Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
          Chef::Config[:knife][:winrm_user] = 'testuser'
          Chef::Config[:knife][:winrm_password] = 'winrm_password'
        end

        it "server create with domain join options" do
          Chef::Config[:knife][:azure_domain_name] = 'testad.com'
          Chef::Config[:knife][:azure_domain_user] = 'domainuser'
          Chef::Config[:knife][:azure_domain_passwd] = 'domainuserpass'
          @server_instance.run
          testxml = Nokogiri::XML(@receivedXML)
          expect(xml_content(testxml, 'DomainJoin Credentials Domain')).to eq('testad.com')
          expect(xml_content(testxml, 'DomainJoin Credentials Username')).to eq('domainuser')
          expect(xml_content(testxml, 'DomainJoin Credentials Password')).to eq('domainuserpass')
          expect(xml_content(testxml, 'JoinDomain')).to eq('testad.com')
        end

        it "server create with domain join options in user principal name (UPN) format (user@fully-qualified-DNS-domain)" do
          Chef::Config[:knife][:azure_domain_user] = 'domainuser@testad.com'
          Chef::Config[:knife][:azure_domain_passwd] = 'domainuserpass'
          @server_instance.run
          testxml = Nokogiri::XML(@receivedXML)
          expect(xml_content(testxml, 'DomainJoin Credentials Domain')).to eq('testad.com')
          expect(xml_content(testxml, 'DomainJoin Credentials Username')).to eq('domainuser')
          expect(xml_content(testxml, 'DomainJoin Credentials Password')).to eq('domainuserpass')
          expect(xml_content(testxml, 'JoinDomain')).to eq('testad.com')
        end

        it "server create with domain join options in fully-qualified-DNS-domain\\username format" do
          Chef::Config[:knife][:azure_domain_user] = 'testad.com\\domainuser'
          Chef::Config[:knife][:azure_domain_passwd] = 'domainuserpass'
          @server_instance.run
          testxml = Nokogiri::XML(@receivedXML)
          expect(xml_content(testxml, 'DomainJoin Credentials Domain')).to eq('testad.com')
          expect(xml_content(testxml, 'DomainJoin Credentials Username')).to eq('domainuser')
          expect(xml_content(testxml, 'DomainJoin Credentials Password')).to eq('domainuserpass')
          expect(xml_content(testxml, 'JoinDomain')).to eq('testad.com')
        end

        it "server create with domain join options including name of the organizational unit (OU) in which the computer account is created" do
          Chef::Config[:knife][:azure_domain_user] = 'testad.com\\domainuser'
          Chef::Config[:knife][:azure_domain_passwd] = 'domainuserpass'
          Chef::Config[:knife][:azure_domain_ou_dn] = 'OU=HR,dc=opscode,dc=com'
          @server_instance.run
          testxml = Nokogiri::XML(@receivedXML)
          expect(xml_content(testxml, 'DomainJoin Credentials Domain')).to eq('testad.com')
          expect(xml_content(testxml, 'DomainJoin Credentials Username')).to eq('domainuser')
          expect(xml_content(testxml, 'DomainJoin Credentials Password')).to eq('domainuserpass')
          expect(xml_content(testxml, 'DomainJoin MachineObjectOU')).to eq("OU=HR,dc=opscode,dc=com")
          expect(xml_content(testxml, 'JoinDomain')).to eq('testad.com')
        end
      end
    end

    context "missing create options" do
      before do
        Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
        Chef::Config[:knife][:winrm_user] = 'testuser'
        Chef::Config[:knife][:winrm_password] = 'winrm_password'
        Chef::Config[:knife].delete(:azure_vm_name)
        Chef::Config[:knife].delete(:azure_storage_account)
      end

      it "should error if domain user is not specified for domain join" do
        Chef::Config[:knife][:azure_dns_name] = 'vmname'
        @server_instance.stub(:is_image_windows?).and_return(true)

        Chef::Config[:knife][:azure_domain_name] = 'testad.com'
        Chef::Config[:knife][:azure_domain_passwd] = 'domainuserpass'
        @server_instance.ui.should_receive(:error).with('Must specify both --azure-domain-user and --azure-domain-passwd.')
        expect {@server_instance.run}.to raise_error(SystemExit)
      end

      it "should error if password for domain user is not specified for domain join" do
        Chef::Config[:knife][:azure_dns_name] = 'vmname'
        @server_instance.stub(:is_image_windows?).and_return(true)

        Chef::Config[:knife][:azure_domain_name] = 'testad.com'
        Chef::Config[:knife][:azure_domain_user] = 'domainuser'
        @server_instance.ui.should_receive(:error).with('Must specify both --azure-domain-user and --azure-domain-passwd.')
        expect {@server_instance.run}.to raise_error(SystemExit)
      end
    end

    context "when --azure-dns-name is not specified" do
      before(:each) do
        Chef::Config[:knife][:azure_dns_name] = nil
        Chef::Config[:knife][:azure_vm_name] = nil
      end

      it "generate unique dns name" do
        dns_name = []
        5.times do
          # send() to access private get_dns_name method of @server_instance
          dns = @server_instance.send(:get_dns_name, Chef::Config[:knife][:azure_dns_name])
          expect(dns_name).to_not include(dns)
          dns_name.push(dns)
        end
      end

      it "include vmname in dnsname if --azure-vm-name specified" do
        Chef::Config[:knife][:azure_vm_name] = "vmname"
        dns = @server_instance.send(:get_dns_name, Chef::Config[:knife][:azure_dns_name])
        expect(dns).to include("vmname")
      end
    end

    context "#cleanup_and_exit" do
      it "service leak cleanup" do
        expect(@server_instance.ui).to receive(:warn).with("Cleaning up resources...")
        expect {@server_instance.cleanup_and_exit("hosted_srvc", "storage_srvc")}.to raise_error
      end

      it "service leak cleanup with nil params" do
        expect(@server_instance.ui).to receive(:warn).with("Cleaning up resources...")
        expect(@server_instance.connection.hosts).to_not receive(:delete)
        expect(@server_instance.connection.storageaccounts).to_not receive(:delete)
        expect {@server_instance.cleanup_and_exit(nil, nil)}.to raise_error
      end

      it "service leak cleanup with valid params" do
        ret_val = Object.new
        ret_val.define_singleton_method(:content){""}
        expect(@server_instance.ui).to receive(:warn).with("Cleaning up resources...")
        expect(@server_instance.ui).to receive(:warn).with("Deleted created DNS: hosted_srvc.")
        expect(@server_instance.ui).to receive(:warn).with("Deleted created Storage Account: storage_srvc.")
        expect(@server_instance.connection.hosts).to receive(:delete).with("hosted_srvc").and_return(ret_val)
        expect(@server_instance.connection.storageaccounts).to receive(:delete).with("storage_srvc").and_return(ret_val)

        expect {@server_instance.cleanup_and_exit("hosted_srvc", "storage_srvc")}.to raise_error
      end

      it "display proper warn messages on cleanup fails" do
        ret_val = Object.new
        ret_val.define_singleton_method(:content){ "ConflictError" }
        ret_val.define_singleton_method(:text){ "ConflictError" }
        expect(@server_instance.ui).to receive(:warn).with("Cleaning up resources...")
        expect(@server_instance.ui).to receive(:warn).with("Deletion failed for created DNS:hosted_srvc. ConflictError")
        expect(@server_instance.ui).to receive(:warn).with("Deletion failed for created Storage Account: storage_srvc. ConflictError")
        expect(@server_instance.connection.hosts).to receive(:delete).with("hosted_srvc").and_return(ret_val)
        expect(@server_instance.connection.storageaccounts).to receive(:delete).with("storage_srvc").and_return(ret_val)

        expect {@server_instance.cleanup_and_exit("hosted_srvc", "storage_srvc")}.to raise_error
      end
    end

    context "connect to existing DNS tests" do
      before do
        Chef::Config[:knife][:azure_connect_to_existing_dns] = true
      end

      it "should throw error when DNS does not exist" do
        Chef::Config[:knife][:azure_dns_name] = 'does-not-exist'
        Chef::Config[:knife][:ssh_user] = 'azureuser'
        Chef::Config[:knife][:ssh_password] = 'Jetstream123!'
        expect {@server_instance.run}.to raise_error
      end

      it "port should be unique number when winrm-port not specified for winrm", :chef_lt_12_only do
        Chef::Config[:knife][:winrm_port] = nil
        Chef::Config[:knife][:azure_dns_name] = 'service001'
        Chef::Config[:knife][:azure_vm_name] = 'newvm01'
        Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
        Chef::Config[:knife][:winrm_user] = 'testuser'
        Chef::Config[:knife][:winrm_password] = 'Jetstream123!'
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:port]).not_to be == '5985'
      end

      it "port should be winrm-port value specified in the option" do
        Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
        Chef::Config[:knife][:winrm_user] = 'testuser'
        Chef::Config[:knife][:winrm_password] = 'Jetstream123!'
        Chef::Config[:knife][:winrm_port] = '5990'
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:port]).to be == '5990'
      end

      it "extract user name when winrm_user contains domain name" do
        Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
        Chef::Config[:knife][:winrm_user] = 'domain\\testuser'
        Chef::Config[:knife][:winrm_password] = 'Jetstream123!'
        Chef::Config[:knife][:winrm_port] = '5990'
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:winrm_user]).to be == 'testuser'
      end

      it "port should be unique number when ssh-port not specified for linux image" do
        Chef::Config[:knife][:ssh_user] = 'azureuser'
        Chef::Config[:knife][:ssh_password] = 'Jetstream123!'
        Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(false)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:port]).to_not be == '22'
      end

      it "port should be ssh-port value specified in the option" do
        Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
        Chef::Config[:knife][:ssh_user] = 'azureuser'
        Chef::Config[:knife][:ssh_password] = 'Jetstream123!'
        Chef::Config[:knife][:ssh_port] = '24'
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(false)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:port]).to be == '24'
      end

      it "port should be 22 if user specified --ssh-port 22" do
        Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
        Chef::Config[:knife][:ssh_user] = 'azureuser'
        Chef::Config[:knife][:ssh_password] = 'Jetstream123!'
        Chef::Config[:knife][:ssh_port] = '22'
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(false)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:port]).to be == '22'
      end

      it "port should be 5985 if user specified --winrm-port 5985" do
        Chef::Config[:knife][:winrm_user] = 'azureuser'
        Chef::Config[:knife][:winrm_password] = 'Jetstream123!'
        Chef::Config[:knife][:winrm_port] = '5985'
        Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:port]).to be == '5985'
      end
    end
  end

  describe "cloud attributes" do
    context "WinRM protocol:" do
      before do
        @bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
        allow(Chef::Knife::BootstrapWindowsWinrm).to receive(:new).and_return(@bootstrap)
        expect(@bootstrap).to receive(:run)
        allow(@server_instance).to receive(:is_image_windows?).and_return(true)
        Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
        Chef::Config[:knife][:winrm_user] = 'testuser'
        Chef::Config[:knife][:winrm_password] = 'winrm_password'
        Chef::Config[:knife][:azure_dns_name] = 'service004'
        Chef::Config[:knife][:azure_vm_name] = 'winrm-vm'
        Chef::Config[:knife][:hints] = nil # reset as this is loaded only once for app(test here)
        allow(@server_instance).to receive(:msg_server_summary)
        @server_instance.run
      end

      it "should set the cloud attributes in hints" do
        cloud_attributes = Chef::Config[:knife][:hints]["azure"]
        expect(cloud_attributes["public_ip"]).to be == "65.52.249.191"
        expect(cloud_attributes["vm_name"]).to be == "winrm-vm"
        expect(cloud_attributes["public_fqdn"]).to be == "service004.cloudapp.net"
        expect(cloud_attributes["public_ssh_port"]).to be_nil
        expect(cloud_attributes["public_winrm_port"]).to be == "5985"
      end
    end

    context "SSH protocol:" do
      before do
        @bootstrap = Chef::Knife::Bootstrap.new
        allow(Chef::Knife::Bootstrap).to receive(:new).and_return(@bootstrap)
        expect(@bootstrap).to receive(:run)
        allow(@server_instance).to receive(:is_image_windows?).and_return(false)
        Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
        Chef::Config[:knife][:ssh_password] = 'ssh_password'
        Chef::Config[:knife][:ssh_user] = 'ssh_user'
        Chef::Config[:knife][:azure_dns_name] = 'service004'
        Chef::Config[:knife][:azure_vm_name] = 'ssh-vm'
        Chef::Config[:knife][:hints] = nil # reset as this is loaded only once for app(test here)
        allow(@server_instance).to receive(:msg_server_summary)
        @server_instance.run
      end

      it "should set the cloud attributes in hints" do
        cloud_attributes = Chef::Config[:knife][:hints]["azure"]
        expect(cloud_attributes["public_ip"]).to be == "65.52.251.57"
        expect(cloud_attributes["vm_name"]).to be == "ssh-vm"
        expect(cloud_attributes["public_fqdn"]).to be == "service004.cloudapp.net"
        expect(cloud_attributes["public_ssh_port"]).to be  == "22"
        expect(cloud_attributes["public_winrm_port"]).to be nil
      end
    end
  end

  describe "for bootstrap protocol winrm:" do
    before do
      Chef::Config[:knife][:bootstrap_protocol] = 'winrm'
      Chef::Config[:knife][:winrm_user] = 'testuser'
      Chef::Config[:knife][:winrm_password] = 'winrm_password'
      allow(@server_instance.ui).to receive(:error)
      allow(@server_instance).to receive(:msg_server_summary)
    end

    it "check if all server params are set correctly" do
      expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
      @server_params = @server_instance.create_server_def
      expect(@server_params[:os_type]).to be == 'Windows'
      expect(@server_params[:admin_password]).to be == 'winrm_password'
      expect(@server_params[:bootstrap_proto]).to be == 'winrm'
      expect(@server_params[:azure_dns_name]).to be == 'service001'
      expect(@server_params[:azure_vm_name]).to be == 'vm002'
      expect(@server_params[:winrm_user]).to be == 'testuser'
      expect(@server_params[:port]).to be == '5985'
    end

    it "winrm_user cannot be 'administrator'" do
      expect(@server_instance).to receive(:is_image_windows?).twice.and_return(true)
      Chef::Config[:knife][:winrm_user] = 'administrator'
      expect {@server_instance.create_server_def}.to raise_error
    end

    it "winrm_user cannot be 'admin*'" do
      expect(@server_instance).to receive(:is_image_windows?).twice.and_return(true)
      Chef::Config[:knife][:winrm_user] = 'Admin12'
      expect {@server_instance.create_server_def}.to raise_error
    end

    context "bootstrap node" do
      before do
        @bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
        allow(Chef::Knife::BootstrapWindowsWinrm).to receive(:new).and_return(@bootstrap)
        expect(@bootstrap).to receive(:run)
      end

      it "sets param <azure_storage_account> from azure_vm_name" do
        Chef::Config[:knife].delete(:azure_storage_account)
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(true)
        @server_instance.run
        expect(@server_instance.config[:azure_storage_account]).to match(/\Avm002/)
      end

      it "sets param <azure_storage_account> from storage name" do
        Chef::Config[:knife].delete(:azure_storage_account)
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(true)
        Chef::Config[:knife][:azure_service_location] = 'service-location'
        @server_instance.run
        expect(@server_instance.config[:azure_storage_account]).to match(/storage-service-name/)
      end

      it "successful bootstrap of windows instance" do
        expect(@server_instance).to receive(:is_image_windows?).exactly(5).times.and_return(true)
        expect(@server_instance).to receive(:wait_until_virtual_machine_ready).exactly(1).times.and_return(true)
        @server_instance.run
      end

      it "sets encrypted data bag secret parameter" do
        Chef::Config[:knife][:encrypted_data_bag_secret] = 'test_encrypted_data_bag_secret'
        expect(@server_instance).to receive(:is_image_windows?).exactly(5).times.and_return(true)
        @server_instance.run
        expect(@bootstrap.config[:encrypted_data_bag_secret]).to be == 'test_encrypted_data_bag_secret'
      end

      it "sets encrypted data bag secret file parameter" do
        Chef::Config[:knife][:encrypted_data_bag_secret_file] = 'test_encrypted_data_bag_secret_file'
        expect(@server_instance).to receive(:is_image_windows?).exactly(5).times.and_return(true)
        @server_instance.run
        expect(@bootstrap.config[:encrypted_data_bag_secret_file]).to be == 'test_encrypted_data_bag_secret_file'
      end

      it "sets winrm authentication protocol for windows vm" do
        Chef::Config[:knife][:winrm_authentication_protocol] = "negotiate"
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(true)
        @server_instance.run
        expect(@bootstrap.config[:winrm_authentication_protocol]).to be == 'negotiate'
      end

      it "sets 'msi_url' correctly" do
        Chef::Config[:knife][:msi_url] = "https://opscode-omnibus-packages.s3.amazonaws.com/windows/2008r2/x86_64/chef-client-12.3.0-1.msi"
        allow(@server_instance).to receive(:is_image_windows?).and_return(true)
        @server_instance.run
        expect(@bootstrap.config[:msi_url]).to be == "https://opscode-omnibus-packages.s3.amazonaws.com/windows/2008r2/x86_64/chef-client-12.3.0-1.msi"
      end

      it "sets 'install_as_service' correctly" do
        Chef::Config[:knife][:install_as_service] = true
        allow(@server_instance).to receive(:is_image_windows?).and_return(true)
        @server_instance.run
        expect(@bootstrap.config[:install_as_service]).to eq(true)
      end
    end
  end

  describe "for bootstrap protocol ssh:" do
    before do
      Chef::Config[:knife][:bootstrap_protocol] = 'ssh'
      allow(@server_instance).to receive(:msg_server_summary)
    end

    context "windows instance:" do
      before do
        Chef::Config[:knife][:forward_agent] = true
      end

      it "successful bootstrap" do
        pending "OC-8384-support ssh for windows vm's in knife-azure"
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        @bootstrap = Chef::Knife::BootstrapWindowsSsh.new
        allow(Chef::Knife::BootstrapWindowsSsh).to receive(:new).and_return(@bootstrap)
        expect(@server_instance).to receive(:wait_until_virtual_machine_ready).exactly(1).times.and_return(true)
        expect(@bootstrap).to receive(:run)
        @server_instance.run
      end

      it "sets 'forward_agent' correctly" do
        expect(@server_instance.send(:locate_config_value,:forward_agent)).to be(true)
      end
    end

    context "linux instance" do
      before do
        Chef::Config[:knife][:ssh_password] = 'ssh_password'
        Chef::Config[:knife][:ssh_user] = 'ssh_user'
      end

      it "check if all server params are set correctly" do
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).and_return(false)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:os_type]).to be == 'Linux'
        expect(@server_params[:ssh_password]).to be == 'ssh_password'
        expect(@server_params[:ssh_user]).to be == 'ssh_user'
        expect(@server_params[:bootstrap_proto]).to be == 'ssh'
        expect(@server_params[:azure_dns_name]).to be == 'service001'
        expect(@server_params[:azure_vm_name]).to be == 'vm002'
        expect(@server_params[:port]).to be == '22'
      end

      it "successful bootstrap" do
        expect(@server_instance).to receive(:is_image_windows?).exactly(6).times.and_return(false)
        @bootstrap = Chef::Knife::Bootstrap.new
        allow(Chef::Knife::Bootstrap).to receive(:new).and_return(@bootstrap)
        expect(@server_instance).to receive(:wait_until_virtual_machine_ready).exactly(1).times.and_return(true)
        expect(@bootstrap).to receive(:run)
        @server_instance.run
      end

      context "ssh key" do
        before do
          Chef::Config[:knife][:ssh_password] = ''
          Chef::Config[:knife][:identity_file] = 'path_to_rsa_private_key'
        end

        it "check if ssh-key set correctly" do
          expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(false)
          @server_params = @server_instance.create_server_def
          expect(@server_params[:os_type]).to be == 'Linux'
          expect(@server_params[:identity_file]).to be == 'path_to_rsa_private_key'
          expect(@server_params[:ssh_user]).to be == 'ssh_user'
          expect(@server_params[:bootstrap_proto]).to be == 'ssh'
          expect(@server_params[:azure_dns_name]).to be == 'service001'
        end

        it "successful bootstrap with ssh key" do
          expect(@server_instance).to receive(:is_image_windows?).exactly(6).times.and_return(false)
          @bootstrap = Chef::Knife::Bootstrap.new
          allow(Chef::Knife::Bootstrap).to receive(:new).and_return(@bootstrap)
          expect(@bootstrap).to receive(:run)
          allow(@server_instance.connection.certificates).to receive(:generate_public_key_certificate_data).and_return("cert_data")
          expect(@server_instance.connection.certificates).to receive(:create)
          @server_instance.run
        end
      end

      context "bootstrap" do
        before do
          @server_params = @server_instance.create_server_def
          @bootstrap = Chef::Knife::Bootstrap.new
          allow(Chef::Knife::Bootstrap).to receive(:new).and_return(@bootstrap)
        end

        it "enables sudo password when ssh_user is not root" do
          expect(@bootstrap).to receive(:run)
          @server_instance.run
          expect(@bootstrap.config[:use_sudo_password]).to be true
        end

        it "does not enable sudo password when ssh_user is root" do
          expect(@bootstrap).to receive(:run)
          Chef::Config[:knife][:ssh_user] = 'root'
          @server_instance.run
          expect(@bootstrap.config[:use_sudo_password]).to_not be true
        end

        it "sets secret parameter" do
          expect(@bootstrap).to receive(:run)
          Chef::Config[:knife][:secret] = 'test_secret'
          @server_instance.run
          expect(@bootstrap.config[:secret]).to be == 'test_secret'
        end

        it "sets secret file parameter" do
          expect(@bootstrap).to receive(:run)
          Chef::Config[:knife][:secret_file] = 'test_secret_file'
          @server_instance.run
          expect(@bootstrap.config[:secret_file]).to be == 'test_secret_file'
        end

        it "sets secret file parameter" do
          expect(@bootstrap).to receive(:run)
          Chef::Config[:knife][:secret_file] = 'test_secret_file'
          @server_instance.run
          expect(@bootstrap.config[:secret_file]).to be == 'test_secret_file'
        end

        it "sets first_boot_attributes to empty hash when json_attributes parameter not specified" do
          expect(@bootstrap).to receive(:run)
          @server_instance.run
          expect(@bootstrap.config[:first_boot_attributes]).to be == {}
        end

        it "sets first_boot_attributes when json_attributes parameter specified" do
          expect(@bootstrap).to receive(:run)
          Chef::Config[:knife][:json_attributes] = '{"keyattr":"value"}'
          @server_instance.run
          expect(@bootstrap.config[:first_boot_attributes]).to be == '{"keyattr":"value"}'
        end
      end
    end
  end

  describe "for --auto-udpate-client and --delete-chef-extension-config" do
    before do
      allow(@server_instance).to receive(:msg_server_summary)
      Chef::Config[:knife][:run_list] = ['getting-started']
      Chef::Config[:knife][:validation_client_name] = 'testorg-validator'
      Chef::Config[:knife][:chef_server_url] = 'https://api.opscode.com/organizations/testorg'
    end

    after do
      Chef::Config[:knife].delete(:bootstrap_protocol)
      Chef::Config[:knife].delete(:run_list)
      Chef::Config[:knife].delete(:validation_client_name)
      Chef::Config[:knife].delete(:chef_server_url)
    end

    context 'option --bootstrap-protocol cloud-api not passed' do
      it 'throws error and server create command fails.' do
        @server_instance.config[:auto_update_client] = true
        @server_instance.config[:delete_chef_extension_config] = true
        allow(@server_instance.ui).to receive(:error)
        expect {@server_instance.run}.to raise_error
      end
    end
  end

  describe "for bootstrap protocol cloud-api:" do
    before do
      Chef::Config[:knife][:bootstrap_protocol] = 'cloud-api'
      allow(@server_instance).to receive(:msg_server_summary)
      Chef::Config[:knife][:run_list] = ["getting-started"]
      Chef::Config[:knife][:validation_client_name] = "testorg-validator"
      Chef::Config[:knife][:chef_server_url] = "https://api.opscode.com/organizations/testorg"
    end

    after do
      Chef::Config[:knife].delete(:bootstrap_protocol)
      Chef::Config[:knife].delete(:run_list)
      Chef::Config[:knife].delete(:validation_client_name)
      Chef::Config[:knife].delete(:chef_server_url)
    end

    context "get_chef_extension_public_params" do
      it "should set autoUpdateClient flag to true" do
        @server_instance.config[:auto_update_client] = true
        public_config = "{\"client_rb\":\"chef_server_url \\t \\\"https://localhost:443\\\"\\nvalidation_client_name\\t\\\"chef-validator\\\"\",\"runlist\":\"\\\"getting-started\\\"\",\"autoUpdateClient\":\"true\",\"deleteChefConfig\":\"false\",\"custom_json_attr\":{},\"bootstrap_options\":{\"chef_server_url\":\"https://localhost:443\",\"validation_client_name\":\"chef-validator\"}}"

        expect(Base64).to receive(:encode64).with(public_config)
        @server_instance.get_chef_extension_public_params
      end

      it "should set autoUpdateClient flag to false" do
        @server_instance.config[:auto_update_client] = false
        public_config = "{\"client_rb\":\"chef_server_url \\t \\\"https://localhost:443\\\"\\nvalidation_client_name\\t\\\"chef-validator\\\"\",\"runlist\":\"\\\"getting-started\\\"\",\"autoUpdateClient\":\"false\",\"deleteChefConfig\":\"false\",\"custom_json_attr\":{},\"bootstrap_options\":{\"chef_server_url\":\"https://localhost:443\",\"validation_client_name\":\"chef-validator\"}}"

        expect(Base64).to receive(:encode64).with(public_config)
        @server_instance.get_chef_extension_public_params
      end

      it "sets deleteChefConfig flag to true" do
        @server_instance.config[:delete_chef_extension_config] = true
        public_config = "{\"client_rb\":\"chef_server_url \\t \\\"https://localhost:443\\\"\\nvalidation_client_name\\t\\\"chef-validator\\\"\",\"runlist\":\"\\\"getting-started\\\"\",\"autoUpdateClient\":\"false\",\"deleteChefConfig\":\"true\",\"custom_json_attr\":{},\"bootstrap_options\":{\"chef_server_url\":\"https://localhost:443\",\"validation_client_name\":\"chef-validator\"}}"

        expect(Base64).to receive(:encode64).with(public_config)
        @server_instance.get_chef_extension_public_params
      end

      it "sets deleteChefConfig flag to false" do
        @server_instance.config[:delete_chef_extension_config] = false
        public_config = "{\"client_rb\":\"chef_server_url \\t \\\"https://localhost:443\\\"\\nvalidation_client_name\\t\\\"chef-validator\\\"\",\"runlist\":\"\\\"getting-started\\\"\",\"autoUpdateClient\":\"false\",\"deleteChefConfig\":\"false\",\"custom_json_attr\":{},\"bootstrap_options\":{\"chef_server_url\":\"https://localhost:443\",\"validation_client_name\":\"chef-validator\"}}"

        expect(Base64).to receive(:encode64).with(public_config)
        @server_instance.get_chef_extension_public_params
      end

      it "sets bootstrapVersion variable in public_config" do
        @server_instance.config[:bootstrap_version] = '12.4.2'
        public_config = "{\"client_rb\":\"chef_server_url \\t \\\"https://localhost:443\\\"\\nvalidation_client_name\\t\\\"chef-validator\\\"\",\"runlist\":\"\\\"getting-started\\\"\",\"autoUpdateClient\":\"false\",\"deleteChefConfig\":\"false\",\"custom_json_attr\":{},\"bootstrap_options\":{\"chef_server_url\":\"https://localhost:443\",\"validation_client_name\":\"chef-validator\",\"bootstrap_version\":\"12.4.2\"}}"

        expect(Base64).to receive(:encode64).with(public_config)
        @server_instance.get_chef_extension_public_params
      end
    end

    context "get azure chef extension version" do
      it "take user specified verison" do
        Chef::Config[:knife][:azure_chef_extension_version] = "1200.12"
        expect(@server_instance.get_chef_extension_version).to eq("1200.12")
      end
    end

    context "windows instance:" do
      it "successful create" do
        expect(@server_instance).to_not receive(:bootstrap_exec)
        expect(@server_instance).to receive(:get_chef_extension_version)
        expect(@server_instance).to receive(:get_chef_extension_public_params)
        expect(@server_instance).to receive(:get_chef_extension_private_params)
        expect(@server_instance).to receive(:is_image_windows?).exactly(4).times.and_return(true)
        expect(@server_instance).to receive(:wait_until_virtual_machine_ready).exactly(1).times.and_return(true)
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        testxml.css('InputEndpoint Protocol:contains("TCP")').each do | port |
          expect(port.parent.css("LocalPort").text).to_not eq("5985")
        end
      end

      it "check if all server params are set correctly" do
        version = Nokogiri::XML::Builder.new do |xml|
          xml.ResourceExtensionReferences {
            xml.Version "11.12"
          }
        end
        expect(@server_instance).to_not receive(:bootstrap_exec)

        allow(@server_instance.connection).to receive(:query_azure).and_return(version.doc)
        expect(@server_instance).to receive(:get_chef_extension_public_params)
        expect(@server_instance).to receive(:get_chef_extension_private_params)
        expect(@server_instance).to receive(:is_image_windows?).exactly(4).times.and_return(true)
        server_config = @server_instance.create_server_def
        expect(server_config[:chef_extension]).to eq("ChefClient")
        expect(server_config[:chef_extension_publisher]).to eq("Chef.Bootstrap.WindowsAzure")
        expect(server_config[:chef_extension_version]).to eq("11.*")
        expect(server_config).to include(:chef_extension_public_param)
        expect(server_config).to include(:chef_extension_private_param)
      end
    end

    context "linux instance" do
      it "successful create" do
        expect(@server_instance).to_not receive(:bootstrap_exec)
        expect(@server_instance).to receive(:get_chef_extension_version)
        expect(@server_instance).to receive(:get_chef_extension_public_params)
        expect(@server_instance).to receive(:get_chef_extension_private_params)
        expect(@server_instance).to receive(:is_image_windows?).exactly(4).times.and_return(false)
        expect(@server_instance).to receive(:wait_until_virtual_machine_ready).exactly(1).times.and_return(true)
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        testxml.css('InputEndpoint Protocol:contains("TCP")').each do | port |
          expect(port.parent.css("LocalPort").text).to eq("22")
        end
      end

      it "check if all server params are set correctly" do
        version = Nokogiri::XML::Builder.new do |xml|
          xml.ResourceExtensionReferences {
            xml.Version "11.12"
          }
        end
        expect(@server_instance).to_not receive(:bootstrap_exec)
        allow(@server_instance.connection).to receive(:query_azure).and_return(version.doc)
        expect(@server_instance).to receive(:get_chef_extension_private_params)
        expect(@server_instance).to receive(:is_image_windows?).exactly(4).times.and_return(false)
        server_config = @server_instance.create_server_def
        expect(server_config[:chef_extension]).to eq("LinuxChefClient")
        expect(server_config[:chef_extension_publisher]).to eq("Chef.Bootstrap.WindowsAzure")
        expect(server_config[:chef_extension_version]).to eq("11.*")
        expect(server_config).to include(:chef_extension_public_param)
        expect(JSON.parse(Base64.decode64(server_config[:chef_extension_public_param]))["runlist"]).to eq(Chef::Config[:knife][:run_list].first.to_json)
        expect(server_config).to include(:chef_extension_private_param)
      end
    end

    context 'when validation key is not present', :chef_gte_12_only do
      before do
        allow(File).to receive(:exist?).and_return(false)
        Chef::Config[:knife] = { chef_node_name: 'foo.example.com' }
      end

      it 'calls get chef extension private params and adds client pem in json object' do
        allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:run)
        allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:client_path)
        allow(File).to receive(:read).and_return('foo')
        pri_config = { client_pem: 'foo' }
        expect(Base64).to receive(:encode64).with(pri_config.to_json)
        @server_instance.get_chef_extension_private_params
      end
    end

    context "when validation key is not present, using chef 11", :chef_lt_12_only do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it 'raises an exception if validation_key is not present in chef 11' do
        expect(@server_instance.ui).to receive(:error)
        expect { @server_instance.run }.to raise_error(SystemExit)
      end
    end
  end
end
