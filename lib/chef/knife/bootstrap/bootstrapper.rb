#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
#
# Copyright:: Copyright (c) 2016 Opscode, Inc.
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

        def load_winrm_deps
          require 'winrm'
          require 'chef/knife/winrm'
          require 'chef/knife/bootstrap_windows_winrm'
        end

        def default_bootstrap_template
          is_image_windows? ? 'windows-chef-client-msi' : 'chef-full'
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

        def bootstrap_exec(server)
          fqdn = server.publicipaddress

          if is_image_windows?
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
            bootstrap_for_windows_node(server, fqdn, port).run
          else
            unless server && server.publicipaddress && server.sshport
              Chef::Log.fatal("server not created")
              exit 1
            end

            port = server.sshport

            print ui.color("Waiting for sshd on #{fqdn}:#{port}", :magenta)

            print(".") until tcp_test_ssh(fqdn,port) {
              sleep @initial_sleep_delay ||= 10
              puts("done")
            }

            puts("\n")
            bootstrap_for_node(server, fqdn, port).run
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
          bootstrap.config[:run_list] = locate_config_value(:run_list)
          bootstrap.config[:prerelease] = locate_config_value(:prerelease)
          bootstrap.config[:first_boot_attributes] = locate_config_value(:json_attributes) || {}
          bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
          bootstrap.config[:distro] = locate_config_value(:distro) || default_bootstrap_template
          # setting bootstrap_template value to template_file for backward
          bootstrap.config[:template_file] = locate_config_value(:template_file) || locate_config_value(:bootstrap_template)
          bootstrap.config[:node_ssl_verify_mode] = locate_config_value(:node_ssl_verify_mode)
          bootstrap.config[:node_verify_api_cert] = locate_config_value(:node_verify_api_cert)
          bootstrap.config[:bootstrap_no_proxy] = locate_config_value(:bootstrap_no_proxy)
          bootstrap.config[:bootstrap_url] = locate_config_value(:bootstrap_url)
          bootstrap.config[:bootstrap_vault_file] = locate_config_value(:bootstrap_vault_file)
          bootstrap.config[:bootstrap_vault_json] = locate_config_value(:bootstrap_vault_json)
          bootstrap.config[:bootstrap_vault_item] = locate_config_value(:bootstrap_vault_item)

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
            bootstrap.config[:auth_timeout] = locate_config_value(:auth_timeout)
            # Todo: we should skip cert generate in case when winrm_ssl_verify_mode=verify_none
            bootstrap.config[:winrm_ssl_verify_mode] = locate_config_value(:winrm_ssl_verify_mode)
          elsif locate_config_value(:bootstrap_protocol) == 'ssh'
            bootstrap = Chef::Knife::BootstrapWindowsSsh.new
            bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
            bootstrap.config[:ssh_password] = locate_config_value(:ssh_password)
            bootstrap.config[:forward_agent] = locate_config_value(:forward_agent)
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
          bootstrap.config[:msi_url] = locate_config_value(:msi_url)
          bootstrap.config[:install_as_service] = locate_config_value(:install_as_service)
          bootstrap_common_params(bootstrap, server)
        end

        def bootstrap_for_node(server, fqdn, port)
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
          Chef::Config[:knife][:secret] = config[:encrypted_data_bag_secret] if config[:encrypted_data_bag_secret]
          Chef::Config[:knife][:secret_file] = config[:encrypted_data_bag_secret_file] if config[:encrypted_data_bag_secret_file]
          bootstrap.config[:secret] = locate_config_value(:secret) || locate_config_value(:encrypted_data_bag_secret)
          bootstrap.config[:secret_file] = locate_config_value(:secret_file) || locate_config_value(:encrypted_data_bag_secret_file)
          bootstrap.config[:bootstrap_install_command] = locate_config_value(:bootstrap_install_command)
          bootstrap.config[:bootstrap_wget_options] = locate_config_value(:bootstrap_wget_options)
          bootstrap.config[:bootstrap_curl_options] = locate_config_value(:bootstrap_curl_options)
          bootstrap_common_params(bootstrap, server)
        end

        def get_chef_extension_name
          is_image_windows? ? "ChefClient" : "LinuxChefClient"
        end

        def get_chef_extension_publisher
          "Chef.Bootstrap.WindowsAzure"
        end

        # get latest version
        def get_chef_extension_version(chef_extension_name = nil)
          if locate_config_value(:azure_chef_extension_version)
            Chef::Config[:knife][:azure_chef_extension_version]
          else
            chef_extension_name = chef_extension_name.nil? ? get_chef_extension_name : chef_extension_name
            if @service.instance_of? Azure::ResourceManagement::ARMInterface
              service.get_latest_chef_extension_version({
                :azure_service_location => locate_config_value(:azure_service_location),
                :chef_extension_publisher => get_chef_extension_publisher,
                :chef_extension => chef_extension_name
              })
            elsif @service.instance_of? Azure::ServiceManagement::ASMInterface
              extensions = service.get_extension(chef_extension_name, get_chef_extension_publisher)
              extensions.css("Version").max.text.split(".").first + ".*"
            end
          end
        end

        def default_hint_options
          [
            'vm_name',
            'public_fqdn',
            'platform'
          ]
        end

        def ohai_hints
          hint_values = locate_config_value(:ohai_hints)

          if hint_values.casecmp('default').zero?
            hints = default_hint_options
          else
            hints = hint_values.split(',')
          end

          hints
        end

        def get_chef_extension_public_params
          pub_config = Hash.new
          if(locate_config_value(:azure_extension_client_config))
            pub_config[:client_rb] = File.read(locate_config_value(:azure_extension_client_config))
          else
            pub_config[:client_rb] = "chef_server_url \t #{Chef::Config[:chef_server_url].to_json}\nvalidation_client_name\t#{Chef::Config[:validation_client_name].to_json}"
          end

          pub_config[:runlist] = locate_config_value(:run_list).empty? ? "" : locate_config_value(:run_list).join(",").to_json
          pub_config[:custom_json_attr] = locate_config_value(:json_attributes) || {}
          pub_config[:extendedLogs] = locate_config_value(:extended_logs) ? "true" : "false"
          pub_config[:hints] = ohai_hints if @service.instance_of?(Azure::ResourceManagement::ARMInterface) && !locate_config_value(:ohai_hints).nil?

          # bootstrap attributes
          pub_config[:bootstrap_options] = {}
          pub_config[:bootstrap_options][:environment] = locate_config_value(:environment) if locate_config_value(:environment)
          pub_config[:bootstrap_options][:chef_node_name] = locate_config_value(:chef_node_name) if locate_config_value(:chef_node_name)

          if ( locate_config_value(:secret_file) || locate_config_value(:encrypted_data_bag_secret_file) ) && ( !locate_config_value(:secret) || !locate_config_value(:encrypted_data_bag_secret) )
            pub_config[:bootstrap_options][:encrypted_data_bag_secret] = Chef::EncryptedDataBagItem.load_secret(config[:secret_file])
          elsif locate_config_value(:encrypted_data_bag_secret) || locate_config_value(:secret)
            pub_config[:bootstrap_options][:encrypted_data_bag_secret] = locate_config_value(:encrypted_data_bag_secret) || locate_config_value(:secret)
          end

          pub_config[:bootstrap_options][:chef_server_url] = Chef::Config[:chef_server_url] if Chef::Config[:chef_server_url]
          pub_config[:bootstrap_options][:validation_client_name] = Chef::Config[:validation_client_name] if Chef::Config[:validation_client_name]
          pub_config[:bootstrap_options][:node_verify_api_cert] = locate_config_value(:node_verify_api_cert) ? "true" : "false" if config.key?(:node_verify_api_cert)
          pub_config[:bootstrap_options][:bootstrap_version] = locate_config_value(:bootstrap_version) if locate_config_value(:bootstrap_version)
          pub_config[:bootstrap_options][:node_ssl_verify_mode] = locate_config_value(:node_ssl_verify_mode) if locate_config_value(:node_ssl_verify_mode)
          pub_config[:bootstrap_options][:bootstrap_proxy] = locate_config_value(:bootstrap_proxy) if locate_config_value(:bootstrap_proxy)

          pub_config
        end

        def get_chef_extension_private_params
          pri_config = Hash.new

          # validator less bootstrap support for bootstrap protocol cloud-api
          if (Chef::Config[:validation_key] && !File.exist?(File.expand_path(Chef::Config[:validation_key])))

            if Chef::VERSION.split('.').first.to_i == 11
              ui.error('Unable to find validation key. Please verify your configuration file for validation_key config value.')
              exit 1
            end

            client_builder = Chef::Knife::Bootstrap::ClientBuilder.new(
              chef_config: Chef::Config,
              knife_config: config,
              ui: ui,
            )

            client_builder.run
            key_path = client_builder.client_path
            pri_config[:client_pem] = File.read(key_path)
          else
            pri_config[:validation_key] = File.read(Chef::Config[:validation_key])
          end

          # SSL cert bootstrap support
          if locate_config_value(:cert_path)
            if File.exist?(File.expand_path(locate_config_value(:cert_path)))
              pri_config[:chef_server_crt] = File.read(locate_config_value(:cert_path))
            else
              ui.error('Specified SSL certificate does not exist.')
              exit 1
            end
          end

          pri_config
        end
      end
    end
  end
end
