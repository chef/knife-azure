
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

require 'chef/knife'
require 'azure/resource_management/ARM_interface'
require 'mixlib/shellout'
require 'time'
require 'json'

class Chef
  class Knife
    module AzurermBase

      if Chef::Platform.windows?
        require 'azure/resource_management/windows_credentials'
        include Azure::ARM::WindowsCredentials
      end

      def self.included(includer)
        includer.class_eval do

          deps do
            require 'readline'
            require 'chef/json_compat'
          end

          option :azure_resource_group_name,
            :short => "-r RESOURCE_GROUP_NAME",
            :long => "--azure-resource-group-name RESOURCE_GROUP_NAME",
            :description => "The Resource Group name."

        end
      end

      def service
        details = authentication_details()
        details.update(:azure_subscription_id => locate_config_value(:azure_subscription_id))
        @service ||= begin
                      service = Azure::ResourceManagement::ARMInterface.new(details)
                    end
        @service.ui = ui
        @service
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]  || default_config[key]
      end

      # validates ARM mandatory keys
      def validate_arm_keys!(*keys)
        Chef::Log.warn('Azurerm subcommands are experimental and of alpha quality. Not suitable for production use. Please use ASM subcommands for production.')
        parse_publish_settings_file(locate_config_value(:azure_publish_settings_file)) if(locate_config_value(:azure_publish_settings_file) != nil)
        keys.push(:azure_subscription_id)

        if(locate_config_value(:azure_tenant_id).nil? || locate_config_value(:azure_client_id).nil? || locate_config_value(:azure_client_secret).nil?)
          validate_azure_login
        else
           keys.concat([:azure_tenant_id, :azure_client_id, :azure_client_secret])
        end

        errors = []
        keys.each do |k|
          if locate_config_value(k).nil?
            errors << "You did not provide a valid '#{pretty_key(k)}' value. Please set knife[:#{k}] in your knife.rb."
          end
        end
        if errors.each{|e| ui.error(e)}.any?
          exit 1
        end
      end

      def authentication_details
        if(!locate_config_value(:azure_tenant_id).nil? && !locate_config_value(:azure_client_id).nil? && !locate_config_value(:azure_client_secret).nil?)
          return {:azure_tenant_id => locate_config_value(:azure_tenant_id), :azure_client_id => locate_config_value(:azure_client_id), :azure_client_secret => locate_config_value(:azure_client_secret)}
        elsif Chef::Platform.windows?
          token_details = token_details_for_windows()
        else
          token_details = token_details_for_linux()
        end
        token_details = check_token_validity(token_details)
        return token_details
      end

      def token_details_for_linux
        home_dir = File.expand_path('~')
        file = File.read(home_dir + '/.azure/accessTokens.json')
        file = JSON.parse(file)
        token_details = {:tokentype => file[-1]["tokenType"], :user => file[-1]["userId"], :token => file[-1]["accessToken"], :clientid => file[-1]["_clientId"], :expiry_time => file[-1]["expiresOn"], :refreshtoken => file[-1]["refreshToken"]}
        return token_details
      end

      def is_token_valid?(token_details)
        time_difference = Time.parse(token_details[:expiry_time]) - Time.now.utc
        time_difference <= 0 ? false : true
      end

      def refresh_token
        begin
          ui.log("Authenticating...")
          Mixlib::ShellOut.new("azure vm show 'knifetest@resourcegroup' testvm", :timeout => 30).run_command
        rescue Mixlib::ShellOut::CommandTimeout
        rescue Exception
          raise "Token has expired. Please run 'azure login' command"
        end
        if Chef::Platform.windows?
          token_details = token_details_for_windows()
        else
          token_details = token_details_for_linux()
        end
        return token_details
      end

      def check_token_validity(token_details)
        if !is_token_valid?(token_details)
          token_details = refresh_token()
          if !is_token_valid?(token_details)
            raise "Token has expired. Please run 'azure login' command"
          end
        end
        return token_details
      end

      def validate_azure_login
        err_string = "Please run XPLAT's 'azure login' command OR specify azure_tenant_id, azure_subscription_id, azure_client_id, azure_client_secret in your knife.rb"
        if Chef::Platform.windows?
          # cmdkey command is used for accessing windows credential manager
          xplat_creds_cmd = Mixlib::ShellOut.new("cmdkey /list | findstr AzureXplatCli")
          result = xplat_creds_cmd.run_command
          if result.stdout.nil? || result.stdout.empty?
            raise err_string
          end
        else
          home_dir = File.expand_path('~')
          if !File.exists?(home_dir + "/.azure/accessTokens.json") || File.size?(home_dir + '/.azure/accessTokens.json') <= 2
            raise err_string
          end
        end
      end

      def parse_publish_settings_file(filename)
        require 'nokogiri'
        require 'base64'
        require 'openssl'
        require 'uri'
        begin
          doc = Nokogiri::XML(File.open(find_file(filename)))
          profile = doc.at_css("PublishProfile")
          subscription = profile.at_css("Subscription")
          #check given PublishSettings XML file format.Currently PublishSettings file have two different XML format
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
        rescue=> error
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
        elsif File.exist?(File.join(ENV['HOME'], '.chef', name))
          file = File.join(ENV['HOME'], '.chef', name)
        else
          ui.error('Unable to find file - ' + name)
          exit 1
        end
        file
      end

      def pretty_key(key)
        key.to_s.gsub(/_/, ' ').gsub(/\w+/){ |w| (w =~ /(ssh)|(aws)/i) ? w.upcase  : w.capitalize }
      end

      def is_image_windows?
        locate_config_value(:azure_image_reference_offer) =~ /WindowsServer.*/
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def msg_server_summary(server)
        puts "\n\n"
        if server.provisioningstate == 'Succeeded'
          Chef::Log.info("Server creation went successfull.")
          puts "\nServer Details are:\n"

          msg_pair('Server ID', server.id)
          msg_pair('Server Name', server.name)
          msg_pair('Server Public IP Address', server.publicipaddress)
          if is_image_windows?
            msg_pair('Server RDP Port', server.rdpport)
          else
            msg_pair('Server SSH Port', server.sshport)
          end
          msg_pair('Server Location', server.locationname)
          msg_pair('Server OS Type', server.ostype)
          msg_pair('Server Provisioning State', server.provisioningstate)
        else
          Chef::Log.info("Server Creation Failed.")
        end

        puts "\n\n"

        if server.resources.provisioning_state == 'Succeeded'
          Chef::Log.info("Server Extension creation went successfull.")
          puts "\nServer Extension Details are:\n"

          msg_pair('Server Extension ID', server.resources.id)
          msg_pair('Server Extension Name', server.resources.name)
          msg_pair('Server Extension Publisher', server.resources.publisher)
          msg_pair('Server Extension Type', server.resources.type)
          msg_pair('Server Extension Type Handler Version', server.resources.type_handler_version)
          msg_pair('Server Extension Provisioning State', server.resources.provisioning_state)
        else
          Chef::Log.info("Server Extension Creation Failed.")
        end
        puts "\n"
      end
    end
  end
end
