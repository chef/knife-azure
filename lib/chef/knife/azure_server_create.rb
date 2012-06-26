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

require File.expand_path('../azure_base', __FILE__)

class Chef
  class Knife
    class AzureServerCreate < Knife

      include Knife::AzureBase

      deps do
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife azure server create (options)"

      attr_accessor :initial_sleep_delay

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

      option :no_host_key_verify,
        :long => "--no-host-key-verify",
        :description => "Disable host key verification",
        :boolean => true,
        :default => false

      option :hosted_service_name,
        :short => "-s NAME",
        :long => "--hosted-service-name NAME",
        :description => "specifies the name for the hosted service"

      option :hosted_service_description,
        :short => "-D DESCRIPTION",
        :long => "--hosted_service_description DESCRIPTION",
        :description => "Description for the hosted service"

      option :storage_account,
        :short => "-a NAME",
        :long => "--storage-account NAME",
        :description => "specifies the name for the hosted service"

      option :role_name,
        :short => "-R name",
        :long => "--role-name NAME",
        :description => "specifies the name for the virtual machine"

      option :host_name,
        :short => "-H NAME",
        :long => "--host-name NAME",
        :description => "specifies the host name for the virtual machine"

      option :service_location,
        :short => "-m LOCATION",
        :long => "--service-location LOCATION",
        :description => "specify the Geographic location for the virtual machine and services"

      option :os_disk_name,
        :short => "-o DISKNAME",
        :long => "--os-disk-name DISKNAME",
        :description => "unique name for specifying os disk (optional)"

      option :source_image,
        :short => "-I IMAGE",
        :long => "--source-image IMAGE",
        :description => "disk image name to use to create virtual machine"

      option :role_size,
        :short => "-z SIZE",
        :long => "--role-size SIZE",
        :description => "size of virtual machine (ExtraSmall, Small, Medium, Large, ExtraLarge)"

      option :tcp_endpoints,
        :short => "-t PORT_LIST",
        :long => "--tcp-endpoints PORT_LIST",
        :description => "Comma separated list of TCP local and public ports to open i.e. '80:80,433:5000'"

      option :udp_endpoints,
        :short => "-u PORT_LIST",
        :long => "--udp-endpoints PORT_LIST",
        :description => "Comma separated list of UDP local and public ports to open i.e. '80:80,433:5000'"


      def strip_non_ascii(string)
        string.gsub(/[^0-9a-z ]/i, '')
      end

      def random_string(len=10)
        (0...len).map{65.+(rand(25)).chr}.join
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
        # This happens on EC2 quite often
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
          :role_name, 
          :host_name, 
          :ssh_user, 
          :ssh_password, 
          :service_location, 
          :source_image, 
          :role_size
        ].each do |key|
          key = key.to_sym
          details << key.to_s
          details << Chef::Config[:knife][key].to_s
          details << config[key].to_s
          details << locate_config_value(key)
        end 
        puts ui.list(details, :columns_across, 4)
      end
      def run
        $stdout.sync = true
        storage = nil

        Chef::Log.info("validating...")
        validate!

        Chef::Log.info("creating...")
      
        if not locate_config_value(:hosted_service_name)
          config[:hosted_service_name] = [strip_non_ascii(locate_config_value(:role_name)), random_string].join
        end

        #If Storage Account is not specified, check if the geographic location has one to re-use 
        if not locate_config_value(:storage_account)
          storage_accts = connection.storageaccounts.all
          storage = storage_accts.find { |storage_acct| storage_acct.location.to_s == locate_config_value(:service_location) }
          if not storage
            config[:storage_account] = [strip_non_ascii(locate_config_value(:role_name)), random_string].join.downcase
          else
            config[:storage_account] = storage.name.to_s
          end
        end
        server = connection.deploys.create(create_server_def)

        puts("\n")

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

        puts "\n"
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
        bootstrap.config[:template_file] = config[:template_file]
        bootstrap.config[:environment] = locate_config_value(:environment)
        # may be needed for vpc_mode
        bootstrap.config[:no_host_key_verify] = config[:no_host_key_verify]
        bootstrap
      end

      def validate!
        super([
              :azure_subscription_id, 
              :azure_mgmt_cert, 
              :azure_host_name,
              :role_name, 
              :host_name, 
              :ssh_user, 
              :ssh_password, 
              :service_location, 
              :source_image, 
              :role_size
        ])
      end

      def create_server_def
        server_def = {
          :hosted_service_name => locate_config_value(:hosted_service_name), 
          :storage_account => locate_config_value(:storage_account),
          :role_name => locate_config_value(:role_name), 
          :host_name => locate_config_value(:host_name), 
          :ssh_user => locate_config_value(:ssh_user),
          :ssh_password => locate_config_value(:ssh_password), 
          :service_location => locate_config_value(:service_location), 
          :os_disk_name => locate_config_value(:os_disk_name), 
          :source_image => locate_config_value(:source_image), 
          :role_size => locate_config_value(:role_size),
          :tcp_endpoints => locate_config_value(:tcp_endpoints),
          :udp_endpoints => locate_config_value(:udp_endpoints)
        }
        server_def
      end
    end
  end
end
