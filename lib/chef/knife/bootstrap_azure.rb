#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
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

require 'chef/knife/azure_base'
require 'chef/knife/bootstrap/common_bootstrap_options'
require 'chef/knife/bootstrap/bootstrapper'

class Chef
  class Knife
    class BootstrapAzure < Knife

      include Knife::AzureBase
      include Knife::Bootstrap::CommonBootstrapOptions
      include Knife::Bootstrap::Bootstrapper

      banner "knife bootstrap azure SERVER (options)"

      option :azure_dns_name,
        :short => "-d DNS_NAME",
        :long => "--azure-dns-name DNS_NAME",
        :description => "Optional. The DNS prefix name that is used to access the cloud service."

      def run
        ui.info "Validating..."
        validate_asm_keys!

        begin
          if @name_args.length == 1
            service.add_extension(@name_args[0], set_ext_params)
          else
            raise ArgumentError, 'Please specify the SERVER name which needs to be bootstrapped via the Chef Extension.' if @name_args.length == 0
            raise ArgumentError, 'Please specify only one SERVER name which needs to be bootstrapped via the Chef Extension.' if @name_args.length > 1
          end
        rescue => error
          ui.error("#{error.message}")
          Chef::Log.debug("#{error.backtrace.join("\n")}")
          exit
        end
      end

      def set_ext_params
        begin
          ui.info "Looking for the server #{@name_args[0]}..."
          server = service.find_server({
              name: @name_args[0],
              azure_dns_name: locate_config_value(:azure_dns_name)
            })

          if !server.instance_of? Azure::Role
            if server.nil?
              if !locate_config_value(:azure_dns_name).nil?
                raise "Hosted service #{locate_config_value(:azure_dns_name)} does not exist."
              else
                raise "Server #{@name_args[0]} does not exist."
              end
            else
              raise "Server #{@name_args[0]} does not exist under the hosted service #{locate_config_value(:azure_dns_name)}."
            end
          end

          ui.info "\nServer #{@name_args[0]} found."
          ui.info "Setting the Chef Extension parameters."
          ext_params = Hash.new
          case server.os_type.downcase
          when 'windows'
            ext_params[:chef_extension] = 'ChefClient'
          when 'linux'
            if ['ubuntu', 'debian', 'rhel', 'centos'].any? { |platform| server.os_version.downcase.include? platform }
              ext_params[:chef_extension] = 'LinuxChefClient'
            else
              raise "OS version #{server.os_version} for OS type #{server.os_type} is not supported."
            end
          else
            raise "OS type #{server.os_type} is not supported."
          end

          ext_params[:azure_dns_name] = server.hostedservicename || locate_config_value(:azure_dns_name)
          ext_params[:deploy_name] = server.deployname
          ext_params[:role_xml] = server.role_xml
          ext_params[:azure_vm_name] = @name_args[0]
          ext_params[:chef_extension_publisher] = get_chef_extension_publisher
          ext_params[:chef_extension_version] = get_chef_extension_version(ext_params[:chef_extension])
          ext_params[:chef_extension_public_param] = get_chef_extension_public_params
          ext_params[:chef_extension_private_param] = get_chef_extension_private_params
        rescue => error
          ui.error("#{error.message}")
          Chef::Log.debug("#{error.backtrace.join("\n")}")
          exit
        end

        ext_params
      end
    end
  end
end
