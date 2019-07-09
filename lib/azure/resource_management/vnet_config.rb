#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
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

require "ipaddress"

module Azure::ARM
  module VnetConfig

    ## lists subnets of only a specific virtual network address space ##
    def subnets_list_for_specific_address_space(address_prefix, subnets_list)
      list = []
      address_space = IPAddress(address_prefix)
      subnets_list.each do |sbn|
        subnet_address_prefix = IPAddress(sbn.address_prefix)

        ## check if the subnet belongs to this address space or not ##
        list << sbn if address_space.include? subnet_address_prefix
      end

      list
    end

    def get_vnet(resource_group_name, vnet_name)
      network_resource_client.virtual_networks.get(resource_group_name, vnet_name)
    rescue MsRestAzure::AzureOperationError => error
      if error.body
        err_json = JSON.parse(error.response.body)
        if err_json["error"]["code"] == "ResourceNotFound"
          return false
        else
          raise error
        end
      end
    end

    ## lists all subnets under a virtual network or lists subnets of only a particular address space ##
    def subnets_list(resource_group_name, vnet_name, address_prefix = nil)
      list = network_resource_client.subnets.list(resource_group_name, vnet_name)
      !address_prefix.nil? && !list.empty? ? subnets_list_for_specific_address_space(address_prefix, list) : list
    end

    ## single subnet body creation to be added in template ##
    def subnet(subnet_name, subnet_prefix)
      {
        "name" => subnet_name,
        "properties" => {
          "addressPrefix" => subnet_prefix,
        },
      }
    end

    ## return all the address prefixes under a virtual network ##
    def vnet_address_spaces(vnet)
      vnet.address_space.address_prefixes
    end

    ## return address prefix of a subnet ##
    def subnet_address_prefix(subnet)
      subnet.address_prefix
    end

    ## sort available networks pool in ascending order based on the network's
    ## IP address to allocate the network for the new subnet to be added in the
    ## existing virtual network ##
    def sort_available_networks(available_networks)
      available_networks.sort_by { |nwrk| nwrk.network.address.split(".").map(&:to_i) }
    end

    ## sort existing subnets in ascending order based on their cidr prefix or
    ## netmask to have subnets with larger networks on the top ##
    def sort_subnets_by_cidr_prefix(subnets)
      subnets.sort_by.with_index { |sbn, i| [subnet_address_prefix(sbn).split("/")[1].to_i, i] }
    end

    ## sort used networks pool in descending order based on the number of hosts
    ## it contains, this helps to keep larger networks on top thereby eliminating
    ## more number of entries in available_networks_pool at a faster pace ##
    def sort_used_networks_by_hosts_size(used_network)
      used_network.sort_by.with_index { |nwrk, i| [-nwrk.hosts.size, i] }
    end

    ## return the cidr prefix or netmask of the given subnet ##
    def subnet_cidr_prefix(subnet)
      subnet_address_prefix(subnet).split("/")[1].to_i
    end

    ## method to invoke respective sort methods for the network pools ##
    def sort_pools(available_networks_pool, used_networks_pool)
      [sort_available_networks(available_networks_pool), sort_used_networks_by_hosts_size(used_networks_pool)]
    end

    ## when a address space in an existing virtual network is not used at all
    ## then divide the space into the number of subnets based on the total
    ## number of hosts that network supports ##
    def divide_network(address_prefix)
      network_address = IPAddress(address_prefix)
      prefix = nil

      case network_address.count
      when 4097..65536
        prefix = "20"
      when 256..4096
        prefix = "24"
      end

      ## if the given network is small then do not divide it else divide using
      ## the prefix value calculated above ##
      prefix.nil? ? address_prefix : network_address.network.address.concat("/" + prefix)
    end

    ## check if the available_network is part of the subnet_network or vice-versa ##
    def in_use_network?(subnet_network, available_network)
      (subnet_network.include? available_network) ||
        (available_network.include? subnet_network)
    end

    ## calculate and return address_prefix for the new subnet to be added in the
    ## existing virtual network ##
    def new_subnet_address_prefix(vnet_address_prefix, subnets)
      if subnets.empty? ## no subnets exist in the given address space of the virtual network, so divide the network into smaller subnets (based on the network size) and allocate space for the new subnet to be added ##
        divide_network(vnet_address_prefix)
      else ## subnets exist in vnet, calculate new address_prefix for the new subnet based on the space taken by these existing subnets under the given address space of the virtual network ##
        vnet_network_address = IPAddress(vnet_address_prefix)
        subnets = sort_subnets_by_cidr_prefix(subnets)
        available_networks_pool = []
        used_networks_pool = []
        subnets.each do |subnet|
          ## in case the larger network is not divided into smaller subnets but
          ## divided into only 1 largest subnet of the complete network size ##
          if vnet_network_address.prefix == subnet_cidr_prefix(subnet)
            break
          end

          ## add all the possible subnets (calculated using the current subnet's
          ## cidr prefix value) into the available_networks_pool ##
          available_networks_pool.push(
            vnet_network_address.subnet(subnet_cidr_prefix(subnet))
          ).flatten!.uniq! { |nwrk| [ nwrk.network.address, nwrk.prefix ].join(":") }

          ## add current subnet into the used_networks_pool ##
          used_networks_pool.push(
            IPAddress(subnet_address_prefix(subnet))
          )

          ## sort both the network pools before trimming the available_networks_pool ##
          available_networks_pool, used_networks_pool = sort_pools(
            available_networks_pool, used_networks_pool
          )

          ## trim the available_networks_pool based on the networks already
          ## allocated to the existing subnets ##
          used_networks_pool.each do |subnet_network|
            available_networks_pool.delete_if do |available_network|
              in_use_network?(subnet_network, available_network)
            end
          end

          ## sort both the network pools after trimming the available_networks_pool ##
          available_networks_pool, used_networks_pool = sort_pools(
            available_networks_pool, used_networks_pool
          )
        end

        ## space available in the vnet_address_prefix network for the new subnet ##
        if !available_networks_pool.empty? && available_networks_pool.first.network?
          available_networks_pool.first.network.address.concat("/" + available_networks_pool.first.prefix.to_s)
        else ## space not available in the vnet_address_prefix network for the new subnet ##
          nil
        end
      end
    end

    ## add new subnet into the existing virtual network ##
    def add_subnet(subnet_name, vnet_config, subnets)
      new_subnet_prefix = nil
      vnet_address_prefix_count = 0
      vnet_address_space = vnet_config[:addressPrefixes]

      ## search for space in all the address prefixes of the virtual network ##
      while new_subnet_prefix.nil? && vnet_address_space.length > vnet_address_prefix_count
        new_subnet_prefix = new_subnet_address_prefix(
          vnet_address_space[vnet_address_prefix_count],
          subnets_list_for_specific_address_space(
            vnet_address_space[vnet_address_prefix_count], subnets
          )
        )
        vnet_address_prefix_count += 1
      end

      if new_subnet_prefix ## found space for new subnet ##
        vnet_config[:subnets].push(
          subnet(subnet_name, new_subnet_prefix)
        )
      else ## no space available in the virtual network for the new subnet ##
        raise "Unable to add subnet #{subnet_name} into the virtual network #{vnet_config[:virtualNetworkName]}, no address space available !!!"
      end

      vnet_config
    end

    ## virtual network configuration creation for the new vnet creation or to
    ## handle existing vnet ##
    def create_vnet_config(resource_group_name, vnet_name, vnet_subnet_name)
      raise ArgumentError, "GatewaySubnet cannot be used as the name for --azure-vnet-subnet-name option. GatewaySubnet can only be used for virtual network gateways." if vnet_subnet_name == "GatewaySubnet"

      vnet_config = {}
      subnets = nil
      flag = true
      ## check whether user passed or default named virtual network exist or not ##
      vnet = get_vnet(resource_group_name, vnet_name)
      vnet_config[:virtualNetworkName] = vnet_name
      if vnet ## handle resources in the existing virtual network ##
        vnet_config[:addressPrefixes] = vnet_address_spaces(vnet)
        vnet_config[:subnets] = []
        subnets = subnets_list(resource_group_name, vnet_name)
        if subnets
          subnets.each do |subnet|
            flag = false if subnet.name == vnet_subnet_name ## given subnet already exist in the virtual network ##
            ## preserve the existing subnet resources ##
            vnet_config[:subnets].push(
              subnet(subnet.name, subnet_address_prefix(subnet))
            )
          end
        end
      else ## create config for new vnet ##
        vnet_config[:addressPrefixes] = [ "10.0.0.0/16" ]
        vnet_config[:subnets] = []
        vnet_config[:subnets].push(
          subnet(vnet_subnet_name, "10.0.0.0/24")
        )
        flag = false
      end

      ## given subnet does not exist, so create new one in the virtual network ##
      vnet_config = add_subnet(vnet_subnet_name, vnet_config, subnets) if flag

      vnet_config
    end
  end
end
