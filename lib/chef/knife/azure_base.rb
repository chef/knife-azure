
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
            :short => "-S ID",
            :long => "--azure-subscription-id ID",
            :description => "Your Azure subscription ID",
            :proc => Proc.new { |key| Chef::Config[:knife][:azure_subscription_id] = key }

          option :azure_mgmt_cert,
            :short => "-p FILENAME",
            :long => "--azure-mgmt-cert FILENAME",
            :description => "Your Azure PEM file name",
            :proc => Proc.new { |key| Chef::Config[:knife][:azure_mgmt_cert] = key }

          option :azure_host_name,
            :short => "-H HOSTNAME",
            :long => "--azure_host_name HOSTNAME",
            :description => "Your Azure host name",
            :proc => Proc.new { |key| Chef::Config[:knife][:azure_host_name] = key }

          option :verify_ssl_cert,
            :long => "--verify-ssl-cert",
            :description => "Verify SSL Certificates for communication over HTTPS",
            :boolean => true,
            :default => false
        end
      end

      def is_image_windows?
        images = connection.images
        target_image = images.all.select { |i| i.name == locate_config_value(:source_image) }
        return target_image[0].os == 'Windows'
      end
      def connection
        @connection ||= begin
                          connection = Azure::Connection.new(
                            :azure_subscription_id => locate_config_value(:azure_subscription_id),
                            :azure_mgmt_cert => locate_config_value(:azure_mgmt_cert),
                            :azure_host_name => locate_config_value(:azure_host_name),
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

      def validate!(keys=[:azure_subscription_id, :azure_mgmt_cert, :azure_host_name])
        errors = []

        keys.each do |k|
          pretty_key = k.to_s.gsub(/_/, ' ').gsub(/\w+/){ |w| (w =~ /(ssh)|(aws)/i) ? w.upcase  : w.capitalize }
          if Chef::Config[:knife][k].nil?
            errors << "You did not provide a valid '#{pretty_key}' value."
          end
        end

        if errors.each{|e| ui.error(e)}.any?
          exit 1
        end
      end

    end
  end
end
