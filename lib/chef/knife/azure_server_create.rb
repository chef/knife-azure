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
require 'chef/knife/bootstrap/bootstrap_options'
require 'chef/knife/bootstrap/bootstrapper'

class Chef
  class Knife
    class AzureServerCreate < Knife

      include Knife::AzureBase
      include Knife::WinrmBase
      include Knife::Bootstrap::BootstrapOptions
      include Knife::Bootstrap::Bootstrapper

      deps do
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        require 'chef/knife/bootstrap_windows_ssh'
        require 'chef/knife/core/windows_bootstrap_context'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife azure server create (options)"

      attr_accessor :initial_sleep_delay


      option :bootstrap_protocol,
        :long => "--bootstrap-protocol protocol",
        :description => "Protocol to bootstrap windows servers. options: 'winrm' or 'ssh' or 'cloud-api'.",
        :default => "winrm"

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
        :description => "The ssh port. Default is 22. If --azure-connect-to-existing-dns set then default SSH port is random"

      option :node_ssl_verify_mode,
        :long        => "--node-ssl-verify-mode [peer|none]",
        :description => "Whether or not to verify the SSL cert for all HTTPS requests.",
        :proc        => Proc.new { |v|
          valid_values = ["none", "peer"]
          unless valid_values.include?(v)
            raise "Invalid value '#{v}' for --node-ssl-verify-mode. Valid values are: #{valid_values.join(", ")}"
          end
        }

      option :node_verify_api_cert,
        :long        => "--[no-]node-verify-api-cert",
        :description => "Verify the SSL cert for HTTPS requests to the Chef server API.",
        :boolean     => true

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
                                      Eg: West US, East US, East Asia, Southeast Asia, North Europe, West Europe",
        :proc        => Proc.new { |lo| Chef::Config[:knife][:azure_service_location] = lo }

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
        :default => 'Small',
        :proc => Proc.new { |si| Chef::Config[:knife][:azure_vm_size] = si }

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

      option :azure_vm_startup_timeout,
        :long => "--azure-vm-startup-timeout TIMEOUT",
        :description => "The number of minutes that knife-azure will wait for the virtual machine to reach the 'provisioning' state. Default is 10.",
        :default => 10

      option :azure_vm_ready_timeout,
        :long => "--azure-vm-ready-timeout TIMEOUT",
        :description => "The number of minutes that knife-azure will wait for the virtual machine state to transition from 'provisioning' to 'ready'. Default is 15.",
        :default => 15

      option :auth_timeout,
        :long => "--windows-auth-timeout MINUTES",
        :description => "The maximum time in minutes to wait to for authentication over the transport to the node to succeed. The default value is 25 minutes.",
        :default => 25

      option :identity_file,
        :long => "--identity-file FILENAME",
        :description => "SSH identity file for authentication, optional. It is the RSA private key path. Specify either ssh-password or identity-file"

      option :identity_file_passphrase,
        :long => "--identity-file-passphrase PASSWORD",
        :description => "SSH key passphrase. Optional, specify if passphrase for identity-file exists"

      option :thumbprint,
        :long => "--thumbprint THUMBPRINT",
        :description => "The thumprint of the ssl certificate"

      option :cert_passphrase,
        :long => "--cert-passphrase PASSWORD",
        :description => "SSL Certificate Password"

      option :cert_path,
        :long => "--cert-path PATH",
        :description => "SSL Certificate Path"

      option :winrm_max_timeout,
        :long => "--winrm-max-timeout MINUTES",
        :description => "Set winrm maximum command timeout in minutes, useful for long bootstraps"

      option :winrm_max_memorypershell,
        :long => "--winrm-max-memory-per-shell",
        :description => "Set winrm max memory per shell in MB"

      option :azure_domain_name,
        :long => "--azure-domain-name DOMAIN_NAME",
        :description => "Optional. Specifies the domain name to join. If the domains name is not specified, --azure-domain-user must specify the user principal name (UPN) format (user@fully-qualified-DNS-domain) or the fully-qualified-DNS-domain\\username format"

      option :azure_domain_ou_dn,
        :long => "--azure-domain-ou-dn DOMAIN_OU_DN",
        :description => "Optional. Specifies the (LDAP) X 500-distinguished name of the organizational unit (OU) in which the computer account is created. This account is in Active Directory on a domain controller in the domain to which the computer is being joined. Example: OU=HR,dc=opscode,dc=com"

      option :azure_domain_user,
        :long => "--azure-domain-user DOMAIN_USER_NAME",
        :description => 'Optional. Specifies the username who has access to join the domain.
          Supported format: username(if domain is already specified in --azure-domain-name option),
          fully-qualified-DNS-domain\username, user@fully-qualified-DNS-domain'

      option :azure_domain_passwd,
        :long => "--azure-domain-passwd DOMAIN_PASSWD",
        :description => "Optional. Specifies the password for domain user who has access to join the domain."

      option :azure_extension_client_config,
        :long => "--azure-extension-client-config CLIENT_PATH",
        :description => "Optional. Path to a client.rb file for use by the bootstrapped node. Only honored when --bootstrap-protocol is set to `cloud-api`."

      def wait_until_virtual_machine_ready(retry_interval_in_seconds = 30)
        vm_status = nil
        begin
          azure_vm_startup_timeout = locate_config_value(:azure_vm_startup_timeout).to_i
          azure_vm_ready_timeout = locate_config_value(:azure_vm_ready_timeout).to_i
          vm_status = wait_for_virtual_machine_state(:vm_status_provisioning, azure_vm_startup_timeout, retry_interval_in_seconds)
          if vm_status != :vm_status_ready
            begin
              wait_for_virtual_machine_state(:vm_status_ready, azure_vm_ready_timeout, retry_interval_in_seconds)
            rescue Chef::Exceptions::CommandTimeout => e
              ui.warn("\n#{e.message}")
              ui.warn("Ignoring failure to reach 'ready' with bootstrap.")
            end
          end

          msg_server_summary(service.get_role_server(locate_config_value(:azure_dns_name), locate_config_value(:azure_vm_name)))

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
        role = service.get_role_server(locate_config_value(:azure_dns_name), locate_config_value(:azure_vm_name))
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
        deployment_name = service.deployment_name(locate_config_value(:azure_dns_name))
        deployment = service.deployment("hostedservices/#{locate_config_value(:azure_dns_name)}/deployments/#{deployment_name}")
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
              elsif (role.at_css('GuestAgentStatus Status').text == 'NotReady') && (waagent_status_msg == lnx_waagent_fail_msg)
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

      def run
        $stdout.sync = true
        storage = nil
        Chef::Log.info("validating...")
        validate_asm_keys!(:azure_source_image)
        validate_params!
        ssh_override_winrm if !is_image_windows?
        Chef::Log.info("creating...")
        config[:azure_dns_name] = get_dns_name(locate_config_value(:azure_dns_name))
        config[:azure_vm_name] = locate_config_value(:azure_dns_name) unless locate_config_value(:azure_vm_name)
        config[:chef_node_name] = locate_config_value(:azure_vm_name) unless locate_config_value(:chef_node_name)
        service.create_server(create_server_def)
        wait_until_virtual_machine_ready()
        if locate_config_value(:bootstrap_protocol) == 'cloud-api' && locate_config_value(:extended_logs)
          print "\n\nWaiting for the first chef-client run"
          fetch_chef_client_logs(Time.now, 30)
        end
        server = service.get_role_server(locate_config_value(:azure_dns_name), locate_config_value(:azure_vm_name))
        msg_server_summary(server)

        bootstrap_exec(server) unless locate_config_value(:bootstrap_protocol) == 'cloud-api'
      end

      def create_server_def
        server_def = {
          :azure_storage_account => locate_config_value(:azure_storage_account),
          :azure_api_host_name => locate_config_value(:azure_api_host_name),
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
          :cert_password => locate_config_value(:cert_passphrase),
          :winrm_transport => locate_config_value(:winrm_transport),
          :winrm_max_timeout => locate_config_value(:winrm_max_timeout).to_i * 60 * 1000, #converting minutes to milliseconds
          :winrm_max_memoryPerShell => locate_config_value(:winrm_max_memory_per_shell)
        }

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
            # take cares of when user name contains domain
            # azure add role api doesn't support '\\' in user name
            if locate_config_value(:winrm_user) && locate_config_value(:winrm_user).split("\\").length.eql?(2)
              server_def[:winrm_user] = locate_config_value(:winrm_user).split("\\")[1]
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
          server_def[:bootstrap_proto] = (locate_config_value(:bootstrap_protocol) == 'winrm') ? 'ssh' : locate_config_value(:bootstrap_protocol)
          server_def[:ssh_user] = locate_config_value(:ssh_user)
          server_def[:ssh_password] = locate_config_value(:ssh_password)
          server_def[:identity_file] = locate_config_value(:identity_file)
          server_def[:identity_file_passphrase] = locate_config_value(:identity_file_passphrase)
        end

        azure_connect_to_existing_dns = locate_config_value(:azure_connect_to_existing_dns)
        if is_image_windows? && server_def[:bootstrap_proto] == 'winrm'
          port = locate_config_value(:winrm_port) || '5985'
          port = locate_config_value(:winrm_port) || Random.rand(64000) + 1000 if azure_connect_to_existing_dns
        elsif server_def[:bootstrap_proto] == 'ssh'
          port = locate_config_value(:ssh_port) || '22'
          port = locate_config_value(:ssh_port) || Random.rand(64000) + 1000 if azure_connect_to_existing_dns
        end

        server_def[:port] = port

        server_def[:is_vm_image] = service.vm_image?(locate_config_value(:azure_source_image))
        server_def[:azure_domain_name] = locate_config_value(:azure_domain_name) if locate_config_value(:azure_domain_name)

        if locate_config_value(:azure_domain_user)
          # extract domain name since it should be part of username
          case locate_config_value(:azure_domain_user)
          when /(\S+)\\(.+)/  # format - fully-qualified-DNS-domain\username
            server_def[:azure_domain_name] = $1 if locate_config_value(:azure_domain_name).nil?
            server_def[:azure_user_domain_name] = $1
            server_def[:azure_domain_user] = $2
          when /(.+)@(\S+)/  # format - user@fully-qualified-DNS-domain
            server_def[:azure_domain_name] = $2 if locate_config_value(:azure_domain_name).nil?
            server_def[:azure_user_domain_name] = $2
            server_def[:azure_domain_user] = $1
          else
            if locate_config_value(:azure_domain_name).nil?
              ui.error('--azure-domain-name should be specified if --azure-domain-user is not in one of the following formats: fully-qualified-DNS-domain\username, user@fully-qualified-DNS-domain')
              exit 1
            end
            server_def[:azure_domain_user] = locate_config_value(:azure_domain_user)
          end
        end
        server_def[:azure_domain_passwd] = locate_config_value(:azure_domain_passwd)
        server_def[:azure_domain_ou_dn] = locate_config_value(:azure_domain_ou_dn)

        server_def
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
        # unset identity_file and set _file, override identity_file
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
