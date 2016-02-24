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

      def get_resource_client
        resource_client = ResourceManagementClient.new(@credentials)
        resource_client.subscription_id = @azure_subscription_id
        resource_client
      end

      def get_compute_client
        compute_client = ComputeManagementClient.new(@credentials)
        compute_client.subscription_id = @azure_subscription_id
        compute_client
      end

      def get_storage_client
        storage_client = StorageManagementClient.new(@credentials)
        storage_client.subscription_id = @azure_subscription_id
        storage_client
      end

      def get_network_client
        network_client = NetworkResourceProviderClient.new(@credentials)
        network_client.subscription_id = @azure_subscription_id
        network_client
      end

      def list_servers
        begin
          promise = get_compute_client.virtual_machines.list_all
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
          ui.error "#{error.class} and #{error.message}"
        end
      end

       def delete_server(resource_group_name, vm_name, custom_headers=nil)
        promise = compute_management_client.virtual_machines.get(resource_group_name, vm_name, expand =nil, custom_headers)
        if promise.value! && promise.value!.body.name == vm_name
          puts "\n"
          msg_pair(ui, 'VM Name', promise.value!.body.name)
          msg_pair(ui, 'VM Size', promise.value!.body.properties.hardware_profile.vm_size)
          msg_pair(ui, 'VM OS', promise.value!.body.properties.storage_profile.os_disk.os_type)
          puts "\n"

          begin
            ui.confirm('Do you really want to delete this server')
          rescue SystemExit   # Need to handle this as confirming with N/n raises SystemExit exception
            server = nil      # Cleanup is implicitly performed in other cloud plugins
            exit!
          end

          ui.info 'Deleting ......'

          promise = compute_management_client.virtual_machines.delete(resource_group_name, vm_name, custom_headers = nil)

          puts "\n"
          ui.warn "Deleted server #{vm_name}"
        else
          puts promise
          raise promise.reason.body
        end
      end
    end
  end
end

