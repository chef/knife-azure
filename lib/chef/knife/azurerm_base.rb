
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

class Chef
  class Knife
    module AzurermBase

      def self.included(includer)
        includer.class_eval do

          deps do
            require 'readline'
            require 'chef/json_compat'
          end

          option :azure_subscription_id,
            :short => "-S ID",
            :long => "--azure-subscription-id ID",
            :description => "Your Azure subscription ID",
            :proc => Proc.new { |key| Chef::Config[:knife][:azure_subscription_id] = key }

          option :azure_tenant_id,
            :short => "-T ID",
            :long => "--azure-tenant-id ID",
            :description => "Your Azure tenant ID",
            :proc => Proc.new { |key| Chef::Config[:knife][:azure_tenant_id] = key }

          option :azure_client_id,
            :short => "-C ID",
            :long => "--azure-client-id ID",
            :description => "Your Azure client ID",
            :proc => Proc.new { |key| Chef::Config[:knife][:azure_client_id] = key }

          option :azure_client_secret,
            :short => "-S SECRET",
            :long => "--azure-client-secret SECRET",
            :description => "Your Azure client secret",
            :proc => Proc.new { |key| Chef::Config[:knife][:azure_client_secret] = key }

          option :azure_resource_group_name,
            :short => "-r RESOURCE_GROUP_NAME",
            :long => "--azure-resource-group-name RESOURCE_GROUP_NAME",
            :description => "Required. The Resource Group name that acts as a
                            container and holds related resources for an
                            application in a group."

        end
      end

      def service
        @service ||= begin
                      service = Azure::ResourceManagement::ARMInterface.new(
                        :azure_subscription_id => locate_config_value(:azure_subscription_id),
                        :azure_tenant_id => locate_config_value(:azure_tenant_id),
                        :azure_client_id => locate_config_value(:azure_client_id),
                        :azure_client_secret => locate_config_value(:azure_client_secret)
                      )
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
        parse_publish_settings_file(locate_config_value(:azure_publish_settings_file)) if(locate_config_value(:azure_publish_settings_file) != nil)
        mandatory_keys = [:azure_tenant_id, :azure_subscription_id, :azure_client_id, :azure_client_secret]
        keys.concat(mandatory_keys)

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
