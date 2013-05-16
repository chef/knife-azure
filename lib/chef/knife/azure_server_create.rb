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
        require 'chef/knife/bootstrap_windows_winrm'
        require 'chef/knife/bootstrap_windows_ssh'
        require 'chef/knife/core/windows_bootstrap_context'
        require 'chef/knife/winrm'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife azure server create (options)"

      attr_accessor :initial_sleep_delay, :port

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

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

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

      option :hosted_service_name,
        :short => "-s NAME",
        :long => "--hosted-service-name NAME",
        :description => "Optional. A name for the cloud service that is unique within Windows Azure. 
                                      If the specified service does not exist, new one is created. If this param is not specified, 
                                      then a new one is created with name derived from the DNS name. This name is the DNS prefix name 
                                      and can be used to access the service. For example: http://ServiceName.cloudapp.net// "

      option :storage_account,
        :short => "-a NAME",
        :long => "--storage-account NAME",
        :description => "Required for advanced server-create option. 
                                      A name for the storage account that is unique within Windows Azure. Storage account names must be 
                                      between 3 and 24 characters in length and use numbers and lower-case letters only. 
                                      This name is the DNS prefix name and can be used to access blobs, queues, and tables in the storage account. 
                                      For example: http://ServiceName.blob.core.windows.net/mycontainer/"

      option :host_name,
        :long => "--host-name NAME",
        :description => "Required for advanced server-create option. 
                                      Specifies the name for the virtual machine. The name must be unique within the deployment."

      option :service_location,
        :short => "-m LOCATION",
        :long => "--service-location LOCATION",
        :description => "Required. Specifies the geographic location - the name of the data center location that is valid for your subscription. 
                                      Eg: West US, East US, East Asia, Southeast Asia, North Europe, West Europe"

      option :dns_name,
        :short => "-d DNS_NAME",
        :long => "--dns-name DNS_NAME",
        :description => "Required. The DNS prefix name that can be used to access the cloud service. 
                                      If you want to add new VM to an existing service/deployment, specify an exiting dns-name, along with --connect-to-existing-dns option.
                                      Otherwise a new deployment is created. For example, if the DNS of cloud service is MyService you could access the cloud service 
                                      by calling: http://MyService.cloudapp.net"

      option :os_disk_name,
        :short => "-o DISKNAME",
        :long => "--os-disk-name DISKNAME",
        :description => "Optional. Optional. Specifies the friendly name of the disk containing the guest OS image in the image repository."

      option :source_image,
        :short => "-I IMAGE",
        :long => "--source-image IMAGE",
        :description => "Required. Specifies the name of the disk image to use to create the virtual machine. Do a \"knife azure image list\" to see a list of available images."

      option :size,
        :short => "-z SIZE",
        :long => "--size SIZE",
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

      option :connect_to_existing_dns,
        :short => "-c",
        :long => "--connect-to-existing-dns",
        :boolean => true,
        :default => false,
        :description => "Set this flag to add the new VM to an existing deployment/service. Must give the name of the existing
                                        DNS correctly in the --dns-name option"

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

      def parameter_test
        details = Array.new
        details << ui.color('name', :bold, :blue)
        details << ui.color('Chef::Config', :bold, :blue)
        details << ui.color('config', :bold, :blue)
        details << ui.color('winner is', :bold, :blue)
        [
          :azure_subscription_id,
          :azure_mgmt_cert,
          :azure_host_name,
          :host_name,
          :ssh_user,
          :ssh_password,
          :service_location,
          :source_image,
          :size
        ].each do |key|
          key = key.to_sym
          details << key.to_s
          details << Chef::Config[:knife][key].to_s
          details << config[key].to_s
          details << locate_config_value(key)
        end
        puts ui.list(details, :columns_across, 4)
      end
      def is_platform_windows?
        return RUBY_PLATFORM.scan('w32').size > 0
      end

      def run
        $stdout.sync = true
        storage = nil

        Chef::Log.info("validating...")
        validate!

        Chef::Log.info("creating...")

        if not locate_config_value(:hosted_service_name)
          config[:hosted_service_name] = locate_config_value(:dns_name)
        end

        if not locate_config_value(:host_name)
          config[:host_name] = locate_config_value(:dns_name)
        end
        
        #If Storage Account is not specified, check if the geographic location has one to re-use
        if not locate_config_value(:storage_account)
          storage_accts = connection.storageaccounts.all
          storage = storage_accts.find { |storage_acct| storage_acct.location.to_s == locate_config_value(:service_location) }
          if not storage
            config[:storage_account] = [strip_non_ascii(locate_config_value(:host_name)), random_string].join.downcase
          else
            config[:storage_account] = storage.name.to_s
          end
        end
        if is_image_windows?
          if is_platform_windows?
            #require 'em-winrs'
          else
            require 'gssapi'
            require 'winrm'
            require 'em-winrm'
          end
        end

        server = connection.deploys.create(create_server_def)

        puts("\n")
        if is_image_windows?
          if locate_config_value(:bootstrap_protocol) == 'ssh'
            fqdn = server.sshipaddress
            port = server.sshport
            print "\n#{ui.color("Waiting for sshd on #{fqdn}:#{port}", :magenta)}"

            print(".") until tcp_test_ssh(fqdn,port) {
              sleep @initial_sleep_delay ||= 10
              puts("done")
           }

          elsif locate_config_value(:bootstrap_protocol) == 'winrm'
            fqdn = server.winrmipaddress
            port = server.winrmport

            print "\n#{ui.color("Waiting for winrm on #{fqdn}:#{port}", :magenta)}"

            print(".") until tcp_test_winrm(fqdn,port) {
              sleep @initial_sleep_delay ||= 10
              puts("done")
           }

          end
          sleep 15
          bootstrap_for_windows_node(server,fqdn).run
        else
          unless server && server.sshipaddress && server.sshport
            Chef::Log.fatal("server not created")
          exit 1
        end

        fqdn = server.sshipaddress
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

      def bootstrap_common_params(bootstrap)

        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap
      end


      def bootstrap_for_windows_node(server, fqdn)
        if locate_config_value(:bootstrap_protocol) == 'winrm'
            if is_platform_windows?
              #require 'em-winrs'
            else
              require 'gssapi'
              require 'winrm'
              require 'em-winrm'
            end
            bootstrap = Chef::Knife::BootstrapWindowsWinrm.new

            bootstrap.config[:winrm_user] = locate_config_value(:winrm_user) || 'Administrator'
            bootstrap.config[:winrm_password] = locate_config_value(:winrm_password)
            bootstrap.config[:winrm_transport] = locate_config_value(:winrm_transport)

            bootstrap.config[:winrm_port] = locate_config_value(:winrm_port)

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
        bootstrap_common_params(bootstrap)
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
        bootstrap
      end

      def validate!
        super([
              :azure_subscription_id,
              :azure_mgmt_cert,
              :azure_host_name,
              :dns_name,
              :service_location,
              :source_image,
              :size,
        ])
        if locate_config_value(:connect_to_existing_dns) && locate_config_value(:host_name).nil?
          ui.error("Specify the VM name using --host-name option, since you are connecting to existing dns")
          exit 1
        end
      end

      def create_server_def
        server_def = {
          :hosted_service_name => locate_config_value(:hosted_service_name),
          :storage_account => locate_config_value(:storage_account),
          :dns_name => locate_config_value(:dns_name),
          :host_name => locate_config_value(:host_name),
          :service_location => locate_config_value(:service_location),
          :os_disk_name => locate_config_value(:os_disk_name),
          :source_image => locate_config_value(:source_image),
          :size => locate_config_value(:size),
          :tcp_endpoints => locate_config_value(:tcp_endpoints),
          :udp_endpoints => locate_config_value(:udp_endpoints),
          :bootstrap_proto => locate_config_value(:bootstrap_protocol),
          :connect_to_existing_dns => locate_config_value(:connect_to_existing_dns)
        }

        if is_image_windows?
          server_def[:os_type] = 'Windows'
          if not locate_config_value(:winrm_password) or not locate_config_value(:bootstrap_protocol)
            ui.error("WinRM Password and Bootstrapping Protocol are compulsory parameters")
          end
          server_def[:admin_password] = locate_config_value(:winrm_password)
          server_def[:bootstrap_proto] = locate_config_value(:bootstrap_protocol)
          @port = locate_config_value(:winrm_port)
          if locate_config_value(:connect_to_existing_dns)
            if @port.nil || @port == 5985
              @port = Random.rand(64000)
            end
          else
            @port = '5985'
          end
        else
          server_def[:os_type] = 'Linux'
          server_def[:bootstrap_proto] = 'ssh'
          if not locate_config_value(:ssh_user) or not locate_config_value(:ssh_password)
            ui.error("SSH User and SSH Password are compulsory parameters")
            exit 1
          end
          server_def[:ssh_user] = locate_config_value(:ssh_user)
          server_def[:ssh_password] = locate_config_value(:ssh_password)
          @port = locate_config_value(:ssh_port)
          if locate_config_value(:connect_to_existing_dns)
            if @port.nil || @port == 22
             @port = Random.rand(64000)
            end
          else
            @port = '22'
          end
        end
        server_def[:port] = @port
        server_def
      end
    end
  end
end
 