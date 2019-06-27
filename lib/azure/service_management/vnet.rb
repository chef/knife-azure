#
# Author:: Jeff Mendoza (jeffmendoza@live.com)
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
  class Vnets
    def initialize(connection)
      @connection = connection
    end

    def load
      @vnets ||= begin
        @vnets = {}
        response = @connection.query_azure("networking/virtualnetwork")
        response.css("VirtualNetworkSite").each do |vnet|
          item = Vnet.new(@connection).parse(vnet)
          @vnets[item.name] = item
        end
        @vnets
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

    def create(params)
      ag = Vnet.new(@connection)
      ag.create(params)
    end
  end
end

module Azure
  class Vnet
    attr_accessor :name, :affinity_group, :state

    def initialize(connection)
      @connection = connection
    end

    def parse(image)
      @name = image.at_css("Name").content
      @affinity_group = image.at_css("AffinityGroup") ? image.at_css("AffinityGroup").content : ""
      @state = image.at_css("State").content
      self
    end

    def create(params)
      response = @connection.query_azure("networking/media")
      if response.at_css("Error") && response.at_css("Code").text == "ResourceNotFound"
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.NetworkConfiguration(
            "xmlns" => "http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration"
          ) do

            xml.VirtualNetworkConfiguration do
              xml.VirtualNetworkSites do
                xml.VirtualNetworkSite("name" => params[:azure_vnet_name], "AffinityGroup" => params[:azure_ag_name]) do
                  if params[:azure_address_space]
                    xml.AddressSpace do
                      xml.AddressPrefix params[:azure_address_space]
                    end
                  end
                  xml.Subnets do
                    xml.Subnet("name" => params[:azure_subnet_name]) do
                      xml.AddressPrefix params[:azure_address_space]
                    end
                  end
                end
              end
            end
          end
        end
        puts("Creating New Virtual Network: #{params[:azure_vnet_name]}...")
        response = builder
      else
        vnets = response.css("VirtualNetworkSite")
        vnet = nil
        vnets.each { |vn| vnet = vn if vn["name"] == params[:azure_vnet_name] }
        add = vnet.nil?
        vnet = Nokogiri::XML::Node.new("VirtualNetworkSite", response) if add
        vnet["name"] = params[:azure_vnet_name]
        vnet["AffinityGroup"] = params[:azure_ag_name]
        if add || !vnet.at_css("AddressSpace") ## create a new AddressSpace block in XML if VNet or AddressSpace block does not already exist
          addr_space = Nokogiri::XML::Node.new("AddressSpace", response)
        else ## retrieve object of existing AddressSpace if VNet or AddressSpace already exist
          addr_space = vnet.at_css("AddressSpace")
        end
        addr_prefix = Nokogiri::XML::Node.new("AddressPrefix", response)
        addr_prefix.content = params[:azure_address_space]
        if add || !vnet.at_css("Subnets") ## create a new Subnets block in XML if VNet or Subnets block does not already exist
          subnets = Nokogiri::XML::Node.new("Subnets", response)
        else ## retrieve object of existing Subnets if VNet or Subnets already exist
          subnets = vnet.at_css("Subnets")
        end
        saddr_prefix = Nokogiri::XML::Node.new("AddressPrefix", response)
        saddr_prefix.content = params[:azure_address_space]
        subnet = Nokogiri::XML::Node.new("Subnet", response)
        subnet["name"] = params[:azure_subnet_name]
        subnet.children = saddr_prefix
        subnets.children = subnet
        vnet.add_child(subnets) if add || !vnet.at_css("Subnets")
        addr_space.children = addr_prefix
        vnet.add_child(addr_space) if add || !vnet.at_css("AddressSpace")
        vnets.last.add_next_sibling(vnet) if add
        puts("Updating existing Virtual Network: #{params[:azure_vnet_name]}...")
      end
      @connection.query_azure("networking/media", "put", response.to_xml)
    end
  end
end
