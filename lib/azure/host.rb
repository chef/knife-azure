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

class Azure
  class Hosts
    def initialize(connection)
      @connection=connection
    end
    def all
      hosted_services = Array.new
      responseXML = @connection.query_azure('hostedservices')
      servicesXML = responseXML.css('HostedServices HostedService')
      servicesXML.each do |serviceXML|
        host = Host.new(@connection)
        hosted_services << host.parse(serviceXML)
      end
      hosted_services
    end
    def exists(name)
      hostExists = false
      self.all.each do |host|
        next unless host.name == name
        hostExists = true
      end
      hostExists
    end
    def create(params)
      host = Host.new(@connection)
      host.create(params)
    end
    def delete(name)
      if self.exists name
          servicecall = "hostedservices/" + name
        @connection.query_azure(servicecall, "delete") 
      end
    end
  end
end

class Azure
  class Host
    include AzureUtility
    attr_accessor :connection, :name, :url, :label
    attr_accessor :dateCreated, :description, :location
    attr_accessor :dateModified, :status
    def initialize(connection)
      @connection = connection
    end
    def parse(serviceXML)
      @name = xml_content(serviceXML, 'ServiceName')
      @url = xml_content(serviceXML, 'Url')
      @label = xml_content(serviceXML, 'HostedServiceProperties Label')
      @dateCreated = xml_content(serviceXML, 'HostedServiceProperties DateCreated')
      @description = xml_content(serviceXML, 'HostedServiceProperties Description')
      @location = xml_content(serviceXML, 'HostedServiceProperties Location')
      @dateModified = xml_content(serviceXML, 'HostedServiceProperties DateLastModified')
      @status = xml_content(serviceXML, 'HostedServiceProperties Status')
      self
    end
    def create(params)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.CreateHostedService('xmlns'=>'http://schemas.microsoft.com/windowsazure') {
          xml.ServiceName params[:azure_hosted_service_name]
          xml.Label Base64.encode64(params[:azure_hosted_service_name])
          xml.Description params[:azure_hosted_service_description] || 'Explicitly created hosted service'
          xml.Location params[:azure_service_location] || 'West US'
        }
      end
      @connection.query_azure("hostedservices", "post", builder.to_xml)
    end
    def details
      response = @connection.query_azure('hostedservices/' + @name + '?embed-detail=true')
    end
  end
end
