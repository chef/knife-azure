# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "chef/knife"

class Chef
  class Knife
    module AzureBase
      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do
          deps do
            require "readline"
            require "chef/json_compat"
            require_relative "../../../azure/service_management/ASM_interface"
          end

          option :azure_subscription_id,
            short: "-S ID",
            long: "--azure-subscription-id ID",
            description: "Your Azure subscription ID"

          option :azure_mgmt_cert,
            short: "-p FILENAME",
            long: "--azure-mgmt-cert FILENAME",
            description: "Your Azure PEM file name"

          option :azure_api_host_name,
            short: "-H HOSTNAME",
            long: "--azure-api-host-name HOSTNAME",
            description: "Your Azure host name"

          option :verify_ssl_cert,
            long: "--verify-ssl-cert",
            description: "Verify SSL Certificates for communication over HTTPS",
            boolean: true,
            default: false

          option :azure_publish_settings_file,
            long: "--azure-publish-settings-file FILENAME",
            description: "Your Azure Publish Settings File"
        end
      end

      def is_image_windows?
        images = service.list_images
        target_image = images.select { |i| i.name == config[:azure_source_image] }
        if target_image[0].nil?
          ui.error('Invalid image. Use the command "knife azure image list" to verify the image name')
          exit 1
        else
          target_image[0].os == "Windows"
        end
      end

      def service
        @service ||= begin
                      service = Azure::ServiceManagement::ASMInterface.new(
                        azure_subscription_id: config[:azure_subscription_id],
                        azure_mgmt_cert: config[:azure_mgmt_cert],
                        azure_api_host_name: config[:azure_api_host_name],
                        verify_ssl_cert: config[:verify_ssl_cert]
                      )
                    end
        @service.ui = ui
        @service
      end

      def msg_pair(label, value, color = :cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def msg_server_summary(server)
        puts "\n"
        msg_pair("DNS Name", server.hostedservicename + ".cloudapp.net")
        msg_pair("VM Name", server.name)
        msg_pair("Size", server.size)
        msg_pair("Azure Source Image", config[:azure_source_image])
        msg_pair("Azure Service Location", config[:azure_service_location])
        msg_pair("Public Ip Address", server.publicipaddress)
        msg_pair("Private Ip Address", server.ipaddress)
        msg_pair("SSH Port", server.sshport) unless server.sshport.nil?
        msg_pair("WinRM Port", server.winrmport) unless server.winrmport.nil?
        msg_pair("TCP Ports", server.tcpports) unless server.tcpports.nil? || server.tcpports.empty?
        msg_pair("UDP Ports", server.udpports) unless server.udpports.nil? || server.udpports.empty?
        msg_pair("Environment", config[:environment] || "_default")
        msg_pair("Runlist", config[:run_list]) unless config[:run_list].empty?
        puts "\n"
      end

      def pretty_key(key)
        key.to_s.tr("_", " ").gsub(/\w+/) { |w| w =~ /(ssh)|(aws)/i ? w.upcase : w.capitalize }
      end

      # validate command pre-requisites (cli options)
      # (config[:connection_password].length <= 6 && config[:connection_password].length >= 72)
      def validate_params!
        if config[:connection_password] && !config[:connection_password].length.between?(6, 72)
          ui.error("The supplied connection password must be 6-72 characters long and meet password complexity requirements")
          exit 1
        end

        if config[:azure_connect_to_existing_dns] && config[:azure_vm_name].nil?
          ui.error("Specify the VM name using --azure-vm-name option, since you are connecting to existing dns")
          exit 1
        end

        unless !!config[:azure_service_location] ^ !!config[:azure_affinity_group]
          ui.error("Specify either --azure-service-location or --azure-affinity-group")
          exit 1
        end

        unless service.valid_image?(config[:azure_source_image])
          ui.error("Image '#{config[:azure_source_image]}' is invalid")
          exit 1
        end

        # Validate join domain requirements.
        if config[:azure_domain_name] || config[:azure_domain_user]
          if config[:azure_domain_user].nil? || config[:azure_domain_passwd].nil?
            ui.error("Must specify both --azure-domain-user and --azure-domain-passwd.")
            exit 1
          end
        end

        if config[:winrm_ssl] && config[:thumbprint].nil? && config[:winrm_no_verify_cert].nil?
          ui.error("The SSL transport was specified without the --thumbprint option. Specify a thumbprint, or alternatively set the --winrm-no-verify-cert option to skip verification.")
          exit 1
        end

        if config[:extended_logs] && config[:connection_protocol] != "cloud-api"
          ui.error("--extended-logs option only works with --bootstrap-protocol cloud-api")
          exit 1
        end

        if config[:connection_protocol] == "cloud-api" && config[:azure_vm_name].nil? && config[:azure_dns_name].nil?
          ui.error("Specifying the DNS name using --azure-dns-name or VM name using --azure-vm-name option is required with --bootstrap-protocol cloud-api")
          exit 1
        end

        if config[:daemon]
          unless is_image_windows?
            raise ArgumentError, "The daemon option is only supported for Windows nodes."
          end

          unless  config[:connection_protocol] == "cloud-api"
            raise ArgumentError, "The --daemon option requires the use of --bootstrap-protocol cloud-api"
          end

          unless %w{none service task}.include?(config[:daemon].downcase)
            raise ArgumentError, "Invalid value for --daemon option. Valid values are 'none', 'service' and 'task'."
          end
        end
      end

      # validates keys
      def validate!(keys)
        errors = []
        keys.each do |k|
          if config[k].nil?
            errors << "You did not provide a valid '#{pretty_key(k)}' value. Please set knife[:#{k}] in your knife.rb or pass as an option."
          end
        end
        exit 1 if errors.each { |e| ui.error(e) }.any?
      end

      # validate ASM mandatory keys
      def validate_asm_keys!(*keys)
        mandatory_keys = %i{azure_subscription_id azure_mgmt_cert azure_api_host_name}
        keys.concat(mandatory_keys)

        unless config[:azure_mgmt_cert].nil?
          config[:azure_mgmt_cert] = File.read find_file(config[:azure_mgmt_cert])
        end

        if !config[:azure_publish_settings_file].nil?
          parse_publish_settings_file(config[:azure_publish_settings_file])
        elsif config[:azure_subscription_id].nil? && config[:azure_mgmt_cert].nil? && config[:azure_api_host_name].nil?
          azureprofile_file = get_azure_profile_file_path
          if File.exist?(File.expand_path(azureprofile_file))
            errors = parse_azure_profile(azureprofile_file, errors)
          end
        end
        validate!(keys)
      end

      def parse_publish_settings_file(filename)
        require "nokogiri" unless defined?(Nokogiri)
        require "base64" unless defined?(Base64)
        require "openssl" unless defined?(OpenSSL)
        require "uri" unless defined?(URI)
        begin
          doc = Nokogiri::XML(File.open(find_file(filename)))
          profile = doc.at_css("PublishProfile")
          subscription = profile.at_css("Subscription")
          # check given PublishSettings XML file format.Currently PublishSettings file have two different XML format
          if profile.attribute("SchemaVersion").nil?
            management_cert = OpenSSL::PKCS12.new(Base64.decode64(profile.attribute("ManagementCertificate").value))
            config[:azure_api_host_name] = URI(profile.attribute("Url").value).host
          elsif profile.attribute("SchemaVersion").value == "2.0"
            management_cert = OpenSSL::PKCS12.new(Base64.decode64(subscription.attribute("ManagementCertificate").value))
            config[:azure_api_host_name] = URI(subscription.attribute("ServiceManagementUrl").value).host
          else
            ui.error("Publish settings file Schema not supported - " + filename)
          end
          config[:azure_mgmt_cert] = management_cert.certificate.to_pem + management_cert.key.to_pem
          config[:azure_subscription_id] = doc.at_css("Subscription").attribute("Id").value
        rescue
          ui.error("Incorrect publish settings file - " + filename)
          exit 1
        end
      end

      def get_azure_profile_file_path
        "~/.azure/azureProfile.json"
      end

      def parse_azure_profile(filename, errors)
        require "openssl" unless defined?(OpenSSL)
        require "uri" unless defined?(URI)
        errors = [] if errors.nil?
        azure_profile = File.read(File.expand_path(filename))
        azure_profile = JSON.parse(azure_profile)
        default_subscription = get_default_subscription(azure_profile)
        if default_subscription.key?("id") && default_subscription.key?("managementCertificate") && default_subscription.key?("managementEndpointUrl")

          config[:azure_subscription_id] = default_subscription["id"]
          mgmt_key = OpenSSL::PKey::RSA.new(default_subscription["managementCertificate"]["key"]).to_pem
          mgmt_cert = OpenSSL::X509::Certificate.new(default_subscription["managementCertificate"]["cert"]).to_pem
          config[:azure_mgmt_cert] = mgmt_key + mgmt_cert
          config[:azure_api_host_name] = URI(default_subscription["managementEndpointUrl"]).host
        else
          errors << "Check if values set for 'id', 'managementCertificate', 'managementEndpointUrl' in -> #{filename} for 'defaultSubscription'. \n  OR "
        end
        errors
      end

      def get_default_subscription(azure_profile)
        first_subscription_as_default = nil
        azure_profile["subscriptions"].each do |subscription|
          if subscription["isDefault"]
            Chef::Log.info("Default subscription \'#{subscription["name"]}\'' selected.")
            return subscription
          end

          first_subscription_as_default ||= subscription
        end

        if first_subscription_as_default
          Chef::Log.info("First subscription \'#{subscription["name"]}\' selected as default.")
        else
          Chef::Log.info("No subscriptions found.")
          exit 1
        end
        first_subscription_as_default
      end

      def find_file(name)
        name = ::File.expand_path(name)
        config_dir = Chef::Knife.chef_config_dir
        if File.exist? name
          file = name
        elsif config_dir && File.exist?(File.join(config_dir, name))
          file = File.join(config_dir, name)
        elsif File.exist?(File.join(ENV["HOME"], ".chef", name))
          file = File.join(ENV["HOME"], ".chef", name)
        else
          ui.error("Unable to find file - " + name)
          exit 1
        end
        file
      end

      def fetch_deployment
        deployment_name = service.deployment_name(config[:azure_dns_name])
        service.deployment("hostedservices/#{config[:azure_dns_name]}/deployments/#{deployment_name}")
      end

      def fetch_role
        deployment = fetch_deployment

        if deployment.at_css("Deployment Name") != nil
          role_list_xml = deployment.css("RoleInstanceList RoleInstance")
          role_list_xml.each do |role|
            if role.at_css("RoleName").text == (config[:azure_vm_name] || @name_args[0])
              return role
            end
          end
        end
        nil
      end

      def fetch_extension(role)
        ext_list_xml = role.css("ResourceExtensionStatusList ResourceExtensionStatus")
        return nil if ext_list_xml.nil?

        ext_list_xml.each do |ext|
          if ext.at_css("HandlerName").text == "Chef.Bootstrap.WindowsAzure.LinuxChefClient" || ext.at_css("HandlerName").text == "Chef.Bootstrap.WindowsAzure.ChefClient"
            return ext
          end
        end
        nil
      end

      def fetch_substatus(extension)
        return nil if extension.at_css("ExtensionSettingStatus SubStatusList SubStatus").nil?

        substatus_list_xml = extension.css("ExtensionSettingStatus SubStatusList SubStatus")
        substatus_list_xml.each do |substatus|
          if substatus.at_css("Name").text == "Chef Client run logs"
            return substatus
          end
        end
        nil
      end

      def fetch_chef_client_logs(fetch_process_start_time, fetch_process_wait_timeout)
        ## fetch server details ##
        role = fetch_role
        if !role.nil?
          ## fetch Chef Extension details deployed on the server ##
          ext = fetch_extension(role)
          if !ext.nil?
            ## fetch substatus field which contains the chef-client run logs ##
            substatus = fetch_substatus(ext)
            if !substatus.nil?
              ## chef-client run logs becomes available ##
              name = substatus.at_css("Name").text
              status = substatus.at_css("Status").text
              message = substatus.at_css("Message").text

              ## printing the logs ##
              puts "\n\n******** Please find the chef-client run details below ********\n\n"
              print "----> chef-client run status: "
              case status
              when "Success"
                ## chef-client run succeeded ##
                color = :green
              when "Error"
                ## chef-client run failed ##
                color = :red
              when "Transitioning"
                ## chef-client run did not complete within maximum timeout of 30 minutes ##
                ## fetch whatever logs available under the chef-client.log file ##
                color = :yellow
              end
              puts "#{ui.color(status, color, :bold)}"
              puts "----> chef-client run logs: "
              puts "\n#{message}\n" ## message field of substatus contains the chef-client run logs ##
            else
              ## unavailability of the substatus field indicates that chef-client run is not completed yet on the server ##
              fetch_process_wait_time = ((Time.now - fetch_process_start_time) / 60).round
              if fetch_process_wait_time <= fetch_process_wait_timeout ## wait for maximum 30 minutes until chef-client run logs becomes available ##
                print "#{ui.color(".", :bold)}"
                sleep 30
                fetch_chef_client_logs(fetch_process_start_time, fetch_process_wait_timeout)
              else
                ## wait time exceeded maximum threshold set for the wait timeout ##
                ui.error "\nchef-client run logs could not be fetched since fetch process exceeded wait timeout of #{fetch_process_wait_timeout} minutes.\n"
              end
            end
          else
            ## Chef Extension could not be found ##
            ui.error("Unable to find Chef extension under role #{config[:azure_vm_name] || @name_args[0]}.")
          end
        else
          ## server could not be found ##
          ui.error("chef-client run logs could not be fetched since role #{config[:azure_vm_name] || @name_args[0]} could not be found.")
        end
      end
    end
  end
end
