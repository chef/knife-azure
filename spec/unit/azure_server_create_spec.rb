#
# Author:: Mukta Aphale (<mukta.aphale@clogeny.com>)
# Copyright:: Copyright 2010-2019, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/../unit/query_azure_mock")
require "chef/knife/bootstrap"
require "active_support/core_ext/hash/conversions"

describe Chef::Knife::AzureServerCreate do
  include AzureSpecHelper
  include QueryAzureMock
  include AzureUtility

  before do
    @server_instance = Chef::Knife::AzureServerCreate.new
    {
      azure_subscription_id: "azure_subscription_id",
      azure_mgmt_cert: @cert_file,
      azure_api_host_name: "preview.core.windows-int.net",
      azure_service_location: "West Europe",
      azure_source_image: "SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd",
      azure_dns_name: "service001",
      azure_vm_name: "vm002",
      azure_storage_account: "ka001testeurope",
      azure_vm_size: "Small",
      connection_user: "test-user",
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    stub_query_azure @server_instance.service.connection
    @connection = @server_instance.service.connection
    allow(@server_instance).to receive(:tcp_test_ssh).and_return(true)
    allow(@server_instance).to receive(:tcp_test_winrm).and_return(true)
    @server_instance.initial_sleep_delay = 0
    allow(@server_instance).to receive(:sleep).and_return(0)
    allow(@server_instance).to receive(:puts)
    allow(@server_instance).to receive(:print)
    allow(@server_instance).to receive(:check_license)
    allow(@server_instance).to receive(:connect!)
    allow(@server_instance).to receive(:register_client)
    allow(@server_instance).to receive(:render_template).and_return "content"
    allow(@server_instance).to receive(:upload_bootstrap).with("content").and_return "/remote/path.sh"
    allow(@server_instance).to receive(:perform_bootstrap).with("/remote/path.sh")
  end

  def test_params(testxml, chef_config, role_name, host_name)
    expect(xml_content(testxml, "UserName")).to be == chef_config[:connection_user]
    expect(xml_content(testxml, "UserPassword")).to be == chef_config[:connection_password]
    expect(xml_content(testxml, "SourceImageName")).to be == chef_config[:azure_source_image]
    expect(xml_content(testxml, "RoleSize")).to be == chef_config[:azure_vm_size]
    expect(xml_content(testxml, "HostName")).to be == host_name
    expect(xml_content(testxml, "RoleName")).to be == role_name
  end

  describe "parameter test:" do
    context "compulsory parameters" do
      it "azure_subscription_id" do
        Chef::Config[:knife].delete(:azure_subscription_id)
        expect(@server_instance.ui).to receive(:error)
        expect { @server_instance.run }.to raise_error(SystemExit)
      end

      it "azure_mgmt_cert" do
        Chef::Config[:knife].delete(:azure_mgmt_cert)
        expect(@server_instance.ui).to receive(:error)
        expect { @server_instance.run }.to raise_error(SystemExit)
      end

      it "azure_api_host_name" do
        Chef::Config[:knife].delete(:azure_api_host_name)
        expect(@server_instance.ui).to receive(:error)
        expect { @server_instance.run }.to raise_error(SystemExit)
      end

      it "azure_source_image" do
        Chef::Config[:knife].delete(:azure_source_image)
        expect(@server_instance.ui).to receive(:error)
        expect { @server_instance.run }.to raise_error(SystemExit)
      end

      it "azure_vm_size" do
        Chef::Config[:knife].delete(:azure_vm_size)
        expect(@server_instance.ui).to receive(:error)
        expect { @server_instance.run }.to raise_error(SystemExit)
      end

      it "azure_service_location and azure_affinity_group not allowed" do
        Chef::Config[:knife][:azure_affinity_group] = "test-affinity"
        expect(@server_instance.ui).to receive(:error)
        expect { @server_instance.run }.to raise_error(SystemExit)
      end

      it "azure_service_location or azure_affinity_group must be provided" do
        Chef::Config[:knife].delete(:azure_service_location)
        expect(@server_instance.ui).to receive(:error)
        expect { @server_instance.run }.to raise_error(SystemExit)
      end

      it "raises an error if neither --azure-dns-name or --azure-vm-name are provided" do
        Chef::Config[:knife].delete(:azure_dns_name)
        Chef::Config[:knife].delete(:azure_vm_name)
        expect(@server_instance.ui).to receive(:error)
        expect { @server_instance.run }.to raise_error(SystemExit)
      end

      context "when winrm authentication protocol invalid" do
        it "raise error" do
          Chef::Config[:knife][:winrm_auth_method] = "invalide"
          expect(@server_instance.ui).to receive(:error)
          expect { @server_instance.run }.to raise_error(SystemExit)
        end
      end

      context "when winrm-ssl ssl and missing thumbprint" do
        it "raise error if :winrm_no_verify_cert is not set" do
          Chef::Config[:knife][:winrm_ssl] = true
          Chef::Config[:knife][:winrm_no_verify_cert] = true
          expect(@server_instance.ui).to receive(:error)
          expect { @server_instance.run }.to raise_error(SystemExit)
        end
      end
    end

    context "validate parameters" do
      it "raise error if daemon option is not provided for windows node" do
        Chef::Config[:knife][:daemon] = "service"
        expect { @server_instance.run }.to raise_error(
          ArgumentError, "The daemon option is only supported for Windows nodes."
        )
      end

      it "raises error if invalid value is provided for daemon option" do
        allow(@server_instance).to receive(:is_image_windows?).and_return(true)
        Chef::Config[:knife][:daemon] = "foo"
        Chef::Config[:knife][:connection_protocol] = "cloud-api"
        expect { @server_instance.run }.to raise_error(
          ArgumentError, "Invalid value for --daemon option. Valid values are 'none', 'service' and 'task'."
        )
      end

      it "raises error if connection_protocol is not cloud-api for daemon option" do
        allow(@server_instance).to receive(:is_image_windows?).and_return(true)
        Chef::Config[:knife][:daemon] = "service"
        expect { @server_instance.run }.to raise_error(
          ArgumentError, "The --daemon option requires the use of --bootstrap-protocol cloud-api"
        )
      end

      it "does not raise error if daemon option value is 'service'" do
        allow(@server_instance).to receive(:is_image_windows?).and_return(true)
        Chef::Config[:knife][:daemon] = "service"
        Chef::Config[:knife][:connection_protocol] = "cloud-api"
        expect { @server_instance.run }.not_to raise_error(
          ArgumentError, "Invalid value for --daemon option. Use valid daemon values i.e 'none', 'service' and 'task'."
        )
      end

      it "does not raise error if daemon option value is 'none'" do
        allow(@server_instance).to receive(:is_image_windows?).and_return(true)
        Chef::Config[:knife][:daemon] = "none"
        Chef::Config[:knife][:connection_protocol] = "cloud-api"
        expect { @server_instance.run }.not_to raise_error(
          ArgumentError, "Invalid value for --daemon option. Use valid daemon values i.e 'none', 'service' and 'task'."
        )
      end

      it "does not raise error if daemon option value is 'task'" do
        allow(@server_instance).to receive(:is_image_windows?).and_return(true)
        Chef::Config[:knife][:daemon] = "task"
        Chef::Config[:knife][:connection_protocol] = "cloud-api"
        expect { @server_instance.run }.not_to raise_error(
          ArgumentError, "Invalid value for --daemon option. Use valid daemon values i.e 'none', 'service' and 'task'."
        )
      end
    end

    context "timeout parameters" do
      it "uses correct values when not specified" do
        expect(@server_instance.options[:azure_vm_startup_timeout][:default].to_i).to eq(10)
        expect(@server_instance.options[:azure_vm_ready_timeout][:default].to_i).to eq(15)
      end

      it "matches the CLI options" do
        # Set params to non-default values
        Chef::Config[:knife][:azure_vm_startup_timeout] = 5
        Chef::Config[:knife][:azure_vm_ready_timeout] = 10
        expect(@server_instance.send(:locate_config_value, :azure_vm_startup_timeout).to_i).to eq(Chef::Config[:knife][:azure_vm_startup_timeout])
        expect(@server_instance.send(:locate_config_value, :azure_vm_ready_timeout).to_i).to eq(Chef::Config[:knife][:azure_vm_ready_timeout])
      end
    end

    context "server create options" do
      before do
        Chef::Config[:knife][:connection_protocol] = "ssh"
        Chef::Config[:knife][:connection_user] = "connection_user"
        Chef::Config[:knife][:connection_password] = "connection_password"
        Chef::Config[:knife].delete(:azure_vm_name)
        Chef::Config[:knife].delete(:azure_storage_account)
        allow(@server_instance).to receive(:msg_server_summary)
      end

      it "quick create" do
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(false)
        Chef::Config[:knife][:azure_dns_name] = "vmname" # service name to be used as vm name
        expect(@server_instance).to receive(:get_dns_name)
        @server_instance.run
        expect(@server_instance.config[:azure_vm_name]).to be == "vmname"
        testxml = Nokogiri::XML(@receivedXML)
        expect(xml_content(testxml, "MediaLink")).to_not be nil
        expect(xml_content(testxml, "DiskName")).to_not be nil
        test_params(testxml, Chef::Config[:knife], Chef::Config[:knife][:azure_dns_name],
          Chef::Config[:knife][:azure_dns_name])
      end

      it "quick create with wirm - API check" do
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(true)
        Chef::Config[:knife][:azure_dns_name] = "vmname" # service name to be used as vm name
        Chef::Config[:knife][:connection_user] = "opscodechef"
        Chef::Config[:knife][:connection_password] = "Opscode123"
        Chef::Config[:knife][:connection_protocol] = "winrm"
        expect(@server_instance).to receive(:get_dns_name)
        @server_instance.run
        expect(@server_instance.config[:azure_vm_name]).to be == "vmname"
        testxml = Nokogiri::XML(@receivedXML)
        expect(xml_content(testxml, "WinRM")).to_not be nil
        expect(xml_content(testxml, "Listeners")).to_not be nil
        expect(xml_content(testxml, "Listener")).to_not be nil
        expect(xml_content(testxml, "Protocol")).to be == "Http"
      end

      it "generate unique OS DiskName" do
        os_disks = []
        allow(@bootstrap).to receive(:run)
        allow(@server_instance).to receive(:validate_asm_keys!)
        Chef::Config[:knife][:azure_dns_name] = "vmname"

        5.times do
          @server_instance.run
          testxml = Nokogiri::XML(@receivedXML)
          disklink = xml_content(testxml, "MediaLink")
          expect(os_disks).to_not include(disklink)
          os_disks.push(disklink)
        end
      end

      it "skip user specified tcp-endpoints if its ports already use by ssh endpoint" do
        # Default external port for ssh endpoint is 22.
        @server_instance.config[:tcp_endpoints] = "12:22"
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(false)
        Chef::Config[:knife][:azure_dns_name] = "vmname" # service name to be used as vm name
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        testxml.css('InputEndpoint Protocol:contains("TCP")').each do |port|
          # Test data in @server_instance.config[:tcp_endpoints]:=> "12:22" this endpoints external port 22 is already use by ssh endpoint. So it should skip endpoint "12:22".
          expect(port.parent.css("LocalPort").text).to_not eq("12")
        end
      end

      it "advanced create" do
        # set all params
        Chef::Config[:knife][:azure_dns_name] = "service001"
        Chef::Config[:knife][:azure_vm_name] = "vm002"
        Chef::Config[:knife][:azure_storage_account] = "ka001testeurope"
        Chef::Config[:knife][:azure_os_disk_name] = "os-disk"
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        expect(xml_content(testxml, "MediaLink")).to be == "http://ka001testeurope.blob.core.windows-int.net/vhds/os-disk.vhd"
        expect(xml_content(testxml, "DiskName")).to be == Chef::Config[:knife][:azure_os_disk_name]
        test_params(testxml, Chef::Config[:knife], Chef::Config[:knife][:azure_vm_name],
          Chef::Config[:knife][:azure_vm_name])
      end

      it "create with availability set" do
        # set all params
        Chef::Config[:knife][:azure_dns_name] = "service001"
        Chef::Config[:knife][:azure_vm_name] = "vm002"
        Chef::Config[:knife][:azure_storage_account] = "ka001testeurope"
        Chef::Config[:knife][:azure_os_disk_name] = "os-disk"
        Chef::Config[:knife][:azure_availability_set] = "test-availability-set"
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        expect(xml_content(testxml, "AvailabilitySetName")).to be == "test-availability-set"
      end

      it "server create with virtual network and subnet" do
        Chef::Config[:knife][:azure_dns_name] = "vmname"
        Chef::Config[:knife][:azure_network_name] = "test-network"
        Chef::Config[:knife][:azure_subnet_name] = "test-subnet"
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        expect(xml_content(testxml, "SubnetName")).to be == "test-subnet"
      end

      it "creates new load balanced endpoints" do
        Chef::Config[:knife][:azure_dns_name] = "vmname"
        @server_instance.config[:tcp_endpoints] = "80:80:EXTERNAL:lb_set,443:443:EXTERNAL:lb_set_ssl:/healthcheck" # TODO: is this a good way of specifying this?
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(false)
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        endpoints = testxml.css("InputEndpoint")

        # Should be 3 endpoints, 1 for SSH, 1 for port 80 using LB set name lb_set, and 1 for port 443 using lb_set2 and with healtcheck path.
        expect(endpoints.count).to be == 3

        # Convert it to a hash as it's easier to test.
        eps = []
        endpoints.each do |ep|
          eps << Hash.from_xml(ep.to_s)
        end

        expect(eps[0]["InputEndpoint"]["Name"]).to be == "SSH"

        lb_set_ep = eps[1]["InputEndpoint"]
        expect(lb_set_ep["LoadBalancedEndpointSetName"]).to be == "lb_set"
        expect(lb_set_ep["LocalPort"]).to be == "80"
        expect(lb_set_ep["Port"]).to be == "80"
        expect(lb_set_ep["Protocol"]).to be == "TCP"
        expect(lb_set_ep["LoadBalancerProbe"]["Port"]).to be == "80"
        expect(lb_set_ep["LoadBalancerProbe"]["Protocol"]).to be == "TCP"

        lb_set2_ep = eps[2]["InputEndpoint"]
        expect(lb_set2_ep["LoadBalancedEndpointSetName"]).to be == "lb_set_ssl"
        expect(lb_set2_ep["LocalPort"]).to be == "443"
        expect(lb_set2_ep["Port"]).to be == "443"
        expect(lb_set2_ep["Protocol"]).to be == "TCP"
        expect(lb_set2_ep["LoadBalancerProbe"]["Path"]).to be == "/healthcheck"
        expect(lb_set2_ep["LoadBalancerProbe"]["Port"]).to be == "443"
        expect(lb_set2_ep["LoadBalancerProbe"]["Protocol"]).to be == "HTTP"
      end

      it "re-uses existing load balanced endpoints" do
        Chef::Config[:knife][:azure_dns_name] = "vmname"
        @server_instance.config[:tcp_endpoints] = "443:443:EXTERNAL:lb_set2:/healthcheck"
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(false)

        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        endpoints = testxml.css("InputEndpoint")

        expect(endpoints.count).to be == 2

        # Convert it to a hash as it's easier to test.
        eps = []
        endpoints.each do |ep|
          eps << Hash.from_xml(ep.to_s)
        end
        expect(eps[0]["InputEndpoint"]["Name"]).to be == "SSH"

        lb_set2_ep = eps[1]["InputEndpoint"]
        expect(lb_set2_ep["LoadBalancedEndpointSetName"]).to be == "lb_set2"
        expect(lb_set2_ep["LocalPort"]).to be == "443"
        expect(lb_set2_ep["Port"]).to be == "443"
        expect(lb_set2_ep["Protocol"]).to be == "tcp"
        expect(lb_set2_ep["LoadBalancerProbe"]["Path"]).to be == "/healthcheck2" # The existing one wins. The 'healthcheck2' value is defined in the stub.
        expect(lb_set2_ep["LoadBalancerProbe"]["Port"]).to be == "443"
        expect(lb_set2_ep["LoadBalancerProbe"]["Protocol"]).to be == "http"
      end

      it "allows internal load balancer to be specified" do
        Chef::Config[:knife][:azure_dns_name] = "vmname"
        @server_instance.config[:tcp_endpoints] = "80:80:internal-lb-name:lb_set" # TODO: is this a good way of specifying this?
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(false)

        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        endpoints = testxml.css("InputEndpoint")
        expect(endpoints.count).to be == 2

        # Convert it to a hash as it's easier to test.
        eps = []
        endpoints.each do |ep|
          eps << Hash.from_xml(ep.to_s)
        end
        expect(eps[0]["InputEndpoint"]["Name"]).to be == "SSH"

        lb_set_ep = eps[1]["InputEndpoint"]
        expect(lb_set_ep["LoadBalancedEndpointSetName"]).to be == "lb_set"
        expect(lb_set_ep["LocalPort"]).to be == "80"
        expect(lb_set_ep["Port"]).to be == "80"
        expect(lb_set_ep["Protocol"]).to be == "TCP"
        expect(lb_set_ep["LoadBalancerProbe"]["Port"]).to be == "80"
        expect(lb_set_ep["LoadBalancerProbe"]["Protocol"]).to be == "TCP"
        expect(lb_set_ep["LoadBalancerName"]).to be == "internal-lb-name"
      end

      it "server create display server summary" do
        Chef::Config[:knife][:azure_dns_name] = "vmname"
        expect(@server_instance).to receive(:msg_server_summary)
        @server_instance.run
      end

      context "Domain join:" do
        before do
          Chef::Config[:knife][:azure_dns_name] = "vmname"
          allow(@server_instance).to receive(:is_image_windows?).and_return(true)
          Chef::Config[:knife][:connection_protocol] = "winrm"
          Chef::Config[:knife][:connection_user] = "testuser"
          Chef::Config[:knife][:connection_password] = "connection_password"
        end

        it "server create with domain join options" do
          Chef::Config[:knife][:azure_domain_name] = "testad.com"
          Chef::Config[:knife][:azure_domain_user] = "domainuser"
          Chef::Config[:knife][:azure_domain_passwd] = "domainuserpass"
          @server_instance.run
          testxml = Nokogiri::XML(@receivedXML)
          expect(xml_content(testxml, "DomainJoin Credentials Domain")).to eq("testad.com")
          expect(xml_content(testxml, "DomainJoin Credentials Username")).to eq("domainuser")
          expect(xml_content(testxml, "DomainJoin Credentials Password")).to eq("domainuserpass")
          expect(xml_content(testxml, "JoinDomain")).to eq("testad.com")
        end

        it "server create with domain join options in user principal name (UPN) format (user@fully-qualified-DNS-domain)" do
          Chef::Config[:knife][:azure_domain_user] = "domainuser@testad.com"
          Chef::Config[:knife][:azure_domain_passwd] = "domainuserpass"
          @server_instance.run
          testxml = Nokogiri::XML(@receivedXML)
          expect(xml_content(testxml, "DomainJoin Credentials Domain")).to eq("testad.com")
          expect(xml_content(testxml, "DomainJoin Credentials Username")).to eq("domainuser")
          expect(xml_content(testxml, "DomainJoin Credentials Password")).to eq("domainuserpass")
          expect(xml_content(testxml, "JoinDomain")).to eq("testad.com")
        end

        it 'server create with domain join options in fully-qualified-DNS-domain\\username format' do
          Chef::Config[:knife][:azure_domain_user] = 'testad.com\\domainuser'
          Chef::Config[:knife][:azure_domain_passwd] = "domainuserpass"
          @server_instance.run
          testxml = Nokogiri::XML(@receivedXML)
          expect(xml_content(testxml, "DomainJoin Credentials Domain")).to eq("testad.com")
          expect(xml_content(testxml, "DomainJoin Credentials Username")).to eq("domainuser")
          expect(xml_content(testxml, "DomainJoin Credentials Password")).to eq("domainuserpass")
          expect(xml_content(testxml, "JoinDomain")).to eq("testad.com")
        end

        it "server create with domain join options including name of the organizational unit (OU) in which the computer account is created" do
          Chef::Config[:knife][:azure_domain_user] = 'testad.com\\domainuser'
          Chef::Config[:knife][:azure_domain_passwd] = "domainuserpass"
          Chef::Config[:knife][:azure_domain_ou_dn] = "OU=HR,dc=opscode,dc=com"
          @server_instance.run
          testxml = Nokogiri::XML(@receivedXML)
          expect(xml_content(testxml, "DomainJoin Credentials Domain")).to eq("testad.com")
          expect(xml_content(testxml, "DomainJoin Credentials Username")).to eq("domainuser")
          expect(xml_content(testxml, "DomainJoin Credentials Password")).to eq("domainuserpass")
          expect(xml_content(testxml, "DomainJoin MachineObjectOU")).to eq("OU=HR,dc=opscode,dc=com")
          expect(xml_content(testxml, "JoinDomain")).to eq("testad.com")
        end
      end
    end

    context "missing create options" do
      before do
        Chef::Config[:knife][:connection_protocol] = "winrm"
        Chef::Config[:knife][:connection_user] = "testuser"
        Chef::Config[:knife][:connection_password] = "connection_password"
        Chef::Config[:knife].delete(:azure_vm_name)
        Chef::Config[:knife].delete(:azure_storage_account)
      end

      it "should error if domain user is not specified for domain join" do
        Chef::Config[:knife][:azure_dns_name] = "vmname"
        allow(@server_instance).to receive(:is_image_windows?).and_return(true)

        Chef::Config[:knife][:azure_domain_name] = "testad.com"
        Chef::Config[:knife][:azure_domain_passwd] = "domainuserpass"
        expect(@server_instance.ui).to receive(:error).with("Must specify both --azure-domain-user and --azure-domain-passwd.")
        expect { @server_instance.run }.to raise_error(SystemExit)
      end

      it "should error if password for domain user is not specified for domain join" do
        Chef::Config[:knife][:azure_dns_name] = "vmname"
        allow(@server_instance).to receive(:is_image_windows?).and_return(true)

        Chef::Config[:knife][:azure_domain_name] = "testad.com"
        Chef::Config[:knife][:azure_domain_user] = "domainuser"
        expect(@server_instance.ui).to receive(:error).with("Must specify both --azure-domain-user and --azure-domain-passwd.")
        expect { @server_instance.run }.to raise_error(SystemExit)
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
        expect { @server_instance.service.cleanup_and_exit("hosted_srvc", "storage_srvc") }.to raise_error(NoMethodError)
      end

      it "service leak cleanup with nil params" do
        expect(@server_instance.service.connection.hosts).to_not receive(:delete)
        expect(@server_instance.service.connection.storageaccounts).to_not receive(:delete)
        expect { @server_instance.service.cleanup_and_exit(nil, nil) }.to raise_error(SystemExit)
      end

      it "service leak cleanup with valid params" do
        ret_val = Object.new
        ret_val.define_singleton_method(:content) { "" }
        expect(@server_instance.service.connection.hosts).to receive(:delete).with("hosted_srvc").and_return(ret_val)
        expect(@server_instance.service.connection.storageaccounts).to receive(:delete).with("storage_srvc").and_return(ret_val)
        expect { @server_instance.service.cleanup_and_exit("hosted_srvc", "storage_srvc") }.to raise_error(SystemExit)
      end

      it "display proper warn messages on cleanup fails" do
        ret_val = Object.new
        ret_val.define_singleton_method(:content) { "ConflictError" }
        ret_val.define_singleton_method(:text) { "ConflictError" }
        expect(@server_instance.service.connection.hosts).to receive(:delete).with("hosted_srvc").and_return(ret_val)
        expect(@server_instance.service.connection.storageaccounts).to receive(:delete).with("storage_srvc").and_return(ret_val)
        expect { @server_instance.service.cleanup_and_exit("hosted_srvc", "storage_srvc") }.to raise_error(SystemExit)
      end
    end

    context "connect to existing DNS tests" do
      before do
        Chef::Config[:knife][:azure_connect_to_existing_dns] = true
      end

      it "should throw error when DNS does not exist" do
        Chef::Config[:knife][:azure_dns_name] = "does-not-exist"
        Chef::Config[:knife][:connection_user] = "azureuser"
        Chef::Config[:knife][:connection_password] = "Jetstream123!"
        expect { @server_instance.run }.to raise_error(SystemExit)
      end

      it "port should be unique number when connection-port not specified for winrm", :chef_lt_12_only do
        Chef::Config[:knife][:connection_port] = nil
        Chef::Config[:knife][:azure_dns_name] = "service001"
        Chef::Config[:knife][:azure_vm_name] = "newvm01"
        Chef::Config[:knife][:connection_protocol] = "winrm"
        Chef::Config[:knife][:connection_user] = "testuser"
        Chef::Config[:knife][:connection_password] = "Jetstream123!"
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:port]).to be == "5985"
      end

      it "port should be connection-port value specified in the option" do
        Chef::Config[:knife][:connection_protocol] = "winrm"
        Chef::Config[:knife][:connection_user] = "testuser"
        Chef::Config[:knife][:connection_password] = "Jetstream123!"
        Chef::Config[:knife][:connection_port] = "5990"
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:port]).to be == "5990"
      end

      it "extract user name when --connection-user contains domain name" do
        Chef::Config[:knife][:connection_protocol] = "winrm"
        Chef::Config[:knife][:connection_user] = 'domain\\testuser'
        Chef::Config[:knife][:connection_password] = "Jetstream123!"
        Chef::Config[:knife][:connection_port] = "5990"
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:connection_user]).to be == "testuser"
      end

      it "port should be unique number when connection-port not specified for linux image" do
        Chef::Config[:knife][:connection_user] = "azureuser"
        Chef::Config[:knife][:connection_password] = "Jetstream123!"
        Chef::Config[:knife][:connection_protocol] = "ssh"
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(false)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:port]).to_not be == "22"
      end

      it "port should be connection-port value specified in the option" do
        Chef::Config[:knife][:connection_protocol] = "ssh"
        Chef::Config[:knife][:connection_user] = "azureuser"
        Chef::Config[:knife][:connection_password] = "Jetstream123!"
        Chef::Config[:knife][:connection_port] = "24"
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(false)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:port]).to be == "24"
      end

      it "port should be 22 if user specified --connection-port 22" do
        Chef::Config[:knife][:connection_protocol] = "ssh"
        Chef::Config[:knife][:connection_user] = "azureuser"
        Chef::Config[:knife][:connection_password] = "Jetstream123!"
        Chef::Config[:knife][:connection_port] = "22"
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(false)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:port]).to be == "22"
      end

      it "port should be 5985 if user specified --connection-port 5985" do
        Chef::Config[:knife][:connection_user] = "azureuser"
        Chef::Config[:knife][:connection_password] = "Jetstream123!"
        Chef::Config[:knife][:connection_port] = "5985"
        Chef::Config[:knife][:connection_protocol] = "winrm"
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:port]).to be == "5985"
      end
    end
  end

  describe "for connection protocol winrm:" do
    before do
      Chef::Config[:knife][:connection_protocol] = "winrm"
      Chef::Config[:knife][:connection_user] = "testuser"
      Chef::Config[:knife][:connection_password] = "connection_password"
      allow(@server_instance.ui).to receive(:error)
      allow(@server_instance).to receive(:msg_server_summary)
    end

    it "check if all server params are set correctly" do
      expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
      @server_params = @server_instance.create_server_def
      expect(@server_params[:os_type]).to be == "Windows"
      expect(@server_params[:admin_password]).to be == "connection_password"
      expect(@server_params[:connection_protocol]).to be == "winrm"
      expect(@server_params[:azure_dns_name]).to be == "service001"
      expect(@server_params[:azure_vm_name]).to be == "vm002"
      expect(@server_params[:connection_user]).to be == "testuser"
      expect(@server_params[:port]).to be == "5985"
    end

    it "--connection-user cannot be 'administrator'" do
      expect(@server_instance).to receive(:is_image_windows?).and_return(true)
      Chef::Config[:knife][:connection_user] = "administrator"
      expect { @server_instance.create_server_def }.to raise_error(SystemExit)
    end

    it "--connection-user cannot be 'admin*'" do
      expect(@server_instance).to receive(:is_image_windows?).and_return(true)
      Chef::Config[:knife][:connection_user] = "Admin12"
      expect { @server_instance.create_server_def }.to raise_error(SystemExit)
    end

    context "bootstrap node" do
      it "successful bootstrap of windows instance" do
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        expect(@server_instance).to receive(:wait_until_virtual_machine_ready).exactly(1).times.and_return(true)
        @server_instance.run
      end

      it "sets encrypted data bag secret parameter" do
        Chef::Config[:knife][:encrypted_data_bag_secret] = "test_encrypted_data_bag_secret"
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        @server_instance.run
        expect(@server_instance.locate_config_value(:encrypted_data_bag_secret)).to be == "test_encrypted_data_bag_secret"
      end

      it "sets encrypted data bag secret file parameter" do
        Chef::Config[:knife][:encrypted_data_bag_secret_file] = "test_encrypted_data_bag_secret_file"
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        @server_instance.run
        expect(@server_instance.locate_config_value(:encrypted_data_bag_secret_file)).to be == "test_encrypted_data_bag_secret_file"
      end

      it "sets winrm authentication protocol for windows vm" do
        Chef::Config[:knife][:winrm_auth_method] = "negotiate"
        expect(@server_instance).to receive(:is_image_windows?).at_least(:twice).and_return(true)
        @server_instance.run
        expect(@server_instance.locate_config_value(:winrm_auth_method)).to be == "negotiate"
      end

      it "sets 'msi_url' correctly" do
        Chef::Config[:knife][:msi_url] = "https://opscode-omnibus-packages.s3.amazonaws.com/windows/2008r2/x86_64/chef-client-12.3.0-1.msi"
        allow(@server_instance).to receive(:is_image_windows?).and_return(true)
        @server_instance.run
        expect(@server_instance.locate_config_value(:msi_url)).to be == "https://opscode-omnibus-packages.s3.amazonaws.com/windows/2008r2/x86_64/chef-client-12.3.0-1.msi"
      end

      it "does not use 'install_as_service' anymore" do
        Chef::Config[:knife][:install_as_service] = true
        allow(@server_instance).to receive(:is_image_windows?).and_return(true)
        @server_instance.run
        expect(@server_instance.locate_config_value(:install_as_service)).to be_truthy
      end
    end
  end

  describe "for connection protocol ssh:" do
    before do
      Chef::Config[:knife][:connection_protocol] = "ssh"
      allow(@server_instance).to receive(:msg_server_summary)
    end

    context "windows instance:" do
      before do
        Chef::Config[:knife][:ssh_forward_agent] = true
      end

      it "sets 'ssh_forward_agent' correctly" do
        expect(@server_instance.send(:locate_config_value, :ssh_forward_agent)).to be(true)
      end
    end

    context "linux instance" do
      before do
        Chef::Config[:knife][:connection_user] = "connection_user"
        Chef::Config[:knife][:connection_password] = "connection_password"
      end

      it "check if all server params are set correctly" do
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).and_return(false)
        @server_params = @server_instance.create_server_def
        expect(@server_params[:os_type]).to be == "Linux"
        expect(@server_params[:connection_user]).to be == "connection_user"
        expect(@server_params[:connection_password]).to be == "connection_password"
        expect(@server_params[:connection_protocol]).to be == "ssh"
        expect(@server_params[:azure_dns_name]).to be == "service001"
        expect(@server_params[:azure_vm_name]).to be == "vm002"
        expect(@server_params[:port]).to be == "22"
      end

      context "ssh key" do
        before do
          Chef::Config[:knife][:connection_password] = nil
          Chef::Config[:knife][:ssh_identity_file] = "path_to_rsa_private_key"
        end

        it "check if ssh-key set correctly" do
          expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(false)
          @server_params = @server_instance.create_server_def
          expect(@server_params[:os_type]).to be == "Linux"
          expect(@server_params[:ssh_identity_file]).to be == "path_to_rsa_private_key"
          expect(@server_params[:connection_user]).to be == "connection_user"
          expect(@server_params[:connection_protocol]).to be == "ssh"
          expect(@server_params[:azure_dns_name]).to be == "service001"
        end

        it "successful bootstrap with ssh key" do
          expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(false)
          allow(@server_instance.service.connection.certificates).to receive(:generate_public_key_certificate_data).and_return("cert_data")
          expect(@server_instance.service.connection.certificates).to receive(:create)
          expect { @server_instance.run }.not_to raise_error
        end
      end

      context "bootstrap" do
        before do
          @server_params = @server_instance.create_server_def
        end

        it "enables sudo password when connection_user is not root" do
          expect { @server_instance.run }.not_to raise_error
          expect(@server_instance.locate_config_value(:use_sudo_password)).to be_nil
        end

        it "does not enable sudo password when connection_user is root" do
          Chef::Config[:knife][:connection_user] = "root"
          expect { @server_instance.run }.not_to raise_error
          expect(@server_instance.locate_config_value(:use_sudo_password)).to_not be true
        end

        it "sets secret parameter" do
          Chef::Config[:knife][:encrypted_data_bag_secret] = "test_secret"
          expect { @server_instance.run }.not_to raise_error
          expect(@server_instance.locate_config_value(:encrypted_data_bag_secret)).to eq("test_secret")
        end

        it "sets secret file parameter" do
          Chef::Config[:knife][:encrypted_data_bag_secret_file] = "test_secret_file"
          expect { @server_instance.run }.not_to raise_error
          expect(@server_instance.locate_config_value(:encrypted_data_bag_secret_file)).to eq("test_secret_file")
        end

        it "sets first_boot_attributes to empty hash when json_attributes parameter not specified" do
          expect { @server_instance.run }.not_to raise_error
          expect(@server_instance.locate_config_value(:json_attributes)).to be_nil
        end

        it "sets first_boot_attributes when json_attributes parameter specified" do
          Chef::Config[:knife][:json_attributes] = '{"keyattr":"value"}'
          expect { @server_instance.run }.not_to raise_error
          expect(@server_instance.locate_config_value(:json_attributes)).to eq('{"keyattr":"value"}')
        end
      end
    end
  end

  describe "for connection protocol cloud-api:" do
    before do
      Chef::Config[:knife][:connection_protocol] = "cloud-api"
      allow(@server_instance).to receive(:msg_server_summary)
      Chef::Config[:knife][:run_list] = ["getting-started"]
      Chef::Config[:knife][:validation_client_name] = "testorg-validator"
      Chef::Config[:knife][:chef_server_url] = "https://api.opscode.com/organizations/testorg"
    end

    after do
      Chef::Config[:knife].delete(:connection_protocol)
      Chef::Config[:knife].delete(:run_list)
      Chef::Config[:knife].delete(:validation_client_name)
      Chef::Config[:knife].delete(:chef_server_url)
    end

    context "get_chef_extension_public_params" do
      before do
        @server_instance.config[:bootstrap_version] = "12.4.2"
        @server_instance.config[:extended_logs] = true
        @server_instance.config[:chef_daemon_interval] = "16"
      end

      let(:public_config) do
        {
          client_rb: "chef_server_url \t \"https://localhost:443\"\nvalidation_client_name\t\"chef-validator\"",
          runlist: '"getting-started"',
          extendedLogs: "true",
          custom_json_attr: {},
          chef_daemon_interval: "16",
          bootstrap_options: { chef_server_url: "https://localhost:443",
                               validation_client_name: "chef-validator",
                               bootstrap_version: "12.4.2" },
        }
      end

      it "should set public config properly" do
        expect(@server_instance).to receive(:get_chef_extension_name)
        expect(@server_instance).to receive(:get_chef_extension_publisher)
        expect(@server_instance).to receive(:get_chef_extension_version)
        expect(@server_instance).to receive(:get_chef_extension_private_params)
        response = @server_instance.create_server_def
        expect(response[:chef_extension_public_param]).to be == public_config
      end

      it "should add daemon in public config if daemon options is given" do
        @server_instance.config[:daemon] = "service"
        public_config[:daemon] = "service"
        expect(@server_instance).to receive(:get_chef_extension_name)
        expect(@server_instance).to receive(:get_chef_extension_publisher)
        expect(@server_instance).to receive(:get_chef_extension_version)
        expect(@server_instance).to receive(:get_chef_extension_private_params)
        response = @server_instance.create_server_def
        expect(response[:chef_extension_public_param]).to be == public_config
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
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(true)
        expect(@server_instance).to receive(:wait_until_virtual_machine_ready).exactly(1).times.and_return(true)
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        testxml.css('InputEndpoint Protocol:contains("TCP")').each do |port|
          expect(port.parent.css("LocalPort").text).to_not eq("5985")
        end
      end

      it "check if all server params are set correctly" do
        version = Nokogiri::XML::Builder.new do |xml|
          xml.ResourceExtensionReferences do
            xml.Version "11.12"
          end
        end
        expect(@server_instance).to_not receive(:bootstrap_exec)

        allow(@server_instance.service.connection).to receive(:query_azure).and_return(version.doc)
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
        expect(@server_instance).to receive(:is_image_windows?).exactly(3).times.and_return(false)
        expect(@server_instance).to receive(:wait_until_virtual_machine_ready).exactly(1).times.and_return(true)
        @server_instance.run
        testxml = Nokogiri::XML(@receivedXML)
        testxml.css('InputEndpoint Protocol:contains("TCP")').each do |port|
          expect(port.parent.css("LocalPort").text).to eq("22")
        end
      end

      it "check if all server params are set correctly" do
        version = Nokogiri::XML::Builder.new do |xml|
          xml.ResourceExtensionReferences do
            xml.Version "11.12"
          end
        end
        expect(@server_instance).to_not receive(:bootstrap_exec)
        allow(@server_instance.service.connection).to receive(:query_azure).and_return(version.doc)
        expect(@server_instance).to receive(:get_chef_extension_private_params)
        expect(@server_instance).to receive(:is_image_windows?).exactly(4).times.and_return(false)
        server_config = @server_instance.create_server_def
        expect(server_config[:chef_extension]).to eq("LinuxChefClient")
        expect(server_config[:chef_extension_publisher]).to eq("Chef.Bootstrap.WindowsAzure")
        expect(server_config[:chef_extension_version]).to eq("11.*")
        expect(server_config).to include(:chef_extension_public_param)
        expect(server_config[:chef_extension_public_param][:runlist]).to eq(Chef::Config[:knife][:run_list].first.to_json)
        expect(server_config).to include(:chef_extension_private_param)
      end
    end

    shared_context "private config contents" do
      before do
        allow(File).to receive(:read).and_return("my_client_pem")
      end

      it "uses Chef ClientBuilder to generate client_pem and sets private config properly" do
        expect_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:run)
        expect_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:client_path).and_return(File.dirname(__FILE__) + "/assets/client.pem")
        response = @server_instance.get_chef_extension_private_params
        expect(response).to be == private_config
      end
    end

    context "when validation key is not present", :chef_gte_12_only do
      context "when encrypted_data_bag_secret option is passed" do
        let(:private_config) do
          { client_pem: "my_client_pem",
            encrypted_data_bag_secret: "my_encrypted_data_bag_secret" }
        end

        before do
          @server_instance.config[:encrypted_data_bag_secret] = "my_encrypted_data_bag_secret"
        end

        include_context "private config contents"
      end

      context "when encrypted_data_bag_secret_file option is passed" do
        let(:private_config) do
          { client_pem: "my_client_pem",
            encrypted_data_bag_secret: "PgIxStCmMDsuIw3ygRhmdMtStpc9EMiWisQXoP" }
        end

        before do
          @server_instance.config[:encrypted_data_bag_secret_file] = File.dirname(__FILE__) + "/assets/secret_file"
        end

        include_context "private config contents"
      end
    end

    context "when SSL certificate file option is passed but file does not exist physically" do
      before do
        allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:run)
        allow_any_instance_of(Chef::Knife::Bootstrap::ClientBuilder).to receive(:client_path).and_return(File.dirname(__FILE__) + "/assets/client.pem")
        @server_instance.config[:cert_path] = "~/my_cert.crt"
      end

      it "raises an error and exits" do
        expect(@server_instance.ui).to receive(:error).with("Specified SSL certificate does not exist.")
        expect { @server_instance.get_chef_extension_private_params }.to raise_error(SystemExit)
      end
    end

    context "when validation key is not present, using chef 11", :chef_lt_12_only do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it "raises an exception if validation_key is not present in chef 11" do
        expect(@server_instance.ui).to receive(:error)
        expect { @server_instance.run }.to raise_error(SystemExit)
      end
    end
  end

  describe "extended_logs feature for cloud-api connection protocol" do
    describe "run" do
      before do
        Chef::Config[:knife][:connection_password] = "connection_password"
        allow(Chef::Log).to receive(:info)
        allow(@server_instance).to receive(:validate_asm_keys!)
        allow(@server_instance).to receive(:validate_params!)
        allow(@server_instance).to receive(:get_dns_name)
        allow(@server_instance.service).to receive(:create_server)
        allow(@server_instance).to receive(:create_server_def)
        allow(@server_instance).to receive(:wait_until_virtual_machine_ready)
        allow(@server_instance.service).to receive(:get_role_server)
        allow(@server_instance).to receive(:msg_server_summary)
        allow(@server_instance).to receive(:plugin_create_instance!)
      end

      context "connection_protocol is not cloud-api and extended_logs is false" do
        before do
          Chef::Config[:knife][:connection_protocol] = "winrm"
          @server_instance.config[:extended_logs] = false
        end

        it "does not invoke fetch_chef_client_logs method" do
          expect(@server_instance).to_not receive(:fetch_chef_client_logs)
          expect { @server_instance.run }.not_to raise_error
        end
      end

      context "connection_protocol is cloud-api" do
        before do
          Chef::Config[:knife][:connection_protocol] = "cloud-api"
        end

        context "extended_logs is false" do
          before do
            @server_instance.config[:extended_logs] = false
          end

          it "does not invoke fetch_chef_client_logs method" do
            expect(@server_instance).to_not receive(:fetch_chef_client_logs)
            @server_instance.run
          end
        end

        context "extended_logs is true" do
          before do
            @server_instance.config[:extended_logs] = true
          end

          it "invoke fetch_chef_client_logs method" do
            expect(@server_instance).to receive(:fetch_chef_client_logs)
            @server_instance.run
          end
        end
      end
    end

    describe "fetch_chef_client_logs" do
      context "role not found" do
        before do
          allow(@server_instance).to receive(
            :fetch_role
          ).and_return(nil)
        end

        it "displays role not found error" do
          expect(@server_instance.ui).to receive(:error).with(
            "chef-client run logs could not be fetched since role vm002 could not be found."
          )
          @server_instance.fetch_chef_client_logs(nil, nil)
        end
      end

      context "extension not found" do
        before do
          allow(@server_instance).to receive(
            :fetch_role
          ).and_return("vm002")
          allow(@server_instance).to receive(
            :fetch_extension
          ).and_return(nil)
        end

        it "displays extension not found error" do
          expect(@server_instance.ui).to receive(:error).with(
            "Unable to find Chef extension under role vm002."
          )
          @server_instance.fetch_chef_client_logs(nil, nil)
        end
      end

      context "substatus not found in server role response" do
        before do
          allow(@server_instance).to receive(
            :fetch_role
          ).and_return("vm002")
          allow(@server_instance).to receive(
            :fetch_extension
          ).and_return("extension")
          allow(@server_instance).to receive(
            :fetch_substatus
          ).and_return(nil)
          @start_time = Time.now
        end

        context "wait time has not exceeded wait timeout limit" do
          it "displays wait messages and re-invokes fetch_chef_client_logs method recursively" do
            @server_instance.instance_eval do
              class << self
                alias fetch_chef_client_logs_mocked fetch_chef_client_logs
              end
            end
            expect(@server_instance).to receive(:print).exactly(1).times
            expect(@server_instance).to receive(:sleep).with(30)
            expect(@server_instance).to receive(
              :fetch_chef_client_logs
            ).with(@start_time, 30)
            @server_instance.fetch_chef_client_logs_mocked(@start_time, 30)
          end
        end

        context "wait time has exceeded wait timeout limit" do
          it "displays wait timeout exceeded message" do
            expect(@server_instance.ui).to receive(:error).with(
              "\nchef-client run logs could not be fetched since fetch process exceeded wait timeout of -1 minutes.\n"
            )
            @server_instance.fetch_chef_client_logs(@start_time, -1)
          end
        end
      end

      context "substatus found in server role response" do
        before do
          Chef::Config[:knife][:azure_vm_name] = "vm04"
          allow(@server_instance.service).to receive(
            :deployment_name
          ).and_return("deploymentExtension")
          deployment = Nokogiri::XML readFile("extension_deployment_xml.xml")
          allow(@server_instance.service).to receive(
            :deployment
          ).and_return(deployment)
        end

        it "displays chef-client run logs and exit status to the user" do
          expect(@server_instance).to receive(
            :puts
          ).exactly(4).times
          expect(@server_instance).to receive(:print)
          @server_instance.fetch_chef_client_logs(@start_time, 30)
        end
      end
    end

    describe "fetch_role" do
      context "role not found" do
        before do
          Chef::Config[:knife][:azure_vm_name] = "vm09"
        end

        it "returns nil" do
          response = fetch_role_from_xml
          expect(response).to be nil
        end
      end

      context "role found" do
        before do
          Chef::Config[:knife][:azure_vm_name] = "vm01"
        end

        it "returns the role" do
          response = fetch_role_from_xml
          expect(response).to_not be nil
          expect(response.at_css("RoleName").text).to eq "vm01"
        end
      end
    end

    describe "fetch_extension" do
      context "Chef Extension not found" do
        context "other extension(s) available" do
          context "example-1" do
            before do
              Chef::Config[:knife][:azure_vm_name] = "vm01"
              @role = fetch_role_from_xml
            end

            it "returns nil" do
              response = @server_instance.fetch_extension(@role)
              expect(response).to be nil
            end
          end

          context "example-2" do
            before do
              Chef::Config[:knife][:azure_vm_name] = "vm07"
              @role = fetch_role_from_xml
            end

            it "returns nil" do
              response = @server_instance.fetch_extension(@role)
              expect(response).to be nil
            end
          end
        end

        context "none of the extension available" do
          before do
            Chef::Config[:knife][:azure_vm_name] = "vm06"
            @role = fetch_role_from_xml
          end

          it "returns nil" do
            response = @server_instance.fetch_extension(@role)
            expect(response).to be nil
          end
        end
      end

      context "Chef Extension found" do
        context "for Windows platform" do
          before do
            Chef::Config[:knife][:azure_vm_name] = "vm02"
            @role = fetch_role_from_xml
          end

          it "returns the Windows Chef Extension" do
            response = @server_instance.fetch_extension(@role)
            expect(response).to_not be nil
            expect(response.at_css("HandlerName").text).to eq \
              "Chef.Bootstrap.WindowsAzure.ChefClient"
          end
        end

        context "for Linux platform" do
          before do
            Chef::Config[:knife][:azure_vm_name] = "vm03"
            @role = fetch_role_from_xml
          end

          it "returns the Linux Chef Extension" do
            response = @server_instance.fetch_extension(@role)
            expect(response).to_not be nil
            expect(response.at_css("HandlerName").text).to eq \
              "Chef.Bootstrap.WindowsAzure.LinuxChefClient"
          end
        end
      end
    end

    describe "fetch_substatus" do
      context "substatus list not found" do
        before do
          Chef::Config[:knife][:azure_vm_name] = "vm02"
          role = fetch_role_from_xml
          @extension = @server_instance.fetch_extension(role)
        end

        it "returns nil" do
          response = @server_instance.fetch_substatus(@extension)
          expect(response).to be nil
        end
      end

      context "substatus list found" do
        context "but it does not contain chef-client run logs substatus" do
          before do
            Chef::Config[:knife][:azure_vm_name] = "vm03"
            role = fetch_role_from_xml
            @extension = @server_instance.fetch_extension(role)
          end

          it "returns nil" do
            response = @server_instance.fetch_substatus(@extension)
            expect(response).to be nil
          end
        end

        context "and it do contain chef-client run logs substatus" do
          before do
            Chef::Config[:knife][:azure_vm_name] = "vm04"
            role = fetch_role_from_xml
            @extension = @server_instance.fetch_extension(role)
          end

          it "returns the substatus" do
            response = @server_instance.fetch_substatus(@extension)
            expect(response).to_not be nil
            expect(response.at_css("Name").text).to eq "Chef Client run logs"
            expect(response.at_css("Status").text).to eq "Success"
            expect(response.at_css("Message").text).to eq "MyChefClientRunLogs"
          end
        end
      end
    end
  end

  describe "#load_correct_secret" do
    context "when encrypted_data_bag_secret_file is passed in knife.rb" do
      it "returns the encrypted_data_bag_secret_file passed from the knife.rb" do
        Chef::Config[:knife][:encrypted_data_bag_secret_file] = "knife/path"
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(Chef::Config[:knife][:encrypted_data_bag_secret_file]).and_return(Chef::Config[:knife][:encrypted_data_bag_secret_file])
        secret = @server_instance.load_correct_secret
        expect(secret).to be == Chef::Config[:knife][:encrypted_data_bag_secret_file]
      end
    end

    context "when encrypted_data_bag_secret is passed in knife.rb" do
      it "returns the encrypted_data_bag_secret passed from the knife.rb" do
        Chef::Config[:knife][:encrypted_data_bag_secret] = "knife_secret"
        secret = @server_instance.load_correct_secret
        expect(secret).to be == Chef::Config[:knife][:encrypted_data_bag_secret]
      end
    end

    context "when both encrypted_data_bag_secret_file and encrypted_data_bag_secret are passed in knife.rb" do
      it "returns the encrypted_data_bag_secret_file passed from the knife.rb" do
        Chef::Config[:knife][:encrypted_data_bag_secret_file] = "knife/path"
        Chef::Config[:knife][:encrypted_data_bag_secret] = "knife_secret"
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(Chef::Config[:knife][:encrypted_data_bag_secret_file]).and_return(Chef::Config[:knife][:encrypted_data_bag_secret_file])
        secret = @server_instance.load_correct_secret
        expect(secret).to be == Chef::Config[:knife][:encrypted_data_bag_secret_file]
      end
    end

    context "when encrypted_data_bag_secret_file is passed from CLI" do
      it "returns the encrypted_data_bag_secret_file passed from the CLI" do
        @server_instance.config[:encrypted_data_bag_secret_file] = "cli/path"
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(@server_instance.config[:encrypted_data_bag_secret_file]).and_return(@server_instance.config[:encrypted_data_bag_secret_file])
        secret = @server_instance.load_correct_secret
        expect(secret).to be == @server_instance.config[:encrypted_data_bag_secret_file]
      end
    end

    context "when encrypted_data_bag_secret is passed from CLI" do
      it "returns the encrypted_data_bag_secret passed from the CLI" do
        @server_instance.config[:encrypted_data_bag_secret] = "cli_secret"
        secret = @server_instance.load_correct_secret
        expect(secret).to be == @server_instance.config[:encrypted_data_bag_secret]
      end
    end

    context "when both encrypted_data_bag_secret_file and encrypted_data_bag_secret are passed from CLI" do
      it "returns the encrypted_data_bag_secret_file passed from CLI" do
        @server_instance.config[:encrypted_data_bag_secret_file] = "cli/path"
        @server_instance.config[:encrypted_data_bag_secret] = "cli_secret"
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(@server_instance.config[:encrypted_data_bag_secret_file]).and_return(@server_instance.config[:encrypted_data_bag_secret_file])
        secret = @server_instance.load_correct_secret
        expect(secret).to be == @server_instance.config[:encrypted_data_bag_secret_file]
      end
    end

    context "when encrypted_data_bag_secret_file and encrypted_data_bag_secret are passed from both knife.rb file and CLI" do
      it "returns the encrypted_data_bag_secret_file passed from the CLI" do
        Chef::Config[:knife][:encrypted_data_bag_secret_file] = "knife/path"
        Chef::Config[:knife][:encrypted_data_bag_secret] = "knife_secret"
        @server_instance.config[:encrypted_data_bag_secret_file] = "cli/path"
        @server_instance.config[:encrypted_data_bag_secret] = "cli_secret"
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(@server_instance.config[:encrypted_data_bag_secret_file]).and_return(@server_instance.config[:encrypted_data_bag_secret_file])
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(Chef::Config[:knife][:encrypted_data_bag_secret_file]).and_return(Chef::Config[:knife][:encrypted_data_bag_secret_file])
        secret = @server_instance.load_correct_secret
        expect(secret).to be == @server_instance.config[:encrypted_data_bag_secret_file]
      end
    end

    context "when encrypted_data_bag_secret_file is passed from both knife.rb file and CLI" do
      it "returns the encrypted_data_bag_secret_file passed from the CLI" do
        Chef::Config[:knife][:encrypted_data_bag_secret_file] = "knife/path"
        @server_instance.config[:encrypted_data_bag_secret_file] = "cli/path"
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(@server_instance.config[:encrypted_data_bag_secret_file]).and_return(@server_instance.config[:encrypted_data_bag_secret_file])
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(Chef::Config[:knife][:encrypted_data_bag_secret_file]).and_return(Chef::Config[:knife][:encrypted_data_bag_secret_file])
        secret = @server_instance.load_correct_secret
        expect(secret).to be == @server_instance.config[:encrypted_data_bag_secret_file]
      end
    end

    context "when encrypted_data_bag_secret is passed from both knife.rb file and CLI" do
      it "returns the encrypted_data_bag_secret passed from the CLI" do
        Chef::Config[:knife][:encrypted_data_bag_secret] = "knife_secret"
        @server_instance.config[:encrypted_data_bag_secret] = "cli_secret"
        secret = @server_instance.load_correct_secret
        expect(secret).to be == @server_instance.config[:encrypted_data_bag_secret]
      end
    end

    context "when encrypted_data_bag_secret_file is passed in knife.rb and encrypted_data_bag_secret is passed from CLI" do
      it "returns the encrypted_data_bag_secret passed from the CLI" do
        Chef::Config[:knife][:encrypted_data_bag_secret_file] = "knife/path"
        @server_instance.config[:encrypted_data_bag_secret] = "cli_secret"
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(Chef::Config[:knife][:encrypted_data_bag_secret_file]).and_return(Chef::Config[:knife][:encrypted_data_bag_secret_file])
        secret = @server_instance.load_correct_secret
        expect(secret).to be == @server_instance.config[:encrypted_data_bag_secret]
      end
    end

    context "when encrypted_data_bag_secret is passed in knife.rb and encrypted_data_bag_secret_file is passed from CLI" do
      it "returns the encrypted_data_bag_secret_file passed from the CLI" do
        Chef::Config[:knife][:encrypted_data_bag_secret] = "knife_secret"
        @server_instance.config[:encrypted_data_bag_secret_file] = "cli/path"
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(@server_instance.config[:encrypted_data_bag_secret_file]).and_return(@server_instance.config[:encrypted_data_bag_secret_file])
        secret = @server_instance.load_correct_secret
        expect(secret).to be == @server_instance.config[:encrypted_data_bag_secret_file]
      end
    end

    context "when encrypted_data_bag_secret_file is passed in knife.rb and encrypted_data_bag_secret_file, encrypted_data_bag_secret are passed from CLI" do
      it "returns the encrypted_data_bag_secret_file passed from the CLI" do
        Chef::Config[:knife][:encrypted_data_bag_secret_file] = "knife/path"
        @server_instance.config[:encrypted_data_bag_secret_file] = "cli/path"
        @server_instance.config[:encrypted_data_bag_secret] = "cli_secret"
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(@server_instance.config[:encrypted_data_bag_secret_file]).and_return(@server_instance.config[:encrypted_data_bag_secret_file])
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(Chef::Config[:knife][:encrypted_data_bag_secret_file]).and_return(Chef::Config[:knife][:encrypted_data_bag_secret_file])
        secret = @server_instance.load_correct_secret
        expect(secret).to be == @server_instance.config[:encrypted_data_bag_secret_file]
      end
    end

    context "when encrypted_data_bag_secret is passed in knife.rb and encrypted_data_bag_secret_file, encrypted_data_bag_secret are passed from CLI" do
      it "returns the encrypted_data_bag_secret_file passed from the CLI" do
        Chef::Config[:knife][:encrypted_data_bag_secret] = "knife_secret"
        @server_instance.config[:encrypted_data_bag_secret_file] = "cli/path"
        @server_instance.config[:encrypted_data_bag_secret] = "cli_secret"
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(@server_instance.config[:encrypted_data_bag_secret_file]).and_return(@server_instance.config[:encrypted_data_bag_secret_file])
        secret = @server_instance.load_correct_secret
        expect(secret).to be == @server_instance.config[:encrypted_data_bag_secret_file]
      end
    end

    context "when encrypted_data_bag_secret_file and encrypted_data_bag_secret are passed in knife.rb and encrypted_data_bag_secret_file is passed from CLI" do
      it "returns the encrypted_data_bag_secret_file passed from the CLI" do
        Chef::Config[:knife][:encrypted_data_bag_secret] = "knife_secret"
        Chef::Config[:knife][:encrypted_data_bag_secret_file] = "knife/path"
        @server_instance.config[:encrypted_data_bag_secret_file] = "cli/path"
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(@server_instance.config[:encrypted_data_bag_secret_file]).and_return(@server_instance.config[:encrypted_data_bag_secret_file])
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(Chef::Config[:knife][:encrypted_data_bag_secret_file]).and_return(Chef::Config[:knife][:encrypted_data_bag_secret_file])
        secret = @server_instance.load_correct_secret
        expect(secret).to be == @server_instance.config[:encrypted_data_bag_secret_file]
      end
    end

    context "when encrypted_data_bag_secret_file and encrypted_data_bag_secret are passed in knife.rb and encrypted_data_bag_secret is passed from CLI" do
      it "returns the encrypted_data_bag_secret passed from the CLI" do
        Chef::Config[:knife][:encrypted_data_bag_secret] = "knife_secret"
        Chef::Config[:knife][:encrypted_data_bag_secret_file] = "knife/path"
        @server_instance.config[:encrypted_data_bag_secret] = "cli_secret"
        allow(Chef::EncryptedDataBagItem).to receive(:load_secret).with(Chef::Config[:knife][:encrypted_data_bag_secret_file]).and_return(Chef::Config[:knife][:encrypted_data_bag_secret_file])
        secret = @server_instance.load_correct_secret
        expect(secret).to be == @server_instance.config[:encrypted_data_bag_secret]
      end
    end
  end

  def fetch_role_from_xml
    allow(@server_instance.service).to receive(
      :deployment_name
    ).and_return("deploymentExtension")
    deployment = Nokogiri::XML readFile("extension_deployment_xml.xml")
    allow(@server_instance.service).to receive(
      :deployment
    ).and_return(deployment)
    @server_instance.fetch_role
  end
end
