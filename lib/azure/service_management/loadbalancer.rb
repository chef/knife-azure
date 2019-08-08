#
# Author:: Aiman Alsari (aiman.alsari@gmail.com)
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
  class Loadbalancer
    include AzureUtility
    attr_accessor :name, :service, :subnet, :vip

    def initialize(connection)
      @connection = connection
    end

    def load
      @lbs ||= begin
        @lbs = {}
        @connection.deploys.all.each do |deploy|
          @lbs.merge!(deploy.loadbalancers)
        end
        @lbs
      end
    end

    def all
      load.values
    end

    def exists?(name)
      load.key?(name)
    end

    def find(name)
      load[name]
    end

    def parse(lbXML, hostedservicename)
      @name = xml_content(lbXML, "Name")
      ip_configXML = lbXML.css("FrontendIpConfiguration")
      @subnet = xml_content(ip_configXML, "SubnetName")
      @vip = xml_content(ip_configXML, "StaticVirtualNetworkIPAddress")
      @service = hostedservicename
      self
    end

    def create(params)
      if params[:azure_lb_static_vip] && !params[:azure_subnet_name]
        Chef::Log.fatal "Unable to create Loadbalancer, :azure_subnet_name needs to be set if :azure_lb_static_vip is set"
      end
      builder = Nokogiri::XML::Builder.new(encoding: "utf-8") do |xml|
        xml.LoadBalancer(xmlns: "http://schemas.microsoft.com/windowsazure") do
          xml.Name params[:azure_load_balancer]
          xml.FrontendIpConfiguration do
            xml.Type "Private"
            xml.SubnetName params[:azure_subnet_name] if params[:azure_subnet_name]
            xml.StaticVirtualNetworkIPAddress params[:azure_lb_static_vip] if params[:azure_lb_static_vip]
          end
        end
      end
      deploy_name = @connection.deploys.get_deploy_name_for_hostedservice(params[:azure_dns_name])
      servicecall = "hostedservices/#{params[:azure_dns_name]}/deployments/#{deploy_name}/loadbalancers"
      @connection.query_azure(servicecall, "post", builder.doc.to_xml)
    end
  end
end
