#
# Copyright:: Copyright (c) 2012-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "uri" unless defined?(URI)
require_relative "environments"
require_relative "errors"
require_relative "http"
require_relative "rest_object"

module Azure
  class ResourceManagement
    module Rest
      # One method per ARM operation used by knife-azure, replacing the four
      # retired azure_mgmt_* SDK clients. Responses are wrapped in RestObject so
      # callers keep using SDK-style dot notation.
      class ArmClient
        RESOURCES_API_VERSION = "2025-04-01".freeze
        COMPUTE_API_VERSION   = "2024-11-01".freeze
        NETWORK_API_VERSION   = "2025-07-01".freeze

        def initialize(subscription_id, http, environment = Environments.default)
          @subscription_id = subscription_id
          @http = http
          @environment = environment
        end

        # ----- Resource groups / deployments (Microsoft.Resources) -----

        def resource_group_exist?(resource_group_name)
          @http.head(rg_url(resource_group_name, RESOURCES_API_VERSION))
          true
        rescue OperationError => e
          return false if e.http_status == 404

          raise
        end

        def create_resource_group(resource_group_name, location)
          body = { "location" => location }
          response = @http.put(rg_url(resource_group_name, RESOURCES_API_VERSION), body)
          RestObject.wrap(response.body)
        end

        def delete_resource_group(resource_group_name)
          @http.request_and_poll(:delete, rg_url(resource_group_name, RESOURCES_API_VERSION))
          nil
        end

        def create_deployment(resource_group_name, deployment_name, deployment_body)
          url = deployment_url(resource_group_name, deployment_name)
          @http.request_and_poll(:put, url, deployment_body)
          response = @http.get(url)
          RestObject.wrap(response.body)
        end

        # ----- Virtual machines / extensions (Microsoft.Compute) -----

        def list_all_virtual_machines
          url = base_url("/providers/Microsoft.Compute/virtualMachines", COMPUTE_API_VERSION)
          @http.get_all(url).map { |vm| RestObject.wrap(vm) }
        end

        def list_virtual_machines(resource_group_name)
          url = base_url(
            "/resourceGroups/#{e(resource_group_name)}/providers/Microsoft.Compute/virtualMachines",
            COMPUTE_API_VERSION
          )
          @http.get_all(url).map { |vm| RestObject.wrap(vm) }
        end

        def get_virtual_machine(resource_group_name, vm_name)
          response = @http.get(vm_url(resource_group_name, vm_name))
          RestObject.wrap(response.body)
        end

        def get_availability_set(resource_group_name, availability_set_name)
          url = base_url(
            "/resourceGroups/#{e(resource_group_name)}/providers/Microsoft.Compute/availabilitySets/#{e(availability_set_name)}",
            COMPUTE_API_VERSION
          )
          response = @http.get(url)
          RestObject.wrap(response.body)
        end

        def delete_virtual_machine(resource_group_name, vm_name)
          @http.request_and_poll(:delete, vm_url(resource_group_name, vm_name))
          nil
        end

        def get_vm_extension(resource_group_name, vm_name, extension_name, expand: nil)
          url = vm_extension_url(resource_group_name, vm_name, extension_name)
          url += "&$expand=#{e(expand)}" if expand
          response = @http.get(url)
          RestObject.wrap(response.body)
        end

        def create_vm_extension(resource_group_name, vm_name, extension_name, extension_body)
          url = vm_extension_url(resource_group_name, vm_name, extension_name)
          # The async PUT resolves to an operation-status document, not the
          # extension itself, so GET the resource once polling completes.
          @http.request_and_poll(:put, url, extension_body)
          response = @http.get(url)
          RestObject.wrap(response.body)
        end

        def list_vm_extension_versions(location, publisher, type)
          path = "/providers/Microsoft.Compute/locations/#{e(location)}/publishers/#{e(publisher)}" \
                 "/artifacttypes/vmextension/types/#{e(type)}/versions"
          response = @http.get(base_url(path, COMPUTE_API_VERSION))
          Array(response.body).map { |v| RestObject.wrap(v) }
        end

        # ----- Network (Microsoft.Network) -----

        def get_network_interface(resource_group_name, name)
          response = @http.get(network_url(resource_group_name, "networkInterfaces", name))
          RestObject.wrap(response.body)
        end

        def get_public_ip_address(resource_group_name, name)
          response = @http.get(network_url(resource_group_name, "publicIPAddresses", name))
          RestObject.wrap(response.body)
        end

        def get_network_security_group(resource_group_name, name)
          response = @http.get(network_url(resource_group_name, "networkSecurityGroups", name))
          RestObject.wrap(response.body)
        end

        def get_virtual_network(resource_group_name, vnet_name)
          response = @http.get(network_url(resource_group_name, "virtualNetworks", vnet_name))
          RestObject.wrap(response.body)
        end

        def list_subnets(resource_group_name, vnet_name)
          path = "/resourceGroups/#{e(resource_group_name)}/providers/Microsoft.Network" \
                 "/virtualNetworks/#{e(vnet_name)}/subnets"
          url = base_url(path, NETWORK_API_VERSION)
          @http.get_all(url).map { |subnet| RestObject.wrap(subnet) }
        end

        private

        def base_url(path, api_version)
          "#{@environment.resource_manager_endpoint_url}/subscriptions/#{e(@subscription_id)}" \
            "#{path}?api-version=#{api_version}"
        end

        def rg_url(resource_group_name, api_version)
          base_url("/resourceGroups/#{e(resource_group_name)}", api_version)
        end

        def deployment_url(resource_group_name, deployment_name)
          base_url(
            "/resourceGroups/#{e(resource_group_name)}/providers/Microsoft.Resources/deployments/#{e(deployment_name)}",
            RESOURCES_API_VERSION
          )
        end

        def vm_url(resource_group_name, vm_name)
          base_url(
            "/resourceGroups/#{e(resource_group_name)}/providers/Microsoft.Compute/virtualMachines/#{e(vm_name)}",
            COMPUTE_API_VERSION
          )
        end

        def vm_extension_url(resource_group_name, vm_name, extension_name)
          base_url(
            "/resourceGroups/#{e(resource_group_name)}/providers/Microsoft.Compute/virtualMachines/" \
              "#{e(vm_name)}/extensions/#{e(extension_name)}",
            COMPUTE_API_VERSION
          )
        end

        def network_url(resource_group_name, resource_type, name)
          base_url(
            "/resourceGroups/#{e(resource_group_name)}/providers/Microsoft.Network/#{resource_type}/#{e(name)}",
            NETWORK_API_VERSION
          )
        end

        def e(value)
          URI.encode_www_form_component(value.to_s)
        end
      end
    end
  end
end
