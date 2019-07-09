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

module Azure
  class StorageAccounts
    include AzureUtility
    def initialize(connection)
      @connection = connection
    end

    # force_load should be true when there is something in local cache and we want to reload
    # first call is always load.
    def load(force_load = false)
      unless @azure_storage_accounts || force_load
        @azure_storage_accounts = begin
          azure_storage_accounts = {}
          responseXML = @connection.query_azure("storageservices")
          servicesXML = responseXML.css("StorageServices StorageService")
          servicesXML.each do |serviceXML|
            storage = StorageAccount.new(@connection).parse(serviceXML)
            azure_storage_accounts[storage.name] = storage
          end
          azure_storage_accounts
        end
      end
      @azure_storage_accounts
    end

    def all
      load.values
    end

    # first look up local cache if we have already loaded list.
    def exists?(name)
      return @azure_storage_accounts.key?(name) if @azure_storage_accounts

      exists_on_cloud?(name)
    end

    # Look up on cloud and not local cache
    def exists_on_cloud?(name)
      ret_val = @connection.query_azure("storageservices/#{name}")
      error_code, error_message = error_from_response_xml(ret_val) if ret_val
      if ret_val.nil? || error_code.length > 0
        Chef::Log.warn "Unable to find storage account:" + error_message + " : " + error_message if ret_val
        false
      else
        true
      end
    end

    def create(params)
      storage = StorageAccount.new(@connection)
      storage.create(params)
    end

    def clear_unattached
      all.each do |storage|
        next unless storage.attached == false

        @connection.query_azure("storageaccounts/" + storage.name, "delete")
      end
    end

    def delete(name)
      if exists?(name)
        servicecall = "storageservices/" + name
        @connection.query_azure(servicecall, "delete")
      end
    end
  end
end

module Azure
  class StorageAccount
    include AzureUtility
    attr_accessor :name, :location
    attr_accessor :affinityGroup, :location, :georeplicationenabled
    def initialize(connection)
      @connection = connection
    end

    def parse(serviceXML)
      @name = xml_content(serviceXML, "ServiceName")
      @description = xml_content(serviceXML, "Description")
      @label = xml_content(serviceXML, "Label")
      @affinitygroup = xml_content(serviceXML, "AffinityGroup")
      @location = xml_content(serviceXML, "Location")
      @georeplicationenabled = xml_content(serviceXML, "GeoReplicationEnabled")
      @extendpropertyname = xml_content(serviceXML, "ExtendedProperties ExtendedProperty Name")
      @extendpropertyvalue = xml_content(serviceXML, "ExtendedProperties ExtendedProperty Value")
      self
    end

    def create(params)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.CreateStorageServiceInput("xmlns" => "http://schemas.microsoft.com/windowsazure") do
          xml.ServiceName params[:azure_storage_account]
          xml.Label Base64.encode64(params[:azure_storage_account])
          xml.Description params[:azure_storage_account_description] || "Explicitly created storage service"
          # Location defaults to 'West US'
          if params[:azure_affinity_group]
            xml.AffinityGroup params[:azure_affinity_group]
          else
            xml.Location params[:azure_service_location] || "West US"
          end
        end
      end
      @connection.query_azure("storageservices", "post", builder.to_xml)
    end
  end
end
