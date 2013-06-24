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

    # force_load should be true when there is something in local cache and we want to reload
    # first call is always load.
    def load(force_load = false)
      if not @hosted_services || force_load
        @hosted_services = begin
          hosted_services = Hash.new
          responseXML = @connection.query_azure('hostedservices')
          servicesXML = responseXML.css('HostedServices HostedService')
          servicesXML.each do |serviceXML|
            host = Host.new(@connection).parse(serviceXML)
            hosted_services[host.name] = host
          end
          hosted_services
        end
      end
      @hosted_services
    end

    def all
      self.load.values
    end

    # first look up local cache if we have already loaded list.
    def exists?(name)
      return @hosted_services.key?(name) if @hosted_services
      self.exists_on_cloud?(name)
    end

    # Look up on cloud and not local cache
    def exists_on_cloud?(name)
      ret_val = @connection.query_azure("hostedservices/#{name}")
      if ret_val.nil? || ret_val.css('Error Code').length > 0
        Chef::Log.warn 'Unable to find hosted(cloud) service:' + ret_val.at_css('Error Code').content + ' : ' + ret_val.at_css('Error Message').content if ret_val
        false
      else
        true
      end
    end

    def create(params)
      host = Host.new(@connection)
      host.create(params)
    end
    def delete(name)
      if self.exists?(name)
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
    attr_accessor :deploys

    def initialize(connection)
      @connection = connection
      @deploys = []
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
          xml.ServiceName params[:azure_dns_name]
          xml.Label Base64.encode64(params[:azure_dns_name])
          xml.Description 'Explicitly created hosted service'
          xml.Location params[:azure_service_location] || 'West US'
        }
      end
      @connection.query_azure("hostedservices", "post", builder.to_xml)
    end
    def details
      response = @connection.query_azure('hostedservices/' + @name + '?embed-detail=true')
    end

    # Deploys within this hostedservice
    def add_deploy(deploy)
      @deploys << deploy
    end
  end
end
