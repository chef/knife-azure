#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
#
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

require "chef/knife"
require "azure/resource_management/ARM_interface"
require "mixlib/shellout"
require "chef/mixin/shell_out"
require "time"
require "json"

class Chef
  class Knife
    module AzurermBase
      include Chef::Mixin::ShellOut

      ## azure-xplat-cli versio that introduced deprecation of Windows Credentials
      ## Manager (WCM) usage for authentication credentials storage purpose ##
      XPLAT_VERSION_WITH_WCM_DEPRECATED ||= "0.10.5".freeze

      if Chef::Platform.windows?
        require "azure/resource_management/windows_credentials"
        include Azure::ARM::WindowsCredentials
      end

      def self.included(includer)
        includer.class_eval do
          deps do
            require "readline"
            require "chef/json_compat"
          end

          option :azure_resource_group_name,
            short: "-r RESOURCE_GROUP_NAME",
            long: "--azure-resource-group-name RESOURCE_GROUP_NAME",
            description: "The Resource Group name."
        end
      end

      def service
        details = authentication_details
        details.update(azure_subscription_id: locate_config_value(:azure_subscription_id))
        @service ||= begin
                      service = Azure::ResourceManagement::ARMInterface.new(details)
                    end
        @service.ui = ui
        @service
      end

      def locate_config_value(key)
        key = key.to_sym
        if defined?(config_value) # Inherited by bootstrap
          config_value(key) || default_config[key]
        else
          config[key] || Chef::Config[:knife][key] || default_config[key]
        end
      end

      # validates ARM mandatory keys
      def validate_arm_keys!(*keys)
        parse_publish_settings_file(locate_config_value(:azure_publish_settings_file)) unless locate_config_value(:azure_publish_settings_file).nil?
        keys.push(:azure_subscription_id)

        if azure_cred?
          validate_azure_login
        else
          keys.concat(%i{azure_tenant_id azure_client_id azure_client_secret})
        end

        errors = []
        keys.each do |k|
          if locate_config_value(k).nil?
            errors << "You did not provide a valid '#{pretty_key(k)}' value. Please set knife[:#{k}] in your knife.rb."
          end
        end
        if errors.each { |e| ui.error(e) }.any?
          exit 1
        end
      end

      def authentication_details
        if is_azure_cred?
          return { azure_tenant_id: locate_config_value(:azure_tenant_id), azure_client_id: locate_config_value(:azure_client_id), azure_client_secret: locate_config_value(:azure_client_secret) }
        elsif Chef::Platform.windows?
          token_details = token_details_for_windows
        else
          token_details = token_details_for_linux
        end

        token_details = check_token_validity(token_details)
        token_details
      end

      def get_azure_cli_version
        if @azure_version != ""
          get_version = shell_out!("azure -v || az -v | grep azure-cli", { returns: [0] }).stdout
          @azure_version = get_version.gsub(/[^0-9.]/, "")
        end
        @azure_prefix = @azure_version.to_i < 2 ? "azure" : "az"
        @azure_version
      end

      def token_details_for_windows
        if is_old_xplat?
          token_details_from_WCM
        else
          is_WCM_env_var_set? ? token_details_from_WCM : token_details_from_accessToken_file
        end
      end

      def token_details_for_linux
        token_details_from_accessToken_file
      end

      def token_details_from_accessToken_file
        home_dir = File.expand_path("~")
        file = File.read(home_dir + "/.azure/accessTokens.json")
        file = JSON.parse(file)
        token_details = { tokentype: file[-1]["tokenType"], user: file[-1]["userId"], token: file[-1]["accessToken"], clientid: file[-1]["_clientId"], expiry_time: file[-1]["expiresOn"], refreshtoken: file[-1]["refreshToken"] }
        token_details
      end

      def is_token_valid?(token_details)
        time_difference = Time.parse(token_details[:expiry_time]) - Time.now.utc
        if time_difference <= 0
          return false
        elsif time_difference <= 600 # 600sec = 10min
          # This is required otherwise a long running command may fail inbetween if the token gets expired.
          raise "Token will expire within 10 minutes. Please run '#{@azure_prefix} login' command"
        else
          return true
        end
      end

      def refresh_token
        azure_authentication
        token_details = Chef::Platform.windows? ? token_details_for_windows : token_details_for_linux
      end

      def azure_authentication
        ui.log("Authenticating...")
        Mixlib::ShellOut.new("#{@azure_prefix} vm show 'knifetest@resourcegroup' testvm", timeout: 30).run_command
      rescue Mixlib::ShellOut::CommandTimeout
      rescue Exception
        raise_azure_status
      end

      def check_token_validity(token_details)
        unless is_token_valid?(token_details)
          token_details = refresh_token
          raise_azure_status unless is_token_valid?(token_details)
        end
        token_details
      end

      def validate_azure_login
        if Chef::Platform.windows? && (is_old_xplat? || is_WCM_env_var_set?)
          # cmdkey command is used for accessing windows credential manager
          xplat_creds_cmd = Mixlib::ShellOut.new("cmdkey /list | findstr AzureXplatCli")
          result = xplat_creds_cmd.run_command
          raise login_message if result.stdout.nil? || result.stdout.empty?
        else
          home_dir = File.expand_path("~")
          puts "File.exist? = #{File.exist?("a")}"
          if !File.exist?(home_dir + "/.azure/accessTokens.json") || File.size?(home_dir + "/.azure/accessTokens.json") <= 2
            raise login_message
          end
        end
      end

      def parse_publish_settings_file(filename)
        require "nokogiri"
        require "base64"
        require "openssl"
        require "uri"
        begin
          doc = Nokogiri::XML(File.open(find_file(filename)))
          profile = doc.at_css("PublishProfile")
          subscription = profile.at_css("Subscription")
          # check given PublishSettings XML file format.Currently PublishSettings file have two different XML format
          if profile.attribute("SchemaVersion").nil?
            management_cert = OpenSSL::PKCS12.new(Base64.decode64(profile.attribute("ManagementCertificate").value))
            Chef::Config[:knife][:azure_api_host_name] = URI(profile.attribute("Url").value).host
          elsif profile.attribute("SchemaVersion").value == "2.0"
            management_cert = OpenSSL::PKCS12.new(Base64.decode64(subscription.attribute("ManagementCertificate").value))
            Chef::Config[:knife][:azure_api_host_name] = URI(subscription.attribute("ServiceManagementUrl").value).host
          else
            ui.error("Publish settings file Schema not supported - " + filename)
          end
          Chef::Config[:knife][:azure_mgmt_cert] = management_cert.certificate.to_pem + management_cert.key.to_pem
          Chef::Config[:knife][:azure_subscription_id] = doc.at_css("Subscription").attribute("Id").value
        rescue => error
          puts "#{error.class} and #{error.message}"
          exit 1
        end
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

      def msg_server_summary(server)
        puts "\n\n"
        if server.provisioningstate == "Succeeded"
          Chef::Log.info("Server creation went successfull.")
          puts "\nServer Details are:\n"

          msg_pair("Server ID", server.id)
          msg_pair("Server Name", server.name)
          msg_pair("Server Public IP Address", server.publicipaddress)
          if is_image_windows?
            msg_pair("Server RDP Port", server.rdpport)
          else
            msg_pair("Server SSH Port", server.sshport)
          end
          msg_pair("Server Location", server.locationname)
          msg_pair("Server OS Type", server.ostype)
          msg_pair("Server Provisioning State", server.provisioningstate)
        else
          Chef::Log.info("Server Creation Failed.")
        end

        puts "\n\n"

        if server.resources.provisioning_state == "Succeeded"
          Chef::Log.info("Server Extension creation went successfull.")
          puts "\nServer Extension Details are:\n"

          msg_pair("Server Extension ID", server.resources.id)
          msg_pair("Server Extension Name", server.resources.name)
          msg_pair("Server Extension Publisher", server.resources.publisher)
          msg_pair("Server Extension Type", server.resources.type)
          msg_pair("Server Extension Type Handler Version", server.resources.type_handler_version)
          msg_pair("Server Extension Provisioning State", server.resources.provisioning_state)
        else
          Chef::Log.info("Server Extension Creation Failed.")
        end
        puts "\n"
      end

      def validate_params!
        if locate_config_value(:connection_user).nil?
          raise ArgumentError, "Please provide --connection-user option for authentication."
        end

        unless locate_config_value(:connection_password).nil? ^ locate_config_value(:ssh_public_key).nil?
          raise ArgumentError, "Please specify either --connection-password or --ssh-public-key option for authentication."
        end

        if locate_config_value(:azure_vnet_subnet_name) && !locate_config_value(:azure_vnet_name)
          raise ArgumentError, "When --azure-vnet-subnet-name is specified, the --azure-vnet-name must also be specified."
        end

        if locate_config_value(:azure_vnet_subnet_name) == "GatewaySubnet"
          raise ArgumentError, "GatewaySubnet cannot be used as the name for --azure-vnet-subnet-name option. GatewaySubnet can only be used for virtual network gateways."
        end

        if locate_config_value(:node_ssl_verify_mode) && !%w{none peer}.include?(locate_config_value(:node_ssl_verify_mode))
          raise ArgumentError, "Invalid value '#{locate_config_value(:node_ssl_verify_mode)}' for --node-ssl-verify-mode. Use Valid values i.e 'none', 'peer'."
        end

        if !is_image_windows?
          if (locate_config_value(:azure_vm_name).match /^(?=.*[a-zA-Z-])([a-zA-z0-9-]{1,64})$/).nil?
            raise ArgumentError, "VM name can only contain alphanumeric and hyphen(-) characters and maximun length cannot exceed 64 charachters."
          end
        elsif (locate_config_value(:azure_vm_name).match /^(?=.*[a-zA-Z-])([a-zA-z0-9-]{1,15})$/).nil?
          raise ArgumentError, "VM name can only contain alphanumeric and hyphen(-) characters and maximun length cannot exceed 15 charachters."
        end

        if locate_config_value(:server_count).to_i > 5
          raise ArgumentError, "Maximum allowed value of --server-count is 5."
        end

        if locate_config_value(:daemon)
          unless is_image_windows?
            raise ArgumentError, "The daemon option is only support for Windows nodes."
          end

          unless %w{none service task}.include?(locate_config_value(:daemon))
            raise ArgumentError, "Invalid value for --daemon option. Use valid daemon values i.e 'none', 'service' and 'task'."
          end
        end

        if locate_config_value(:azure_image_os_type)
          unless %w{ubuntu centos rhel debian windows}.include?(locate_config_value(:azure_image_os_type))
            raise ArgumentError, "Invalid value of --azure-image-os-type. Accepted values ubuntu|centos|rhel|debian|windows"
          end
        end

        config[:ohai_hints] = format_ohai_hints(locate_config_value(:ohai_hints))
        validate_ohai_hints unless locate_config_value(:ohai_hints).casecmp("default").zero?
      end

      private

      def msg_pair(label, value, color = :cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def pretty_key(key)
        key.to_s.tr("_", " ").gsub(/\w+/) { |w| (w =~ /(ssh)|(aws)/i) ? w.upcase : w.capitalize }
      end

      def is_image_windows?
        locate_config_value(:azure_image_reference_offer) =~ /WindowsServer.*/
      end

      def is_azure_cred?
        locate_config_value(:azure_tenant_id) && locate_config_value(:azure_client_id) && locate_config_value(:azure_client_secret)
      end

      def azure_cred?
        locate_config_value(:azure_tenant_id).nil? || locate_config_value(:azure_client_id).nil? || locate_config_value(:azure_client_secret).nil?
      end

      def is_old_xplat?
        return true unless @azure_version

        Gem::Version.new(@azure_version) < Gem::Version.new(XPLAT_VERSION_WITH_WCM_DEPRECATED)
      end

      def is_WCM_env_var_set?
        ENV["AZURE_USE_SECURE_TOKEN_STORAGE"].nil? ? false : true
      end

      def raise_azure_status
        raise "Token has expired. Please run '#{@azure_prefix} login' command"
      end

      def login_message
        ## Older versions of the Azure CLI on Windows stored credentials in a unique way
        ## in Windows Credentails Manager (WCM).
        ## Newer versions use the same pattern across platforms where credentials gets
        ## stored in ~/.azure/accessTokens.json file.
        "Please run XPLAT's '#{@azure_prefix} login' command OR specify azure_tenant_id, azure_subscription_id, azure_client_id, azure_client_secret in your knife.rb"
      end
    end
  end
end
