
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
        config[key] || Chef::Config[:knife][key]
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
    end
  end
end
