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

require 'azure/azure_interface'
require "azure_mgmt_compute"

module Azure
  class ResourceManagement
    class ARMInterface < AzureInterface
      include Azure::ARM::Compute
      include Azure::ARM::Compute::Models

      attr_accessor :connection

      def initialize(params = {})
        token_provider = MsRestAzure::ApplicationTokenProvider.new(params[:azure_tenant_id], params[:azure_client_id], params[:azure_client_secret])
        @credentials = MsRest::TokenCredentials.new(token_provider)
        @azure_subscription_id = params[:azure_subscription_id]
      end

      def resource_management_client
        @resource_management_client ||= begin
          resource_client = ResourceManagementClient.new(@credentials)
          resource_client.subscription_id = @azure_subscription_id
          resource_client
        end
      end

      def compute_management_client
        @compute_management_client ||= begin
           compute_management_client = ComputeManagementClient.new(@credentials)
           compute_management_client.subscription_id = @azure_subscription_id
           compute_management_client
        end
      end

      def storage_management_client
        @storage_management_client ||= begin
          storage_client = StorageManagementClient.new(@credentials)
          storage_client.subscription_id = @azure_subscription_id
          storage_client
        end
      end

      def network_resource_client
        @network_resource_client ||= begin
          network_client = NetworkResourceProviderClient.new(@credentials)
          network_client.subscription_id = @azure_subscription_id
          network_client
        end
      end

      def list_servers
        begin
          promise = compute_management_client.virtual_machines.list_all
          result = promise.value!
          servers = result.body.value

          cols = ['VM Name', 'Location', 'Provisioning State', 'OS Type']
          rows =  []

          servers.each do |server|
            rows << server.name.to_s
            rows << server.location.to_s
            rows << begin
                             state = server.properties.provisioning_state.to_s.downcase
                             case state
                             when 'shutting-down','terminated','stopping','stopped'
                               ui.color(state, :red)
                             when 'pending'
                               ui.color(state, :yellow)
                             else
                               ui.color('ready', :green)
                             end
                           end
            rows << server.properties.storage_profile.os_disk.os_type.to_s
          end
          display_list(ui, cols, rows)
        rescue => error
          puts "#{error.class} and #{error.message}"
        end
      end

      def show_server(name, resource_group)
        begin 
          promise = compute_management_client.virtual_machines.get(resource_group, name)
          result = promise.value!
          
          unless result.nil?
            server = result.body
            
            details = Array.new
            details << ui.color('Server Name', :bold, :cyan)
            details << server.name

            details << ui.color('Size', :bold, :cyan)
            details << server.properties.hardware_profile.vm_size

            details << ui.color('Provisioning State', :bold, :cyan)
            details << server.properties.provisioning_state

            details << ui.color('Location', :bold, :cyan)
            details << server.location

            details << ui.color('Publisher', :bold, :cyan)
            details << server.properties.storage_profile.image_reference.publisher

            details << ui.color('Offer', :bold, :cyan)
            details << server.properties.storage_profile.image_reference.offer

            details << ui.color('Sku', :bold, :cyan)
            details << server.properties.storage_profile.image_reference.sku

            details << ui.color('Version', :bold, :cyan)
            details << server.properties.storage_profile.image_reference.version

            details << ui.color('OS Type', :bold, :cyan)
            details << server.properties.storage_profile.os_disk.os_type
      
            puts ui.list(details, :columns_across, 2)
            
         else
           puts "There is no server with name #{name} or resource_group #{resource_group}. Please provide correct details."
         end  
       
        rescue => error
          puts "#{error.class} and #{error.message}"
        end

      end 
     
    end
  end
end

