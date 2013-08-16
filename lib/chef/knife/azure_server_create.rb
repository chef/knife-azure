#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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

require 'chef/knife/azure_base'
require 'chef/knife/winrm_base'
class Chef
  class Knife
    class AzureServerCreate < Knife

      include Knife::AzureBase
      include Knife::WinrmBase

      deps do
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        require 'chef/knife/bootstrap_windows_ssh'
        require 'chef/knife/core/windows_bootstrap_context'
        Chef::Knife::Bootstrap.load_deps
      end

      def load_winrm_deps
        require 'winrm'
        require 'em-winrm'
        require 'chef/knife/winrm'
        require 'chef/knife/bootstrap_windows_winrm'
      end

      banner "knife azure server create (options)"

      attr_accessor :initial_sleep_delay

      option :bootstrap_protocol,
        :long => "--bootstrap-protocol protocol",
        :description => "Protocol to bootstrap windows servers. options: winrm/ssh",
        :default => "winrm"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_port,
        :long => "--ssh-port PORT",
        :description => "The ssh port. Default is 22.",
        :default => '22'

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "chef-full"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      option :azure_storage_account,
        :short => "-a NAME",
        :long => "--azure-storage-account NAME",
        :description => "Required for advanced server-create option.
                                      A name for the storage account that is unique within Windows Azure. Storage account names must be
                                      between 3 and 24 characters in length and use numbers and lower-case letters only.
                                      This name is the DNS prefix name and can be used to access blobs, queues, and tables in the storage account.
                                      For example: http://ServiceName.blob.core.windows.net/mycontainer/"

      option :azure_vm_name,
        :long => "--azure-vm-name NAME",
        :description => "Required for advanced server-create option.
                                      Specifies the name for the virtual machine. The name must be unique within the deployment."

      option :azure_service_location,
        :short => "-m LOCATION",
        :long => "--azure-service-location LOCATION",
        :description => "Required. Specifies the geographic location - the name of the data center location that is valid for your subscription.
                                      Eg: West US, East US, East Asia, Southeast Asia, North Europe, West Europe"

      option :azure_dns_name,
        :short => "-d DNS_NAME",
        :long => "--azure-dns-name DNS_NAME",
        :description => "Required. The DNS prefix name that can be used to access the cloud service which is unique within Windows Azure.
                                      If you want to add new VM to an existing service/deployment, specify an exiting dns-name,
                                      along with --azure-connect-to-existing-dns option.
                                      Otherwise a new deployment is created. For example, if the DNS of cloud service is MyService you could access the cloud service
                                      by calling: http://DNS_NAME.cloudapp.net"

      option :azure_os_disk_name,
        :short => "-o DISKNAME",
        :long => "--azure-os-disk-name DISKNAME",
        :description => "Optional. Specifies the friendly name of the disk containing the guest OS image in the image repository."

      option :azure_source_image,
        :short => "-I IMAGE",
        :long => "--azure-source-image IMAGE",
        :description => "Required. Specifies the name of the disk image to use to create the virtual machine.
                                      Do a \"knife azure image list\" to see a list of available images."

      option :azure_vm_size,
        :short => "-z SIZE",
        :long => "--azure-vm-size SIZE",
        :description => "Optional. Size of virtual machine (ExtraSmall, Small, Medium, Large, ExtraLarge)",
        :default => 'Small'

      option :tcp_endpoints,
        :short => "-t PORT_LIST",
        :long => "--tcp-endpoints PORT_LIST",
        :description => "Comma separated list of TCP local and public ports to open i.e. '80:80,433:5000'"

      option :udp_endpoints,
        :short => "-u PORT_LIST",
        :long => "--udp-endpoints PORT_LIST",
        :description => "Comma separated list of UDP local and public ports to open i.e. '80:80,433:5000'"

      option :azure_connect_to_existing_dns,
        :short => "-c",
        :long => "--azure-connect-to-existing-dns",
        :boolean => true,
        :default => false,
        :description => "Set this flag to add the new VM to an existing deployment/service. Must give the name of the existing
                                        DNS correctly in the --dns-name option"
      option :identity_file,
        :long => "--identity-file FILENAME",
        :description => "SSH identity file for authentication, optional. It is the RSA private key path. Specify either ssh-password or identity-file"

      option :identity_file_passphrase,
        :long => "--identity-file-passphrase PASSWORD",
        :description => "SSH key passphrase. Optional, specify if passphrase for identity-file exists"

      option :hint,
        :long => "--hint HINT_NAME[=HINT_FILE]",
        :description => "Specify Ohai Hint to be set on the bootstrap target.  Use multiple --hint options to specify multiple hints.",
        :proc => Proc.new { |h|
           Chef::Config[:knife][:hints] ||= {}
           name, path = h.split("=")
           Chef::Config[:knife][:hints][name] = path ? JSON.parse(::File.read(path)) : Hash.new
        }

      def strip_non_ascii(string)
        string.gsub(/[^0-9a-z ]/i, '')
      end

      def random_string(len=10)
        (0...len).map{65.+(rand(25)).chr}.join
      end

      def tcp_test_winrm(ip_addr, port)
	    hostname = ip_addr
        socket = TCPSocket.new(hostname, port)
	    return true
      rescue SocketError
        sleep 2
        false
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      rescue Errno::ENETUNREACH
        sleep 2
        false
      end

      def tcp_test_ssh(fqdn, sshport)
        tcp_socket = TCPSocket.new(fqdn, sshport)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{fqdn}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue SocketError
        sleep 2
        false
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def run
        $stdout.sync = true
        storage = nil

        Chef::Log.info("validating...")
        validate!

        Chef::Log.info("creating...")

        if not locate_config_value(:azure_vm_name)
          config[:azure_vm_name] = locate_config_value(:azure_dns_name)
        end

        #If Storage Account is not specified, check if the geographic location has one to re-use
        if not locate_config_value(:azure_storage_account)
          storage_accts = connection.storageaccounts.all
          storage = storage_accts.find { |storage_acct| storage_acct.location.to_s == locate_config_value(:azure_service_location) }
          if not storage
            config[:azure_storage_account] = [strip_non_ascii(locate_config_value(:azure_vm_name)), random_string].join.downcase
          else
            config[:azure_storage_account] = storage.name.to_s
          end
        end

        server = connection.deploys.create(create_server_def)
        fqdn = server.publicipaddress

        puts("\n")
        if is_image_windows?
          server.tcpports.each do |endpoint|
            if endpoint["Name"] == "RDP"
              ui.info("RDP details for #{ui.color(server.name, :bold)}: ")
              ui.info("\tRDP Public Port: #{ui.color(endpoint['PublicPort'], :bold)}")
              ui.info("\tRDP Private Port: #{ui.color(endpoint['LocalPort'], :bold)}")
            end
          end
          if locate_config_value(:bootstrap_protocol) == 'ssh'
            port = server.sshport
            print "\n#{ui.color("Waiting for sshd on #{fqdn}:#{port}", :magenta)}"

            print(".") until tcp_test_ssh(fqdn,port) {
              sleep @initial_sleep_delay ||= 10
              puts("done")
           }

          elsif locate_config_value(:bootstrap_protocol) == 'winrm'
            port = server.winrmport

            print "\n#{ui.color("Waiting for winrm on #{fqdn}:#{port}", :magenta)}"

            print(".") until tcp_test_winrm(fqdn,port) {
              sleep @initial_sleep_delay ||= 10
              puts("done")
           }

          end
          sleep 15
          bootstrap_for_windows_node(server,fqdn, port).run
        else
          unless server && server.publicipaddress && server.sshport
            Chef::Log.fatal("server not created")
          exit 1
        end

        port = server.sshport

        print "\n#{ui.color("Waiting for sshd on #{fqdn}:#{port}", :magenta)}"

        print(".") until tcp_test_ssh(fqdn,port) {
          sleep @initial_sleep_delay ||= 10
          puts("done")
        }

        sleep 15
          bootstrap_for_node(server,fqdn,port).run
        end
      end

      def load_cloud_attributes_in_hints(server)
        # Modify global configuration state to ensure hint gets set by knife-bootstrap
        # Query azure and load necessary attributes.
        cloud_attributes = {}
        cloud_attributes["public_ip"] = server.publicipaddress
        cloud_attributes["vm_name"] = server.name
        cloud_attributes["public_fqdn"] = server.hostedservicename.to_s + ".cloudapp.net"
        cloud_attributes["public_ssh_port"] = server.sshport if server.sshport
        cloud_attributes["public_winrm_port"] = server.winrmport if server.winrmport

        Chef::Config[:knife][:hints] ||= {}
        Chef::Config[:knife][:hints]["azure"] ||= cloud_attributes

      end

      def bootstrap_common_params(bootstrap, server)

        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        load_cloud_attributes_in_hints(server)
        bootstrap
      end


      def bootstrap_for_windows_node(server, fqdn, port)
        if locate_config_value(:bootstrap_protocol) == 'winrm'

            load_winrm_deps
            if not Chef::Platform.windows?
              require 'gssapi'
            end

            bootstrap = Chef::Knife::BootstrapWindowsWinrm.new

            bootstrap.config[:winrm_user] = locate_config_value(:winrm_user) || 'Administrator'
            bootstrap.config[:winrm_password] = locate_config_value(:winrm_password)
            bootstrap.config[:winrm_transport] = locate_config_value(:winrm_transport)

            bootstrap.config[:winrm_port] = port

        elsif locate_config_value(:bootstrap_protocol) == 'ssh'
            bootstrap = Chef::Knife::BootstrapWindowsSsh.new
            bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
            bootstrap.config[:ssh_password] = locate_config_value(:ssh_password)
            bootstrap.config[:ssh_port] = port
            bootstrap.config[:identity_file] = locate_config_value(:identity_file)
            bootstrap.config[:host_key_verify] = locate_config_value(:host_key_verify)
        else
            ui.error("Unsupported Bootstrapping Protocol. Supported : winrm, ssh")
            exit 1
        end
        bootstrap.name_args = [fqdn]
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.name
        bootstrap.config[:encrypted_data_bag_secret] = config[:encrypted_data_bag_secret]
        bootstrap.config[:encrypted_data_bag_secret_file] = config[:encrypted_data_bag_secret_file]
        bootstrap_common_params(bootstrap, server)
      end

      def bootstrap_for_node(server,fqdn,port)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [fqdn]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
        bootstrap.config[:ssh_password] = locate_config_value(:ssh_password)
        bootstrap.config[:ssh_port] = port
        bootstrap.config[:identity_file] = locate_config_value(:identity_file)
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || server.name
        bootstrap.config[:prerelease] = locate_config_value(:prerelease)
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:use_sudo] = true unless locate_config_value(:ssh_user) == 'root'
        bootstrap.config[:use_sudo_password] = true if bootstrap.config[:use_sudo]
        bootstrap.config[:template_file] = config[:template_file]
        bootstrap.config[:environment] = locate_config_value(:environment)
        # may be needed for vpc_mode
        bootstrap.config[:host_key_verify] = config[:host_key_verify]

        # Load cloud attributes.
        load_cloud_attributes_in_hints(server)

        bootstrap
      end

      def validate!
        super([
              :azure_subscription_id,
              :azure_mgmt_cert,
              :azure_api_host_name,
              :azure_dns_name,
              :azure_service_location,
              :azure_source_image,
              :azure_vm_size,
        ])
        if locate_config_value(:azure_connect_to_existing_dns) && locate_config_value(:azure_vm_name).nil?
          ui.error("Specify the VM name using --azure-vm-name option, since you are connecting to existing dns")
          exit 1
        end
      end

      def create_server_def
        server_def = {
          :azure_storage_account => locate_config_value(:azure_storage_account),
          :azure_dns_name => locate_config_value(:azure_dns_name),
          :azure_vm_name => locate_config_value(:azure_vm_name),
          :azure_service_location => locate_config_value(:azure_service_location),
          :azure_os_disk_name => locate_config_value(:azure_os_disk_name),
          :azure_source_image => locate_config_value(:azure_source_image),
          :azure_vm_size => locate_config_value(:azure_vm_size),
          :tcp_endpoints => locate_config_value(:tcp_endpoints),
          :udp_endpoints => locate_config_value(:udp_endpoints),
          :bootstrap_proto => locate_config_value(:bootstrap_protocol),
          :azure_connect_to_existing_dns => locate_config_value(:azure_connect_to_existing_dns),
          :winrm_user => locate_config_value(:winrm_user)
        }
        # If user is connecting a new VM to an existing dns, then
        # the VM needs to have a unique public port. Logic below takes care of this.
        if !is_image_windows? or locate_config_value(:bootstrap_protocol) == 'ssh'
          port = locate_config_value(:ssh_port) || '22'
          if locate_config_value(:azure_connect_to_existing_dns) && (port == '22')
             port = Random.rand(64000) + 1000
          end
        else
          port = locate_config_value(:winrm_port) || '5985'
          if locate_config_value(:azure_connect_to_existing_dns) && (port == '5985')
              port = Random.rand(64000) + 1000
          end
        end
        server_def[:port] = port

        if is_image_windows?
          server_def[:os_type] = 'Windows'
          if not locate_config_value(:winrm_password) or not locate_config_value(:bootstrap_protocol)
            ui.error("WinRM Password and Bootstrapping Protocol are compulsory parameters")
            exit 1
          end
          # We can specify the AdminUsername after API version 2013-03-01. However, in this API version,
          # the AdminUsername is a required parameter.
          # Also, the user name cannot be Administrator, Admin, Admin1 etc, for enhanced security (provided by Azure)
          if locate_config_value(:winrm_user).nil? || locate_config_value(:winrm_user).downcase =~ /admin*/
            ui.error("WinRM User is compulsory parameter and it cannot be named 'admin*'")
            exit
          end
          server_def[:admin_password] = locate_config_value(:winrm_password)
          server_def[:bootstrap_proto] = locate_config_value(:bootstrap_protocol)
        else
          server_def[:os_type] = 'Linux'
          server_def[:bootstrap_proto] = 'ssh'
          if not locate_config_value(:ssh_user)
            ui.error("SSH User is compulsory parameter")
            exit 1
          end
          unless locate_config_value(:ssh_password) or locate_config_value(:identity_file)
              ui.error("Specify either SSH Key or SSH Password")
              exit 1
          end

          server_def[:ssh_user] = locate_config_value(:ssh_user)
          server_def[:ssh_password] = locate_config_value(:ssh_password)
          server_def[:identity_file] = locate_config_value(:identity_file)
          server_def[:identity_file_passphrase] = locate_config_value(:identity_file_passphrase)
        end
        server_def
      end
    end
  end
end

