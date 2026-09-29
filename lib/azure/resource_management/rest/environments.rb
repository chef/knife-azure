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

module Azure
  class ResourceManagement
    module Rest
      # ARM + Azure AD endpoints per cloud. Public cloud is the default; the
      # other clouds are provided for completeness and parity with the retired
      # Azure SDK, which supported them too.
      class Environments
        ENVIRONMENTS = {
          "AzureCloud" => {
            resource_manager_endpoint_url: "https://management.azure.com",
            active_directory_endpoint_url: "https://login.microsoftonline.com",
            token_audience: "https://management.azure.com/",
          },
          "AzureUSGovernment" => {
            resource_manager_endpoint_url: "https://management.usgovcloudapi.net",
            active_directory_endpoint_url: "https://login.microsoftonline.us",
            token_audience: "https://management.usgovcloudapi.net/",
          },
          "AzureChinaCloud" => {
            resource_manager_endpoint_url: "https://management.chinacloudapi.cn",
            active_directory_endpoint_url: "https://login.chinacloudapi.cn",
            token_audience: "https://management.chinacloudapi.cn/",
          },
          "AzureGermanCloud" => {
            resource_manager_endpoint_url: "https://management.microsoftazure.de",
            active_directory_endpoint_url: "https://login.microsoftonline.de",
            token_audience: "https://management.microsoftazure.de/",
          },
        }.freeze

        DEFAULT_ENVIRONMENT = "AzureCloud".freeze

        attr_reader :resource_manager_endpoint_url, :active_directory_endpoint_url, :token_audience

        def initialize(name = DEFAULT_ENVIRONMENT)
          config = ENVIRONMENTS[name] || ENVIRONMENTS[DEFAULT_ENVIRONMENT]
          @resource_manager_endpoint_url = config[:resource_manager_endpoint_url]
          @active_directory_endpoint_url = config[:active_directory_endpoint_url]
          @token_audience = config[:token_audience]
        end

        def self.default
          new(DEFAULT_ENVIRONMENT)
        end

        # Resolves a caller-supplied cloud name (e.g. "AzureUSGovernment") to an
        # Environments instance, falling back to the public cloud for a blank or
        # unknown value so a bad setting can never send credentials nowhere.
        def self.from_name(name)
          normalized = name.to_s.strip
          new(ENVIRONMENTS.key?(normalized) ? normalized : DEFAULT_ENVIRONMENT)
        end

        # Names of the clouds this client understands, exposed so callers can
        # validate a user-provided setting.
        def self.names
          ENVIRONMENTS.keys
        end
      end
    end
  end
end
