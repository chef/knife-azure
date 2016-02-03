#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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
require 'azure/service_management/rest'
require 'azure/service_management/connection'

class Azure
  class ServiceManagement
    class ASMInterface < AzureInterface
      include AzureAPI

      attr_accessor :connection

      def initialize(params = {})
        @rest = Rest.new(params)
        @connection = Azure::ServiceManagement::Connection.new(@rest)
      end

      def list_images
        connection.images.all
      end

      def list_servers
        connection.roles.all
      end

      def find_server(params)
        server = connection.roles.find(name, params = { :azure_dns_name => locate_config_value(:azure_dns_name) })
        unless server
          ui.warn("Server #{name} does not exist")
          return
        end
      end

      def delete_server
      end
    end
  end
end

