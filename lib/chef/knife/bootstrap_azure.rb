#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
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

require "chef/knife/azure_base"
require "chef/knife/bootstrap"
require "chef/knife/bootstrap/common_bootstrap_options"
require "chef/knife/bootstrap/bootstrapper"

class Chef
  class Knife
    class BootstrapAzure < Knife::Bootstrap
      include Knife::AzureBase
      include Knife::Bootstrap::CommonBootstrapOptions
      include Knife::Bootstrap::Bootstrapper

      banner "knife bootstrap azure SERVER (options)"

      option :azure_dns_name,
        short: "-d DNS_NAME",
        long: "--azure-dns-name DNS_NAME",
        description: "Optional. The DNS prefix name that is used to access the cloud service."

      # run() would be executing from parent class
      # Chef::Knife::Bootstrap, defined in core.
      # Required methods have been overridden here
      #### run() execution begins ####

      def plugin_setup!; end

      def validate_name_args!; end

      def plugin_validate_options!
        ui.info "Validating..."
        validate_asm_keys!
      end

      def plugin_create_instance!
        if @name_args.length == 1
          service.add_extension(@name_args[0], set_ext_params)
          if locate_config_value(:extended_logs)
            print "\n\nWaiting for the Chef Extension to become available/ready"
            wait_until_extension_available(Time.now, 10)
            print "\n\nWaiting for the first chef-client run"
            fetch_chef_client_logs(Time.now, 35)
          end
        else
          raise ArgumentError, "Please specify the SERVER name which needs to be bootstrapped via the Chef Extension." if @name_args.empty?
          raise ArgumentError, "Please specify only one SERVER name which needs to be bootstrapped via the Chef Extension." if @name_args.length > 1
        end
      rescue StandardError => error
        ui.error(error.message.to_s)
        Chef::Log.debug(error.backtrace.join("\n").to_s)
        exit
      end

      def plugin_finalize; end

      # Following methods are not required
      #
      def connect!; end

      def register_client; end

      def render_template; end

      def upload_bootstrap(content); end

      def perform_bootstrap(bootstrap_path); end

      #### run() execution ends ####

      def set_ext_params
        begin
          ui.info "Looking for the server #{@name_args[0]}..."
          server = service.find_server(
            name: @name_args[0],
            azure_dns_name: locate_config_value(:azure_dns_name)
          )

          ## if azure_dns_name value not passed by user then set it using the hostedservicename attribute from the retrieved server's object ##
          config[:azure_dns_name] = server.hostedservicename if locate_config_value(:azure_dns_name).nil? && (server.instance_of? Azure::Role)
          unless server.instance_of? Azure::Role
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
          ext_params = {}
          case server.os_type.downcase
          when "windows"
            ext_params[:chef_extension] = "ChefClient"
          when "linux"
            if %w{ubuntu debian rhel centos}.any? { |platform| server.os_version.downcase.include? platform }
              ext_params[:chef_extension] = "LinuxChefClient"
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

      def wait_until_extension_available(extension_deploy_start_time, extension_availaibility_wait_timeout)
        extension_availaibility_wait_time = ((Time.now - extension_deploy_start_time) / 60).round
        if extension_availaibility_wait_time <= extension_availaibility_wait_timeout
          ## extension availaibility wait time has not exceeded the maximum threshold set for the wait timeout ##
          my_role = nil
          sleep_and_wait = false
          deployment = fetch_deployment
          if deployment.at_css("Deployment Name") != nil
            role_list_xml = deployment.css("RoleInstanceList RoleInstance")
            ## list of roles found under the deployment ##
            role_list_xml.each do |role|
              ## search in the roles list for the given role ##
              if role.at_css("RoleName").text == @name_args[0]
                my_role = role
                break
              end
            end

            if my_role && my_role.at_css("GuestAgentStatus Status").text == "Ready"
              ## given role found and also GuestAgent is ready ##
              extension = fetch_extension(my_role)
              ## check if Chef Extension not found (which means it is not available/ready yet) then sleep_and_wait OR
              ## if found (which means it is available/ready now) then proceed further with chef-client run logs fetch process ##
              sleep_and_wait = true if extension.nil?
            else
              ## given role not found or GuestAgent not ready yet ##
              sleep_and_wait = true
            end
          else
            ## deployment could not be found ##
            sleep_and_wait = true
          end

          ## wait for some time and then re-fetch the status ##
          if sleep_and_wait == true
            print "#{ui.color(".", :bold)}"
            sleep 30
            wait_until_extension_available(
              extension_deploy_start_time,
              extension_availaibility_wait_timeout
            )
          end
        else
          ## extension availaibility wait time exceeded maximum threshold set for the wait timeout ##
          raise "\nUnable to fetch chef-client run logs as Chef Extension seems to be unavailable even after #{extension_availaibility_wait_timeout} minutes of its deployment.\n"
        end
      end
    end
  end
end
