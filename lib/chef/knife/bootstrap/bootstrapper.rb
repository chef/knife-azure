#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
# Author:: Nimesh Patni (nimesh.patni@msystechnologies.com)
#
# Copyright:: Copyright 2008-2019, Chef Software, Inc.
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

class Chef
  class Knife
    class Bootstrap
      module Bootstrapper

        # @return [Boolean] True if the --connection-protocol was 'winrm'
        def winrm?
          locate_config_value(:connection_protocol) == "winrm"
        end

        # @return [String] windows-chef-client-msi for windows target
        #  otherwise "chef-full"
        def default_bootstrap_template
          is_image_windows? ? "windows-chef-client-msi" : "chef-full"
        end

        # Loads winrm related modules
        def load_winrm_deps
          require "winrm"
          require "chef/knife/winrm"
          require "gssapi" unless Chef::Platform.windows?
        end

        # @return [Array<Symbol>] list of connectivity related bootstrap options
        def connectivity_opts
          %i{connection_user
             connection_password
             connection_port
             connection_protocol
             max_wait
             session_timeout}
        end

        # @return [Array<Symbol>] list of WINRM related bootstrap options
        def winrm_opts
          %i{winrm_ssl_peer_fingerprint
             ca_trust_file
             winrm_no_verify_cert
             winrm_ssl
             winrm_auth_method
             winrm_basic_auth_only
             kerberos_realm
             kerberos_service}
        end

        # @return [Array<Symbol>] list of SSH related bootstrap options
        def ssh_opts
          %i{ssh_gateway
             ssh_gateway_identity
             ssh_forward_agent
             ssh_identity_file
             ssh_verify_host_key}
        end

        # @return [Array<Symbol>] list of connectivity related bootstrap options
        # @note msi_url is for Windows target only, and therefore not included in this list
        def common_bootstrap_opts
          %i{bootstrap_version
             channel
             bootstrap_proxy
             bootstrap_proxy_user
             bootstrap_proxy_pass
             bootstrap_no_proxy
             bootstrap_template
             node_ssl_verify_mode
             node_verify_api_cert
             use_sudo
             preserve_home
             use_sudo_password
             chef_node_name
             run_list
             policy_name
             policy_group
             tags
             first_boot_attributes
             first_boot_attributes_from_file
             hint
             bootstrap_url
             bootstrap_install_command
             bootstrap_preinstall_command
             bootstrap_wget_options
             bootstrap_curl_options
             bootstrap_vault_file
             bootstrap_vault_item
             bootstrap_vault_json}
        end

        # @return [Array<Symbol>] list of other bootstrap options
        def other_bootstrap_opts
          %i{encrypted_data_bag_secret
             encrypted_data_bag_secret_file
             distro
             template_file
             environment}
        end

        # @param options [Array] list of options
        #   Common logic to configure options for Chef::Knife::Bootstrap
        def configure(options)
          options.each do |option|
            @bootstrap.config[option] = locate_config_value(option)
          end
        end

        # Configures common options for Chef::Knife::Bootstrap.
        def config_common_bootstraps
          configure(common_bootstrap_opts)
          unless @bootstrap.config[:first_boot_attributes]
            @bootstrap.config[:first_boot_attributes] = locate_config_value(:json_attributes) || {}
          end
          use_sudo = locate_config_value(:connection_user) == "root"
          @bootstrap.config[:use_sudo] = use_sudo
          @bootstrap.config[:use_sudo_password] = use_sudo
        end

        # Configures connectivity related options for Chef::Knife::Bootstrap.
        def config_connectivity(server, fqdn, port)
          configure(connectivity_opts)
          @bootstrap.config[:connection_port] ||= port
          @bootstrap.config[:chef_node_name] ||= server.name
          @bootstrap.name_args = [fqdn]
        end

        # Configures WINRM related options for Chef::Knife::Bootstrap.
        def config_winrm
          configure(winrm_opts)
        end

        # Configures SSH related options for Chef::Knife::Bootstrap.
        def config_ssh
          configure(ssh_opts)
        end

        # Configures windows specific options for Chef::Knife::Bootstrap.
        def config_windows
          @bootstrap.config[:connection_user] ||= "Administrator"
          @bootstrap.config[:msi_url] = locate_config_value(:msi_url)
        end

        # Configures non-windows options for Chef::Knife::Bootstrap.
        def config_linux
          # Confirmation Required!
          # @bootstrap.config[:connection_user] ||= "root"
        end

        # Configures data-bag related options for Chef::Knife::Bootstrap.
        # Confirmation Required! It does not seems to be significant
        def config_data_bag
          if config[:encrypted_data_bag_secret]
            Chef::Config[:knife][:secret] = config[:encrypted_data_bag_secret]
            @bootstrap.config[:secret] = locate_config_value(:encrypted_data_bag_secret)
          end

          if config[:encrypted_data_bag_secret_file]
            Chef::Config[:knife][:secret_file] = config[:encrypted_data_bag_secret_file]
            @bootstrap.config[:secret_file] = locate_config_value(:encrypted_data_bag_secret_file)
          end
        end

        # Configures other options for Chef::Knife::Bootstrap.
        # Confirmation Required! It might not be significant and could be cleaned up. Have kept it
        # as it was implemented previously
        def config_other_bootstraps
          configure(other_bootstrap_opts)
          config_data_bag

          # setting bootstrap_template value to template_file for backward compatibility
          @bootstrap.config[:template_file] ||= locate_config_value(:bootstrap_template)
          @bootstrap.config[:distro] ||= default_bootstrap_template
        end

        # @param fqdn [String]
        # @param port [String]
        #   Method to test WINRM connection
        def tcp_test_winrm(fqdn, port)
          socket = TCPSocket.new(fqdn, port)
          true
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

        # @param fqdn [String]
        # @param port [String]
        #   Method to test SSH connection
        def tcp_test_ssh(fqdn, port)
          tcp_socket = TCPSocket.new(fqdn, port)
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

        # @param fqdn [String]
        # @param port [String]
        #   Method to establish a WINRM connection
        def connect_winrm(fqdn, port)
          print ui.color("Waiting for winrm on #{fqdn}:#{port}", :magenta).to_s
          print(".") until tcp_test_winrm(fqdn, port) do
            sleep @initial_sleep_delay ||= 10
            puts("done")
          end
        end

        # @param fqdn [String]
        # @param port [String]
        #   Method to establish a SSH connection
        def connect_ssh(fqdn, port)
          print ui.color("Waiting for sshd on #{fqdn}:#{port}", :magenta).to_s
          print(".") until tcp_test_ssh(fqdn, port) do
            sleep @initial_sleep_delay ||= 10
            puts("done")
          end
        end

        # @param server [Object]
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

        # @param server [Object]
        # @param fqdn [String]
        # @param port [String]
        # @return [Chef::Knife::Bootstrap] a loaded object with options
        #   Method to set configurations that would be required to bootstrap a node
        def bootstrap_node(server, fqdn, port)
          @bootstrap = Chef::Knife::Bootstrap.new

          config_common_bootstraps
          config_connectivity(server, fqdn, port)

          if is_image_windows?
            config_windows
          else
            config_linux
          end

          if winrm?
            load_winrm_deps
            config_winrm
          else
            config_ssh
          end

          config_other_bootstraps

          load_cloud_attributes_in_hints(server)
          @bootstrap
        end

        # @param server [Object]
        # Method to set connections and bootstrap a node and returns summary
        def bootstrap_exec(server)
          fqdn = server.publicipaddress
          port = winrm? ? server.winrmport : server.sshport

          unless server && fqdn && port
            Chef::Log.fatal("server not created")
            exit 1
          end

          if winrm?
            connect_winrm(fqdn, port)
          else
            connect_ssh(fqdn, port)
          end

          bootstrap_node(server, fqdn, port).run

          msg_server_summary(server)
        end

        ######################################################
        # Following methods are either
        # - Knife-Azure specific
        # - Does NOT configure Chef::Knife::Bootstrap
        ######################################################

        def get_chef_extension_name
          is_image_windows? ? "ChefClient" : "LinuxChefClient"
        end

        def get_chef_extension_publisher
          "Chef.Bootstrap.WindowsAzure"
        end

        def default_hint_options
          %w{
            vm_name
            public_fqdn
            platform
          }
        end

        # get latest version
        def get_chef_extension_version(chef_extension_name = nil)
          if locate_config_value(:azure_chef_extension_version)
            Chef::Config[:knife][:azure_chef_extension_version]
          else
            chef_extension_name ||= get_chef_extension_name
            if @service.instance_of? Azure::ResourceManagement::ARMInterface
              service.get_latest_chef_extension_version(
                azure_service_location: locate_config_value(:azure_service_location),
                chef_extension_publisher: get_chef_extension_publisher,
                chef_extension: chef_extension_name
              )
            elsif @service.instance_of? Azure::ServiceManagement::ASMInterface
              extensions = service.get_extension(chef_extension_name, get_chef_extension_publisher)
              extensions.css("Version").max.text.split(".").first + ".*"
            end
          end
        end

        def ohai_hints
          hint_values = locate_config_value(:ohai_hints)
          if hint_values.casecmp("default") == 0
            default_hint_options
          else
            hint_values.split(",")
          end
        end

        def get_chef_extension_public_params
          pub_config = {}
          if locate_config_value(:azure_extension_client_config)
            pub_config[:client_rb] = File.read(File.expand_path(locate_config_value(:azure_extension_client_config)))
          else
            pub_config[:client_rb] = "chef_server_url \t #{Chef::Config[:chef_server_url].to_json}\nvalidation_client_name\t#{Chef::Config[:validation_client_name].to_json}"
          end

          pub_config[:runlist] = locate_config_value(:run_list).empty? ? "" : locate_config_value(:run_list).join(",").to_json
          pub_config[:custom_json_attr] = locate_config_value(:json_attributes) || {}
          pub_config[:extendedLogs] = locate_config_value(:extended_logs) ? "true" : "false"
          pub_config[:hints] = ohai_hints if @service.instance_of?(Azure::ResourceManagement::ARMInterface) && !locate_config_value(:ohai_hints).nil?
          pub_config[:chef_daemon_interval] = locate_config_value(:chef_daemon_interval) if locate_config_value(:chef_daemon_interval)
          pub_config[:daemon] = locate_config_value(:daemon) if locate_config_value(:daemon)

          # bootstrap attributes
          pub_config[:bootstrap_options] = {}
          pub_config[:bootstrap_options][:environment] = locate_config_value(:environment) if locate_config_value(:environment)
          pub_config[:bootstrap_options][:chef_node_name] = locate_config_value(:chef_node_name) if locate_config_value(:chef_node_name)
          pub_config[:bootstrap_options][:chef_server_url] = Chef::Config[:chef_server_url] if Chef::Config[:chef_server_url]
          pub_config[:bootstrap_options][:validation_client_name] = Chef::Config[:validation_client_name] if Chef::Config[:validation_client_name]
          pub_config[:bootstrap_options][:node_verify_api_cert] = locate_config_value(:node_verify_api_cert) ? "true" : "false" if config.key?(:node_verify_api_cert)
          pub_config[:bootstrap_options][:bootstrap_version] = locate_config_value(:bootstrap_version) if locate_config_value(:bootstrap_version)
          pub_config[:bootstrap_options][:node_ssl_verify_mode] = locate_config_value(:node_ssl_verify_mode) if locate_config_value(:node_ssl_verify_mode)
          pub_config[:bootstrap_options][:bootstrap_proxy] = locate_config_value(:bootstrap_proxy) if locate_config_value(:bootstrap_proxy)
          pub_config
        end

        def load_correct_secret
          knife_secret_file = Chef::Config[:knife][:encrypted_data_bag_secret_file]
          knife_secret = Chef::Config[:knife][:encrypted_data_bag_secret]
          cli_secret_file = config[:encrypted_data_bag_secret_file]
          cli_secret = config[:encrypted_data_bag_secret]

          # The value set in knife.rb gets set in config object too
          # That's why setting cli objects to nil if the values are specified in knife.rb
          cli_secret_file = nil if cli_secret_file == knife_secret_file
          cli_secret = nil if cli_secret == knife_secret

          cli_secret_file = Chef::EncryptedDataBagItem.load_secret(cli_secret_file) unless cli_secret_file.nil?
          knife_secret_file = Chef::EncryptedDataBagItem.load_secret(knife_secret_file) unless knife_secret_file.nil?

          cli_secret_file || cli_secret || knife_secret_file || knife_secret
        end

        def create_node_and_client_pem
          client_builder ||= begin
            require "chef/knife/bootstrap/client_builder"
            Chef::Knife::Bootstrap::ClientBuilder.new(
              chef_config: Chef::Config,
              knife_config: config,
              ui: ui
            )
          end
          client_builder.run
          client_builder.client_path
        end

        def get_chef_extension_private_params
          pri_config = {}
          # validator less bootstrap support for bootstrap protocol cloud-api
          if Chef::Config[:validation_key] && File.exist?(File.expand_path(Chef::Config[:validation_key]))
            pri_config[:validation_key] = File.read(File.expand_path(Chef::Config[:validation_key]))
          else
            if Chef::VERSION.split(".").first.to_i == 11
              ui.error("Unable to find validation key. Please verify your configuration file for validation_key config value.")
              exit 1
            end
            if config[:server_count].to_i > 1
              node_name = config[:chef_node_name]
              0.upto(config[:server_count].to_i - 1) do |count|
                config[:chef_node_name] = node_name + count.to_s
                key_path = create_node_and_client_pem
                pri_config[("client_pem" + count.to_s).to_sym] = File.read(key_path)
              end
              config[:chef_node_name] = node_name
            else
              key_path = create_node_and_client_pem
              if File.exist?(key_path)
                pri_config[:client_pem] = File.read(key_path)
              else
                ui.error('Unable to find client.pem at given path #{key_path}')
                exit 1
              end
            end
          end

          # SSL cert bootstrap support
          if locate_config_value(:cert_path)
            if File.exist?(File.expand_path(locate_config_value(:cert_path)))
              pri_config[:chef_server_crt] = File.read(File.expand_path(locate_config_value(:cert_path)))
            else
              ui.error("Specified SSL certificate does not exist.")
              exit 1
            end
          end

          # encrypted_data_bag_secret key for encrypting/decrypting the data bags
          pri_config[:encrypted_data_bag_secret] = load_correct_secret

          pri_config
        end

      end
    end
  end
end
