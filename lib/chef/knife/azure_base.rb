
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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
require File.expand_path('../../../azure/connection', __FILE__)

class Chef
  class Knife
    module AzureBase

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'readline'
            require 'chef/json_compat'
          end

          option :azure_subscription_id,
            :long => "--azure-subscription-id ID",
            :description => "Your Azure subscription ID",
            :proc => Proc.new { |key| Chef::Config[:knife][:azure_subscription_id] = key }

          option :azure_mgmt_cert,
            :long => "--azure-mgmt-cert FILENAME",
            :description => "Your Azure PEM file name",
            :proc => Proc.new { |key| Chef::Config[:knife][:azure_mgmt_cert] = key }

          option :azure_api_host_name,
            :short => "-H HOSTNAME",
            :long => "--azure-api-host-name HOSTNAME",
            :description => "Your Azure host name",
            :proc => Proc.new { |key| Chef::Config[:knife][:azure_api_host_name] = key }

          option :verify_ssl_cert,
            :long => "--verify-ssl-cert",
            :description => "Verify SSL Certificates for communication over HTTPS",
            :boolean => true,
            :default => false

          option :azure_publish_settings_file,
            :long => "--azure-publish-settings-file FILENAME",
            :description => "Your Azure Publish Settings File",
            :proc => Proc.new { |key| Chef::Config[:knife][:azure_publish_settings_file] = key }
        end
      end

      def is_image_windows?
        images = connection.images
        target_image = images.all.select { |i| i.name == locate_config_value(:azure_source_image) }
        unless target_image[0].nil?
          return target_image[0].os == 'Windows'
        else
          ui.error("Invalid image. Use the command \"knife azure image list\" to verify the image name")
          exit 1
        end
      end
      def connection
        @connection ||= begin
                          connection = Azure::Connection.new(
                            :azure_subscription_id => locate_config_value(:azure_subscription_id),
                            :azure_mgmt_cert => locate_config_value(:azure_mgmt_cert),
                            :azure_api_host_name => locate_config_value(:azure_api_host_name),
                            :verify_ssl_cert => locate_config_value(:verify_ssl_cert)
                          )
                        end
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def validate!(keys=[:azure_subscription_id, :azure_mgmt_cert, :azure_api_host_name])
        errors = []
        if(locate_config_value(:azure_mgmt_cert) != nil)
          config[:azure_mgmt_cert] = File.read find_file(locate_config_value(:azure_mgmt_cert))
        end
        if(locate_config_value(:azure_publish_settings_file) != nil)
          parse_publish_settings_file(locate_config_value(:azure_publish_settings_file))
        end
        keys.each do |k|
          pretty_key = k.to_s.gsub(/_/, ' ').gsub(/\w+/){ |w| (w =~ /(ssh)|(aws)/i) ? w.upcase  : w.capitalize }
          if locate_config_value(k).nil?
            errors << "You did not provide a valid '#{pretty_key}' value. Please set knife[:#{k}] in your knife.rb or pass as an option."
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
        rescue
          ui.error("Incorrect publish settings file - " + filename)
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

    end
  end
end
