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
  class Hosts
    include AzureUtility
    def initialize(connection)
      @connection = connection
    end

    # force_load should be true when there is something in local cache and we want to reload
    # first call is always load.
    def load(force_load = false)
      unless @hosted_services || force_load
        @hosted_services = begin
          hosted_services = {}
          responseXML = @connection.query_azure("hostedservices")
          servicesXML = responseXML.css("HostedServices HostedService")
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
      load.values
    end

    # first look up local cache if we have already loaded list.
    def exists?(name)
      return @hosted_services.key?(name) if @hosted_services

      exists_on_cloud?(name)
    end

    # Look up on cloud and not local cache
    def exists_on_cloud?(name)
      ret_val = @connection.query_azure("hostedservices/#{name}")
      error_code, error_message = error_from_response_xml(ret_val) if ret_val
      if ret_val.nil? || error_code.length > 0
        Chef::Log.debug("Unable to find hosted(cloud) service:" + error_code + " : " + error_message) if ret_val
        false
      else
        true
      end
    end

    # first look up local cache if we have already loaded list.
    def find(name)
      return @hosted_services[name] if @hosted_services && @hosted_services.key?(name)

      fetch_from_cloud(name)
    end

    # Look up hosted service on cloud and not local cache
    def fetch_from_cloud(name)
      ret_val = @connection.query_azure("hostedservices/#{name}")
      error_code, error_message = error_from_response_xml(ret_val) if ret_val
      if ret_val.nil? || error_code.length > 0
        Chef::Log.warn("Unable to find hosted(cloud) service:" + error_code + " : " + error_message) if ret_val
        nil
      else
        Host.new(@connection).parse(ret_val)
      end
    end

    def create(params)
      host = Host.new(@connection)
      host.create(params)
    end

    def delete(name)
      if exists?(name)
        servicecall = "hostedservices/" + name
        @connection.query_azure(servicecall, "delete")
      end
    end
  end
end

module Azure
  class Host
    include AzureUtility
    attr_accessor :connection, :name, :url, :label
    attr_accessor :dateCreated, :description, :location
    attr_accessor :dateModified, :status

    def initialize(connection)
      @connection = connection
      @deploys_loaded = false
      @deploys = {}
    end

    def parse(serviceXML)
      @name = xml_content(serviceXML, "ServiceName")
      @url = xml_content(serviceXML, "Url")
      @label = xml_content(serviceXML, "HostedServiceProperties Label")
      @dateCreated = xml_content(serviceXML, "HostedServiceProperties DateCreated")
      @description = xml_content(serviceXML, "HostedServiceProperties Description")
      @location = xml_content(serviceXML, "HostedServiceProperties Location")
      @dateModified = xml_content(serviceXML, "HostedServiceProperties DateLastModified")
      @status = xml_content(serviceXML, "HostedServiceProperties Status")
      self
    end

    def create(params)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.CreateHostedService("xmlns" => "http://schemas.microsoft.com/windowsazure") do
          xml.ServiceName params[:azure_dns_name]
          xml.Label Base64.encode64(params[:azure_dns_name])
          xml.Description "Explicitly created hosted service"
          unless params[:azure_service_location].nil?
            xml.Location params[:azure_service_location]
          end
          unless params[:azure_affinity_group].nil?
            xml.AffinityGroup params[:azure_affinity_group]
          end
        end
      end
      @connection.query_azure("hostedservices", "post", builder.to_xml)
    end

    def details
      response = @connection.query_azure("hostedservices/" + @name + "?embed-detail=true")
    end

    # Deployments within this hostedservice
    def add_deploy(deploy)
      @deploys[deploy.name] = deploy
    end

    def delete_role(role)
      deploys.each { |d| d.delete_role_if_present(role) }
    end

    def deploys
      # check if we have deploys loaded, else load.
      if (@deploys.length == 0) && !@deploys_loaded
        deploy = Deploy.new(@connection)
        deploy.retrieve(@name)
        @deploys[deploy.name] = deploy
        @deploys_loaded = true
      end
      @deploys.values
    end

    def roles
      roles = []
      deploys.each do |deploy|
        roles.concat(deploy.roles) if deploy.roles
      end
      roles
    end

    def find_role(role_name, deploy_name = nil)
      return @deploys[deploy_name].find_role(role_name) if deploy_name && deploys

      # else lookup all deploys within hostedservice
      deploys.each do |deploy|
        role = deploy.find_role(role_name)
        return role if role
      end
    end
  end
end
