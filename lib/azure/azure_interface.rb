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

require "azure/custom_errors"
require "azure/helpers"

module Azure
  class AzureInterface
    include CustomErrors
    include Helpers

    attr_accessor :ui

    def initialize(options = {}); end

    def create_server(params = {})
      AzureInterface.api_not_implemented(self)
    end

    def list_servers
      AzureInterface.api_not_implemented(self)
    end

    def delete_server(server_name)
      AzureInterface.api_not_implemented(self)
    end

    def list_images
      AzureInterface.api_not_implemented(self)
    end

    def show_server(server_name, resource_group = "")
      AzureInterface.api_not_implemented(self)
    end

    def create_vnet(params = {})
      AzureInterface.api_not_implemented(self)
    end

    def list_vnets
      AzureInterface.api_not_implemented(self)
    end

    def list_internal_lb
      AzureInterface.api_not_implemented(self)
    end

    def create_internal_lb(params = {})
      AzureInterface.api_not_implemented(self)
    end

    def list_affinity_groups
      AzureInterface.api_not_implemented(self)
    end

    def create_affinity_group(params = {})
      AzureInterface.api_not_implemented(self)
    end

    def find_server(server_name)
      AzureInterface.api_not_implemented(self)
    end
  end
end
