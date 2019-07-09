#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
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

require "azure/service_management/image"
require "azure/service_management/role"
require "azure/service_management/deploy"
require "azure/service_management/host"
require "azure/service_management/loadbalancer"
require "azure/service_management/vnet"
require "azure/service_management/utility"
require "azure/service_management/ag"
require "azure/service_management/storageaccount"
require "azure/service_management/certificate"
require "azure/service_management/disk"

module Azure
  class ServiceManagement
    class Connection
      include AzureUtility
      attr_accessor :hosts, :rest, :images, :deploys, :roles,
        :disks, :storageaccounts, :certificates, :ags, :vnets, :lbs
      def initialize(rest)
        @images = Images.new(self)
        @roles = Roles.new(self)
        @deploys = Deploys.new(self)
        @hosts = Hosts.new(self)
        @rest = rest
        @lbs = Loadbalancer.new(self)
        @vnets = Vnets.new(self)
        @ags = AGs.new(self)
        @storageaccounts = StorageAccounts.new(self)
        @certificates = Certificates.new(self)
        @disks = Disks.new(self)
      end

      def query_azure(service_name,
        verb = "get",
        body = "",
        params = "",
        wait = true,
        services = true,
        content_type = nil)
        Chef::Log.info "calling " + verb + " " + service_name + (wait ? " synchronously" : " asynchronously")
        Chef::Log.debug body unless body == ""
        response = @rest.query_azure(service_name, verb, body, params, services, content_type)
        if response.code.to_i == 200
          ret_val = Nokogiri::XML response.body
        elsif !wait && response.code.to_i == 202
          Chef::Log.debug "Request accepted in asynchronous mode"
          ret_val = Nokogiri::XML response.body
        elsif response.code.to_i >= 201 && response.code.to_i <= 299
          ret_val = wait_for_completion
        else
          if response.body
            ret_val = Nokogiri::XML response.body
            Chef::Log.debug ret_val.to_xml
            error_code, error_message = error_from_response_xml(ret_val)
            Chef::Log.debug error_code + " : " + error_message if error_code.length > 0
          else
            Chef::Log.warn "http error: " + response.code
          end
        end
        ret_val
      end

      def wait_for_completion
        status = "InProgress"
        Chef::Log.info "Waiting while status returns InProgress"
        while status == "InProgress"
          response = @rest.query_for_completion
          ret_val = Nokogiri::XML response.body
          status = xml_content(ret_val, "Status")
          if status == "InProgress"
            print "."
            sleep(0.5)
          elsif status == "Succeeded"
            Chef::Log.debug "not InProgress : " + ret_val.to_xml
          else
            error_code, error_message = error_from_response_xml(ret_val)
            Chef::Log.debug status + error_code + " : " + error_message if error_code.length > 0
          end
        end
        ret_val
      end
    end
  end
end
