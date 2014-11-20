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
require 'securerandom'

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
        :description => "Protocol to bootstrap windows servers. options: 'winrm' or 'ssh' or 'cloud-api'.",
        :default => "winrm"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root"

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
                                      Specifies the name for the virtual machine. The name must be unique within the deployment. The azure vm name cannot be more than 15 characters long"

      option :azure_service_location,
        :short => "-m LOCATION",
        :long => "--azure-service-location LOCATION",
        :description => "Required if not using an Affinity Group. Specifies the geographic location - the name of the data center location that is valid for your subscription.
                                      Eg: West US, East US, East Asia, Southeast Asia, North Europe, West Europe"

      option :azure_affinity_group,
        :short => "-a GROUP",
        :long => "--azure-affinity-group GROUP",
        :description => "Required if not using a Service Location. Specifies Affinity Group the VM should belong to."

      option :azure_dns_name,
        :short => "-d DNS_NAME",
        :long => "--azure-dns-name DNS_NAME",
        :description => "The DNS prefix name that can be used to access the cloud service which is unique within Windows Azure. Default is 'azure-dns-any_random_text'(e.g: azure-dns-be9b0f6f-7dda-456f-b2bf-4e28a3bc0add).
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

      option :azure_availability_set,
             :long => "--azure-availability-set NAME",
             :description => "Optional. Name of availability set to add virtual machine into."

      option :tcp_endpoints,
        :short => "-t PORT_LIST",
        :long => "--tcp-endpoints PORT_LIST",
        :description => "Comma-separated list of TCP local and public ports to open e.g. '80:80,433:5000'"

      option :udp_endpoints,
        :short => "-u PORT_LIST",
        :long => "--udp-endpoints PORT_LIST",
        :description => "Comma-separated list of UDP local and public ports to open e.g. '80:80,433:5000'"

      option :azure_connect_to_existing_dns,
        :short => "-c",
        :long => "--azure-connect-to-existing-dns",
        :boolean => true,
        :default => false,
        :description => "Set this flag to add the new VM to an existing deployment/service. Must give the name of the existing
                                        DNS correctly in the --dns-name option"

      option :azure_network_name,
        :long => "--azure-network-name NETWORK_NAME",
        :description => "Optional. Specifies the network of virtual machine"

      option :azure_subnet_name,
        :long => "--azure-subnet-name SUBNET_NAME",
        :description => "Optional. Specifies the subnet of virtual machine"

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

      option :json_attributes,
        :short => "-j JSON",
        :long => "--json-attributes JSON",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| JSON.parse(o) }

      option :thumbprint,
        :long => "--thumbprint THUMBPRINT",
        :description => "The thumprint of the ssl certificate"

      option :cert_passphrase,
        :long => "--cert-passphrase PASSWORD",
        :description => "SSL Certificate Password"

      option :cert_path,
        :long => "--cert-path PATH",
        :description => "SSL Certificate Path"

      def strip_non_ascii(string)
        string.gsub(/[^0-9a-z ]/i, '')
      end

      def random_string(len=10)
        (0...len).map{65.+(rand(25)).chr}.join
      end

      def wait_until_virtual_machine_ready(retry_interval_in_seconds = 30)

        vm_status = nil
        puts

        begin
          vm_status = wait_for_virtual_machine_state(:vm_status_provisioning, 5, retry_interval_in_seconds)
          if vm_status != :vm_status_ready
            wait_for_virtual_machine_state(:vm_status_ready, 15, retry_interval_in_seconds)
          end

          msg_server_summary(get_role_server())

          if locate_config_value(:bootstrap_protocol) == "cloud-api"
            extension_status = wait_for_resource_extension_state(:wagent_provisioning, 5, retry_interval_in_seconds)

            if extension_status != :extension_installing
              extension_status = wait_for_resource_extension_state(:extension_installing, 5, retry_interval_in_seconds)
            end

            if extension_status != :extension_provisioning
              extension_status = wait_for_resource_extension_state(:extension_provisioning, 10, retry_interval_in_seconds)
            end

            if extension_status != :extension_ready
              wait_for_resource_extension_state(:extension_ready, 5, retry_interval_in_seconds)
            end
          end
        rescue Exception => e
          Chef::Log.error("#{e.to_s}")
          raise 'Verify connectivity to Azure and subscription resource limit compliance (e.g. maximum CPU core limits) and try again.'
        end
      end

      def wait_for_virtual_machine_state(vm_status_goal, total_wait_time_in_minutes, retry_interval_in_seconds)
        vm_status_ordering = {:vm_status_not_detected => 0, :vm_status_provisioning => 1, :vm_status_ready => 2}
        vm_status_description = {:vm_status_not_detected => 'any', :vm_status_provisioning => 'provisioning', :vm_status_ready => 'ready'}

        print ui.color("Waiting for virtual machine to reach status '#{vm_status_description[vm_status_goal]}'", :magenta)

        total_wait_time_in_seconds = total_wait_time_in_minutes * 60
        max_polling_attempts = total_wait_time_in_seconds / retry_interval_in_seconds
        polling_attempts = 0

        wait_start_time = Time.now

        begin
          vm_status = get_virtual_machine_status()
          vm_ready = vm_status_ordering[vm_status] >= vm_status_ordering[vm_status_goal]
          print '.'
          sleep retry_interval_in_seconds if !vm_ready
          polling_attempts += 1
        end until vm_ready || polling_attempts >= max_polling_attempts

        if ! vm_ready
          raise Chef::Exceptions::CommandTimeout, "Virtual machine state '#{vm_status_description[vm_status_goal]}' not reached after #{total_wait_time_in_minutes} minutes."
        end

        elapsed_time_in_minutes = ((Time.now - wait_start_time) / 60).round(2)
        print ui.color("vm state '#{vm_status_description[vm_status_goal]}' reached after #{elapsed_time_in_minutes} minutes.\n", :cyan)
        vm_status
      end

      def wait_for_resource_extension_state(extension_status_goal, total_wait_time_in_minutes, retry_interval_in_seconds)

        extension_status_ordering = {:extension_status_not_detected => 0, :wagent_provisioning => 1, :extension_installing => 2, :extension_provisioning => 3, :extension_ready => 4}

        status_description = {:extension_status_not_detected => 'any', :wagent_provisioning => 'wagent provisioning', :extension_installing => "installing", :extension_provisioning => "provisioning", :extension_ready => "ready" }

        print ui.color("Waiting for Resource Extension to reach status '#{status_description[extension_status_goal]}'", :magenta)

        max_polling_attempts = (total_wait_time_in_minutes * 60) / retry_interval_in_seconds
        polling_attempts = 0

        wait_start_time = Time.now

        begin
          extension_status = get_extension_status()
          extension_ready = extension_status_ordering[extension_status[:status]] >= extension_status_ordering[extension_status_goal]
          print '.'
          sleep retry_interval_in_seconds if !extension_ready
          polling_attempts += 1
        end until extension_ready || polling_attempts >= max_polling_attempts

        if ! extension_ready
          raise Chef::Exceptions::CommandTimeout, "Resource extension state '#{status_description[extension_status_goal]}' not reached after #{total_wait_time_in_minutes} minutes. #{extension_status[:message]}"
        end

        elapsed_time_in_minutes = ((Time.now - wait_start_time) / 60).round(2)
        print ui.color("Resource extension state '#{status_description[extension_status_goal]}' reached after #{elapsed_time_in_minutes} minutes.\n", :cyan)

        extension_status[:status]
      end

      def get_virtual_machine_status()
        role = get_role_server()
        unless role.nil?
          Chef::Log.debug("Role status is #{role.status.to_s}")
          if  "ReadyRole".eql? role.status.to_s
            return :vm_status_ready
          elsif "Provisioning".eql? role.status.to_s
            return :vm_status_provisioning
          else
            return :vm_status_not_detected
          end
        end
        return :vm_status_not_detected
      end

      def get_extension_status()
        deployment_name = connection.deploys.get_deploy_name_for_hostedservice(locate_config_value(:azure_dns_name))
        deployment = connection.query_azure("hostedservices/#{locate_config_value(:azure_dns_name)}/deployments/#{deployment_name}")
        extension_status = Hash.new

        if deployment.at_css('Deployment Name') != nil
          role_list_xml =  deployment.css('RoleInstanceList RoleInstance')
          role_list_xml.each do |role|
            if role.at_css("RoleName").text == locate_config_value(:azure_vm_name)
              lnx_waagent_fail_msg = "Failed to deserialize the status reported by the Guest Agent"
              waagent_status_msg = role.at_css("GuestAgentStatus FormattedMessage Message").text

              if role.at_css("GuestAgentStatus Status").text == "Ready"
                extn_status = role.at_css("ResourceExtensionStatusList Status").text

                Chef::Log.debug("Resource extension status is #{extn_status}")

                if extn_status == "Installing"
                  extension_status[:status] = :extension_installing
                  extension_status[:message] = role.at_css("ResourceExtensionStatusList FormattedMessage Message").text
                elsif extn_status == "NotReady"
                  extension_status[:status] = :extension_provisioning
                  extension_status[:message] = role.at_css("ResourceExtensionStatusList FormattedMessage Message").text
                elsif extn_status == "Ready"
                  extension_status[:status] = :extension_ready
                  extension_status[:message] = role.at_css("ResourceExtensionStatusList FormattedMessage Message").text
                else
                  extension_status[:status] = :extension_status_not_detected
                end
              # This fix is for linux waagent issue: api unable to deserialize the waagent status.
              elsif role.at_css("GuestAgentStatus Status").text == "NotReady" and waagent_status_msg == lnx_waagent_fail_msg
                extension_status[:status] = :extension_ready
              else
                extension_status[:status] = :wagent_provisioning
                extension_status[:message] = role.at_css("GuestAgentStatus Message").text
              end
            else
              extension_status[:status] = :extension_status_not_detected
            end
          end
        else
          extension_status[:status] = :extension_status_not_detected
        end

        return extension_status
      end

      def get_role_server()
        deploy = connection.deploys.queryDeploy(locate_config_value(:azure_dns_name))
        deploy.find_role(locate_config_value(:azure_vm_name))
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

        ssh_override_winrm if %w(ssh cloud-api).include?(locate_config_value(:bootstrap_protocol)) and !is_image_windows?

        Chef::Log.info("creating...")

        config[:azure_dns_name] = get_dns_name(locate_config_value(:azure_dns_name))
        if not locate_config_value(:azure_vm_name)
          config[:azure_vm_name] = locate_config_value(:azure_dns_name)
        end

        remove_hosted_service_on_failure = locate_config_value(:azure_dns_name)
        if connection.hosts.exists?(locate_config_value(:azure_dns_name))
          remove_hosted_service_on_failure = nil
        end

        #If Storage Account is not specified, check if the geographic location has one to re-use
        if not locate_config_value(:azure_storage_account)
          storage_accts = connection.storageaccounts.all
          storage = storage_accts.find { |storage_acct| storage_acct.location.to_s == locate_config_value(:azure_service_location) }
          if not storage
            config[:azure_storage_account] = [strip_non_ascii(locate_config_value(:azure_vm_name)), random_string].join.downcase
            remove_storage_service_on_failure = config[:azure_storage_account]
          else
            remove_storage_service_on_failure = nil
            config[:azure_storage_account] = storage.name.to_s
          end
        else
          if connection.storageaccounts.exists?(locate_config_value(:azure_storage_account))
            remove_storage_service_on_failure = nil
          else
            remove_storage_service_on_failure = locate_config_value(:azure_storage_account)
          end
        end

        begin
          connection.deploys.create(create_server_def)
          wait_until_virtual_machine_ready()
          server = get_role_server()
        rescue Exception => e
          Chef::Log.error("Failed to create the server -- exception being rescued: #{e.to_s}")
          backtrace_message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          Chef::Log.debug("#{backtrace_message}")
          cleanup_and_exit(remove_hosted_service_on_failure, remove_storage_service_on_failure)
        end

        msg_server_summary(server)

        bootstrap_exec(server) unless locate_config_value(:bootstrap_protocol) == 'cloud-api'
      end

      def bootstrap_exec(server)
        fqdn = server.publicipaddress

        if is_image_windows?
          # Set distro to windows-chef-client-msi
          config[:distro] = "windows-chef-client-msi" if (config[:distro].nil? || config[:distro] == "chef-full")

          if locate_config_value(:bootstrap_protocol) == 'ssh'
            port = server.sshport
            print "#{ui.color("Waiting for sshd on #{fqdn}:#{port}", :magenta)}"

            print(".") until tcp_test_ssh(fqdn,port) {
              sleep @initial_sleep_delay ||= 10
              puts("done")
            }

          elsif locate_config_value(:bootstrap_protocol) == 'winrm'
            port = server.winrmport

            print "#{ui.color("Waiting for winrm on #{fqdn}:#{port}", :magenta)}"

            print(".") until tcp_test_winrm(fqdn,port) {
              sleep @initial_sleep_delay ||= 10
              puts("done")
            }
          end

          puts("\n")
          bootstrap_for_windows_node(server,fqdn, port).run
        else
          unless server && server.publicipaddress && server.sshport
            Chef::Log.fatal("server not created")
            exit 1
          end

          port = server.sshport

          print "#{ui.color("Waiting for sshd on #{fqdn}:#{port}", :magenta)}"

          print(".") until tcp_test_ssh(fqdn,port) {
            sleep @initial_sleep_delay ||= 10
            puts("done")
          }

          puts("\n")
          bootstrap_for_node(server,fqdn,port).run
        end

        msg_server_summary(server)
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
        bootstrap.config[:first_boot_attributes] = locate_config_value(:json_attributes) || {}
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
            bootstrap.config[:winrm_authentication_protocol] = locate_config_value(:winrm_authentication_protocol)
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
        bootstrap.config[:encrypted_data_bag_secret] = locate_config_value(:encrypted_data_bag_secret)
        bootstrap.config[:encrypted_data_bag_secret_file] = locate_config_value(:encrypted_data_bag_secret_file)
        bootstrap_common_params(bootstrap, server)
      end

      def bootstrap_for_node(server,fqdn,port)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [fqdn]
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
        bootstrap.config[:ssh_password] = locate_config_value(:ssh_password)
        bootstrap.config[:ssh_port] = port
        bootstrap.config[:identity_file] = locate_config_value(:identity_file)
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || server.name
        bootstrap.config[:use_sudo] = true unless locate_config_value(:ssh_user) == 'root'
        bootstrap.config[:use_sudo_password] = true if bootstrap.config[:use_sudo]
        bootstrap.config[:environment] = locate_config_value(:environment)
        # may be needed for vpc_mode
        bootstrap.config[:host_key_verify] = config[:host_key_verify]
        bootstrap.config[:secret] = locate_config_value(:secret)
        bootstrap.config[:secret_file] = locate_config_value(:secret_file)

        bootstrap_common_params(bootstrap, server)
      end

      def validate!
        super([
              :azure_subscription_id,
              :azure_mgmt_cert,
              :azure_api_host_name,
              :azure_source_image,
              :azure_vm_size,
        ])

        if locate_config_value(:winrm_password) and (locate_config_value(:winrm_password).length <= 6 and locate_config_value(:winrm_password).length >= 72)
          ui.error("The supplied password must be 6-72 characters long and meet password complexity requirements")
          exit 1
        end

        if locate_config_value(:ssh_password) and (locate_config_value(:ssh_password).length <= 6 and locate_config_value(:ssh_password).length >= 72)
          ui.error("The supplied password must be 6-72 characters long and meet password complexity requirements")
          exit 1
        end

        if locate_config_value(:azure_connect_to_existing_dns) && locate_config_value(:azure_vm_name).nil?
          ui.error("Specify the VM name using --azure-vm-name option, since you are connecting to existing dns")
          exit 1
        end

        if locate_config_value(:azure_service_location) && locate_config_value(:azure_affinity_group)
          ui.error("Cannot specify both --azure-service-location and --azure-affinity-group, use one or the other.")
          exit 1
        elsif locate_config_value(:azure_service_location).nil? && locate_config_value(:azure_affinity_group).nil?
          ui.error("Must specify either --azure-service-location or --azure-affinity-group.")
          exit 1
        end

        if locate_config_value(:winrm_authentication_protocol) && ! %w{basic negotiate kerberos}.include?(locate_config_value(:winrm_authentication_protocol))
          ui.error("Invalid value for --winrm-authentication-protocol option. Use valid protocol values i.e [basic, negotiate, kerberos]")
          exit 1
        end

        if !(connection.images.exists?(locate_config_value(:azure_source_image)))
          ui.error("Image provided is invalid")
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
          :winrm_user => locate_config_value(:winrm_user),
          :azure_availability_set => locate_config_value(:azure_availability_set),
          :azure_affinity_group => locate_config_value(:azure_affinity_group),
          :azure_network_name => locate_config_value(:azure_network_name),
          :azure_subnet_name => locate_config_value(:azure_subnet_name),
          :ssl_cert_fingerprint => locate_config_value(:thumbprint),
          :cert_path => locate_config_value(:cert_path),
          :cert_password => locate_config_value(:cert_passphrase)
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

        if locate_config_value(:bootstrap_protocol) == 'cloud-api'
          server_def[:chef_extension] = get_chef_extension_name
          server_def[:chef_extension_publisher] = get_chef_extension_publisher
          server_def[:chef_extension_version] = get_chef_extension_version
          server_def[:chef_extension_public_param] = get_chef_extension_public_params
          server_def[:chef_extension_private_param] = get_chef_extension_private_params
        else
          if is_image_windows?
            if not locate_config_value(:winrm_password) or not locate_config_value(:bootstrap_protocol)
              ui.error("WinRM Password and Bootstrapping Protocol are compulsory parameters")
              exit 1
            end
            # We can specify the AdminUsername after API version 2013-03-01. However, in this API version,
            # the AdminUsername is a required parameter.
            # Also, the user name cannot be Administrator, Admin, Admin1 etc, for enhanced security (provided by Azure)
            if locate_config_value(:winrm_user).nil? || locate_config_value(:winrm_user).downcase =~ /admin*/
              ui.error("WinRM User is compulsory parameter and it cannot be named 'admin*'")
              exit 1
            end
          else
            if not locate_config_value(:ssh_user)
              ui.error("SSH User is compulsory parameter")
              exit 1
            end
            unless locate_config_value(:ssh_password) or locate_config_value(:identity_file)
              ui.error("Specify either SSH Key or SSH Password")
              exit 1
            end
          end
        end
        if is_image_windows?
          server_def[:os_type] = 'Windows'
          server_def[:admin_password] = locate_config_value(:winrm_password)
          server_def[:bootstrap_proto] = locate_config_value(:bootstrap_protocol)
        else
          server_def[:os_type] = 'Linux'
          server_def[:bootstrap_proto] =  locate_config_value(:bootstrap_protocol) || 'ssh'
          server_def[:ssh_user] = locate_config_value(:ssh_user)
          server_def[:ssh_password] = locate_config_value(:ssh_password)
          server_def[:identity_file] = locate_config_value(:identity_file)
          server_def[:identity_file_passphrase] = locate_config_value(:identity_file_passphrase)
        end

        server_def[:is_vm_image] = connection.images.is_vm_image(locate_config_value(:azure_source_image))
        server_def
      end

      def get_chef_extension_name
        extension_name = is_image_windows? ? "ChefClient" : "LinuxChefClient"
      end

      def get_chef_extension_publisher
        publisher = "Chef.Bootstrap.WindowsAzure"
      end

      # get latest version
      def get_chef_extension_version
        extensions = @connection.query_azure("resourceextensions/#{get_chef_extension_publisher}/#{get_chef_extension_name}")
        extensions.css("Version").max.text.to_f
      end

      def get_chef_extension_public_params
        pub_config = Hash.new
        pub_config[:client_rb] = "chef_server_url \t #{Chef::Config[:chef_server_url].to_json}\nvalidation_client_name\t#{Chef::Config[:validation_client_name].to_json}"
        pub_config[:runlist] = locate_config_value(:run_list).empty? ? "" : locate_config_value(:run_list).join(",").to_json
        Base64.encode64(pub_config.to_json)
      end

      def get_chef_extension_private_params
        pri_config = Hash.new
        pri_config[:validation_key] = File.read(Chef::Config[:validation_key])
        Base64.encode64(pri_config.to_json)
      end

      def cleanup_and_exit(remove_hosted_service_on_failure, remove_storage_service_on_failure)
        ui.warn("Cleaning up resources...")

        if remove_hosted_service_on_failure
          ret_val = connection.hosts.delete(remove_hosted_service_on_failure)
          ret_val.content.empty? ? ui.warn("Deleted created DNS: #{remove_hosted_service_on_failure}.") : ui.warn("Deletion failed for created DNS:#{remove_hosted_service_on_failure}. " + ret_val.text)
        end

        if remove_storage_service_on_failure
          ret_val = connection.storageaccounts.delete(remove_storage_service_on_failure)
          ret_val.content.empty? ? ui.warn("Deleted created Storage Account: #{remove_storage_service_on_failure}.") : ui.warn("Deletion failed for created Storage Account: #{remove_storage_service_on_failure}. " + ret_val.text)
        end
        exit 1
      end

      private

      def ssh_override_winrm
        # unchanged ssh_user and changed winrm_user, override ssh_user
        if locate_config_value(:ssh_user).eql?(options[:ssh_user][:default]) &&
            !locate_config_value(:winrm_user).eql?(options[:winrm_user][:default])
          config[:ssh_user] = locate_config_value(:winrm_user)
        end
        # unchanged ssh_port and changed winrm_port, override ssh_port
        if locate_config_value(:ssh_port).eql?(options[:ssh_port][:default]) &&
            !locate_config_value(:winrm_port).eql?(options[:winrm_port][:default])
          config[:ssh_port] = locate_config_value(:winrm_port)
        end
        # unset ssh_password and set winrm_password, override ssh_password
        if locate_config_value(:ssh_password).nil? &&
            !locate_config_value(:winrm_password).nil?
          config[:ssh_password] = locate_config_value(:winrm_password)
        end
        # unset identity_file and set kerberos_keytab_file, override identity_file
        if locate_config_value(:identity_file).nil? &&
            !locate_config_value(:kerberos_keytab_file).nil?
          config[:identity_file] = locate_config_value(:kerberos_keytab_file)
        end
      end

      # This is related to Windows VM's specifically and computer name
      # length limits for legacy computer accounts
      MAX_VM_NAME_CHARACTERS = 15

      # generate a random dns_name if azure_dns_name is empty
      def get_dns_name(azure_dns_name, prefix = "az-")
        return azure_dns_name unless azure_dns_name.nil?
        if locate_config_value(:azure_vm_name).nil?
          azure_dns_name = prefix + SecureRandom.hex(( MAX_VM_NAME_CHARACTERS - prefix.length)/2)
        else
          azure_dns_name = locate_config_value(:azure_vm_name)
        end
      end
    end
  end
end
