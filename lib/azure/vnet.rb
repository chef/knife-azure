#
# Author:: Jeff Mendoza (jeffmendoza@live.com)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
  class Vnets
    def initialize(connection)
      @connection = connection
    end

    def load
      @vnets ||= begin
        @vnets = {}
        response = @connection.query_azure('networking/virtualnetwork')
        response.css('VirtualNetworkSite').each do |vnet|
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

class Azure
  class Vnet
    attr_accessor :name, :affinity_group, :state

    def initialize(connection)
      @connection = connection
    end

    def parse(image)
      @name = image.at_css('Name').content
      @affinity_group = image.at_css('AffinityGroup') ? image.at_css('AffinityGroup').content : ""
      @state = image.at_css('State').content
      self
    end

    def create(params)
      response = @connection.query_azure('networking/media')
      if response.at_css("Error")
        puts response.at_css("Error Message").content
      else
        vnets = response.css('VirtualNetworkSite')
        vnet = nil
        vnets.each { |vn| vnet = vn if vn['name'] == params[:azure_vnet_name] }
        add = vnet.nil?
        vnet = Nokogiri::XML::Node.new('VirtualNetworkSite', response) if add
        vnet['name'] = params[:azure_vnet_name]
        vnet['AffinityGroup'] = params[:azure_ag_name]
        addr_space = Nokogiri::XML::Node.new('AddressSpace', response)
        addr_prefix = Nokogiri::XML::Node.new('AddressPrefix', response)
        addr_prefix.content = params[:azure_address_space]
        addr_space.children = addr_prefix
        vnet.children = addr_space
        vnets.last.add_next_sibling(vnet) if add
        @connection.query_azure('networking/media', 'put', response.to_xml)
      end
    end
  end
end
