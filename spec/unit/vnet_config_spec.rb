#
# Author:: Aliasgar Batterywala (<aliasgar.batterywala@clogeny.com>)
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

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/../unit/query_azure_mock")

describe Azure::ARM::VnetConfig do
  include QueryAzureMock
  module Azure
    module ARM
      class DummyClass < Azure::ResourceManagement::ARMInterface
        include Azure::ARM::VnetConfig
      end
    end
  end

  before do
    stub_resource_groups
    @dummy_class = Azure::ARM::DummyClass.new
  end

  def subnet(resource_group_name, vnet_name, subnet_index = nil)
    subnets_list = stub_subnets_list_response(resource_group_name, vnet_name)

    subnet_index.nil? ? subnets_list : subnets_list[subnet_index]
  end

  def used_networks(subnets)
    used_networks_pool = []
    subnets.each do |subnet|
      used_networks_pool.push(IPAddress(subnet.address_prefix))
    end

    used_networks_pool
  end

  describe "subnets_list_for_specific_address_space" do
    context "subnets exist in the given address_prefix of the virtual network" do
      context "example-1" do
        before do
          resource_group_name = "rgrp-2"
          vnet_name = "vnet-2"
          @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
          @subnets_address_prefix = [ subnet(resource_group_name, vnet_name, 0),
            subnet(resource_group_name, vnet_name, 2),
          ]
        end

        it "returns the list of subnets which belongs to the given address_prefix of the virtual network" do
          response = @dummy_class.subnets_list_for_specific_address_space("10.2.0.0/16", @subnets)
          expect(response.class).to be == Array
          expect(response).to be == @subnets_address_prefix
        end
      end

      context "example-2" do
        before do
          resource_group_name = "rgrp-1"
          vnet_name = "vnet-1"
          @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
          @subnets_address_prefix = [ subnet(resource_group_name, vnet_name, 0),
            subnet(resource_group_name, vnet_name, 1),
          ]
        end

        it "returns the list of subnets which belongs to the given address_prefix of the virtual network" do
          response = @dummy_class.subnets_list_for_specific_address_space("10.1.0.0/16", @subnets)
          expect(response.class).to be == Array
          expect(response).to be == @subnets_address_prefix
        end
      end
    end

    context "no subnets exist in the given address_prefix of the virtual network - example1" do
      context "example-1" do
        before do
          resource_group_name = "rgrp-3"
          vnet_name = "vnet-4"
          @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
          @subnets_address_prefix = []
        end

        it "returns the empty list of subnets" do
          response = @dummy_class.subnets_list_for_specific_address_space("10.15.0.0/20", @subnets)
          expect(response.class).to be == Array
          expect(response).to be == @subnets_address_prefix
        end
      end

      context "example-2" do
        before do
          resource_group_name = "rgrp-2"
          vnet_name = "vnet-3"
          @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
        end

        it "returns the empty list of subnets" do
          response = @dummy_class.subnets_list_for_specific_address_space("141.154.163.0/26", @subnets)
          expect(response.class).to be == Array
          expect(response.empty?).to be == true
        end
      end
    end
  end

  describe "get_vnet" do
    context "given vnet exist under the given resource group" do
      before do
        @resource_group_name = "rgrp-2"
        @vnet_name = "vnet-2"
        allow(@dummy_class).to receive(:network_resource_client).and_return(
          stub_network_resource_client(nil, @resource_group_name, @vnet_name)
        )
      end

      it "returns vnet object" do
        response = @dummy_class.get_vnet(@resource_group_name, @vnet_name)
        expect(response.address_space.address_prefixes).to be == [ "10.2.0.0/16", "192.168.172.0/24", "16.2.0.0/24" ]
        expect(response.subnets.class).to be == Array
        expect(response.subnets.length).to be == 3
      end
    end

    context "given vnet does not exist under the given resource group" do
      before do
        @resource_group_name = "rgrp-2"
        @vnet_name = "vnet-22"
        request = {}
        response = OpenStruct.new({
          "body" => '{"error": {"code": "ResourceNotFound"}}',
        })
        body = "MsRestAzure::AzureOperationError"
        error = MsRestAzure::AzureOperationError.new(request, response, body)
        network_resource_client = double("NetworkResourceClient",
          virtual_networks: double)
        allow(network_resource_client.virtual_networks).to receive(
          :get
        ).and_raise(error)
        allow(@dummy_class).to receive(:network_resource_client).and_return(
          network_resource_client
        )
      end

      it "returns false" do
        response = @dummy_class.get_vnet(@resource_group_name, @vnet_name)
        expect(response).to be == false
      end
    end

    context "vnet get api call raises some unknown exception" do
      before do
        @resource_group_name = "rgrp-2"
        @vnet_name = "vnet-22"
        request = {}
        response = OpenStruct.new({
          "body" => '{"error": {"code": "SomeProblemOccurred"}}',
        })
        body = "MsRestAzure::AzureOperationError"
        @error = MsRestAzure::AzureOperationError.new(request, response, body)
        network_resource_client = double("NetworkResourceClient",
          virtual_networks: double)
        allow(network_resource_client.virtual_networks).to receive(
          :get
        ).and_raise(@error)
        allow(@dummy_class).to receive(:network_resource_client).and_return(
          network_resource_client
        )
      end

      it "raises error" do
        expect do
          @dummy_class.get_vnet(@resource_group_name, @vnet_name)
        end.to raise_error(@error)
      end
    end
  end

  describe "subnets_list" do
    context "when address_prefix is not passed" do
      context "example-1" do
        before do
          @resource_group_name = "rgrp-2"
          @vnet_name = "vnet-2"
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            stub_network_resource_client(nil, @resource_group_name, @vnet_name)
          )
          @subnets_vnet_name = [ subnet(@resource_group_name, @vnet_name) ].flatten!
        end

        it "returns a list of all the subnets present under the given virtual network" do
          response = @dummy_class.subnets_list(@resource_group_name, @vnet_name)
          expect(response.class).to be == Array
          expect(response).to be == @subnets_vnet_name
        end
      end

      context "example-2" do
        before do
          @resource_group_name = "rgrp-2"
          @vnet_name = "vnet-3"
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            stub_network_resource_client(nil, @resource_group_name, @vnet_name)
          )
          @subnets_vnet_name = [ subnet(@resource_group_name, @vnet_name) ].flatten!
        end

        it "returns a list of all the subnets present under the given virtual network" do
          response = @dummy_class.subnets_list(@resource_group_name, @vnet_name)
          expect(response.class).to be == Array
          expect(response).to be == @subnets_vnet_name
        end
      end
    end

    context "when address_prefix is passed" do
      context "example-1" do
        before do
          @resource_group_name = "rgrp-2"
          @vnet_name = "vnet-2"
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            stub_network_resource_client(nil, @resource_group_name, @vnet_name)
          )
          @subnets_address_prefix = [ subnet(@resource_group_name, @vnet_name, 1) ]
        end

        it "returns a list of all the subnets present under the given virtual network" do
          response = @dummy_class.subnets_list(@resource_group_name, @vnet_name, "192.168.172.0/24")
          expect(response.class).to be == Array
          expect(response).to be == @subnets_address_prefix
        end
      end

      context "example-2" do
        before do
          @resource_group_name = "rgrp-3"
          @vnet_name = "vnet-5"
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            stub_network_resource_client(nil, @resource_group_name, @vnet_name)
          )
          @subnets_address_prefix = [ subnet(@resource_group_name, @vnet_name, 0),
            subnet(@resource_group_name, @vnet_name, 1),
            subnet(@resource_group_name, @vnet_name, 3),
          ]
        end

        it "returns a list of all the subnets present under the given virtual network" do
          response = @dummy_class.subnets_list(@resource_group_name, @vnet_name, "69.182.8.0/21")
          expect(response.class).to be == Array
          expect(response).to be == @subnets_address_prefix
        end
      end
    end
  end

  describe "subnet" do
    before do
      @subnet = {
        "name" => "my_sbn",
        "properties" => {
          "addressPrefix" => "10.20.30.40/20",
        },
      }
    end

    it "returns the hash for subnet" do
      response = @dummy_class.subnet("my_sbn", "10.20.30.40/20")
      expect(response.class).to be == Hash
      expect(response).to be == @subnet
    end
  end

  describe "vnet_address_spaces" do
    context "example-1" do
      before do
        resource_group_name = "rgrp-1"
        vnet_name = "vnet-1"
        @vnet = @resource_groups[0][resource_group_name]["vnets"][0][vnet_name]
        @address_prefixes = [ "10.1.0.0/16" ]
      end

      it "returns address_prefixes for the given virtual network existing under the given resource group" do
        response = @dummy_class.vnet_address_spaces(@vnet)
        expect(response.class).to be == Array
        expect(response).to be == @address_prefixes
      end
    end

    context "example-2" do
      before do
        resource_group_name = "rgrp-2"
        vnet_name = "vnet-2"
        @vnet = @resource_groups[1][resource_group_name]["vnets"][0][vnet_name]
        @address_prefixes = [ "10.2.0.0/16", "192.168.172.0/24", "16.2.0.0/24" ]
      end

      it "returns address_prefixes for the given virtual network existing under the given resource group" do
        response = @dummy_class.vnet_address_spaces(@vnet)
        expect(response.class).to be == Array
        expect(response).to be == @address_prefixes
      end
    end
  end

  describe "subnet_address_prefix" do
    context "example-1" do
      before do
        resource_group_name = "rgrp-2"
        vnet_name = "vnet-2"
        @subnet = subnet(resource_group_name, vnet_name, 1)
      end

      it "returns the address_prefix of the subnet present under the given resource_group and vnet_name at the 1st index" do
        response = @dummy_class.subnet_address_prefix(@subnet)
        expect(response.class).to be == String
        expect(response).to be == "192.168.172.0/25"
      end
    end

    context "example-2" do
      before do
        resource_group_name = "rgrp-3"
        vnet_name = "vnet-5"
        @subnet = subnet(resource_group_name, vnet_name, 4)
      end

      it "returns the address_prefix of the subnet present under the given resource_group and vnet_name at the 4th index" do
        response = @dummy_class.subnet_address_prefix(@subnet)
        expect(response.class).to be == String
        expect(response).to be == "12.3.19.128/25"
      end
    end
  end

  describe "sort_available_networks" do
    context "example-1" do
      before do
        @available_networks = [ IPAddress("10.16.48.0/20"),
          IPAddress("10.16.32.0/24"),
          IPAddress("12.23.19.0/24"),
          IPAddress("221.17.234.0/29"),
          IPAddress("133.78.152.0/25"),
          IPAddress("11.13.48.0/20"),
        ]
      end

      it "sorts the given pool of available_networks in ascending order of the network's address" do
        response = @dummy_class.sort_available_networks(@available_networks)
        expect("#{response[0].network.address}/#{response[0].prefix}").to be == "10.16.32.0/24"
        expect("#{response[1].network.address}/#{response[1].prefix}").to be == "10.16.48.0/20"
        expect("#{response[2].network.address}/#{response[2].prefix}").to be == "11.13.48.0/20"
        expect("#{response[3].network.address}/#{response[3].prefix}").to be == "12.23.19.0/24"
        expect("#{response[4].network.address}/#{response[4].prefix}").to be == "133.78.152.0/25"
        expect("#{response[5].network.address}/#{response[5].prefix}").to be == "221.17.234.0/29"
      end
    end

    context "example-2" do
      before do
        @available_networks = [ IPAddress("159.10.0.0/16"),
          IPAddress("28.65.42.0/24"),
          IPAddress("165.98.0.0/20"),
          IPAddress("192.168.172.0/24"),
          IPAddress("31.66.12.128/25"),
          IPAddress("10.9.0.0/16"),
        ]
      end

      it "sorts the given pool of available_networks in ascending order of the network's address" do
        response = @dummy_class.sort_available_networks(@available_networks)
        expect("#{response[0].network.address}/#{response[0].prefix}").to be == "10.9.0.0/16"
        expect("#{response[1].network.address}/#{response[1].prefix}").to be == "28.65.42.0/24"
        expect("#{response[2].network.address}/#{response[2].prefix}").to be == "31.66.12.128/25"
        expect("#{response[3].network.address}/#{response[3].prefix}").to be == "159.10.0.0/16"
        expect("#{response[4].network.address}/#{response[4].prefix}").to be == "165.98.0.0/20"
        expect("#{response[5].network.address}/#{response[5].prefix}").to be == "192.168.172.0/24"
      end
    end
  end

  describe "sort_subnets_by_cidr_prefix" do
    context "example-1" do
      before do
        resource_group_name = "rgrp-2"
        vnet_name = "vnet-2"
        @subnets = stub_subnets_list_response(resource_group_name, vnet_name)

        resource_group_name = "rgrp-1"
        vnet_name = "vnet-1"
        @subnets.push(stub_subnets_list_response(
          resource_group_name, vnet_name
        )).flatten!
      end

      it "returns the sorted list of subnets in ascending order of their cidr prefix" do
        response = @dummy_class.sort_subnets_by_cidr_prefix(@subnets)
        expect(response[0].address_prefix).to be == "10.2.0.0/20"
        expect(response[1].address_prefix).to be == "10.1.48.0/20"
        expect(response[2].address_prefix).to be == "10.1.0.0/24"
        expect(response[3].address_prefix).to be == "192.168.172.0/25"
        expect(response[4].address_prefix).to be == "10.2.16.0/28"
      end
    end

    context "example-2" do
      before do
        resource_group_name = "rgrp-3"
        vnet_name = "vnet-5"
        @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
      end

      it "returns the sorted list of subnets in ascending order of their cidr prefix" do
        response = @dummy_class.sort_subnets_by_cidr_prefix(@subnets)
        expect(response[0].address_prefix).to be == "69.182.9.0/24"
        expect(response[1].address_prefix).to be == "69.182.11.0/24"
        expect(response[2].address_prefix).to be == "69.182.14.0/24"
        expect(response[3].address_prefix).to be == "12.3.19.0/25"
        expect(response[4].address_prefix).to be == "12.3.19.128/25"
      end
    end
  end

  describe "sort_used_networks_by_hosts_size" do
    context "example-1" do
      before do
        resource_group_name = "rgrp-2"
        vnet_name = "vnet-2"
        subnets = stub_subnets_list_response(resource_group_name, vnet_name)

        resource_group_name = "rgrp-1"
        vnet_name = "vnet-1"
        subnets.push(stub_subnets_list_response(
          resource_group_name, vnet_name
        )).flatten!

        @used_networks_pool = used_networks(subnets)
      end

      it "returns the list of used_networks sorted in descending order of their hosts size" do
        response = @dummy_class.sort_used_networks_by_hosts_size(@used_networks_pool)
        expect(response[0].network.address.concat("/" + response[0].prefix.to_s)).to be == "10.2.0.0/20"
        expect(response[1].network.address.concat("/" + response[1].prefix.to_s)).to be == "10.1.48.0/20"
        expect(response[2].network.address.concat("/" + response[2].prefix.to_s)).to be == "10.1.0.0/24"
        expect(response[3].network.address.concat("/" + response[3].prefix.to_s)).to be == "192.168.172.0/25"
        expect(response[4].network.address.concat("/" + response[4].prefix.to_s)).to be == "10.2.16.0/28"
      end
    end

    context "example-2" do
      before do
        resource_group_name = "rgrp-3"
        vnet_name = "vnet-4"
        subnets = stub_subnets_list_response(resource_group_name, vnet_name)

        resource_group_name = "rgrp-3"
        vnet_name = "vnet-5"
        subnets.push(stub_subnets_list_response(
          resource_group_name, vnet_name
        )).flatten!

        @used_networks_pool = used_networks(subnets)
      end

      it "returns the list of used_networks sorted in descending order of their hosts size", if: (RUBY_VERSION.to_f <= 2.1) do
        response = @dummy_class.sort_used_networks_by_hosts_size(@used_networks_pool)
        expect(response[0].network.address.concat("/" + response[0].prefix.to_s)).to be == "69.182.14.0/24"
        expect(response[1].network.address.concat("/" + response[1].prefix.to_s)).to be == "69.182.9.0/24"
        expect(response[2].network.address.concat("/" + response[2].prefix.to_s)).to be == "69.182.11.0/24"
        expect(response[3].network.address.concat("/" + response[3].prefix.to_s)).to be == "12.3.19.128/25"
        expect(response[4].network.address.concat("/" + response[4].prefix.to_s)).to be == "12.3.19.0/25"
        expect(response[5].network.address.concat("/" + response[5].prefix.to_s)).to be == "40.23.19.0/29"
      end

      it "returns the list of used_networks sorted in descending order of their hosts size", if: (RUBY_VERSION.to_f >= 2.2) do
        response = @dummy_class.sort_used_networks_by_hosts_size(@used_networks_pool)
        expect(response[0].network.address.concat("/" + response[0].prefix.to_s)).to be == "69.182.9.0/24"
        expect(response[1].network.address.concat("/" + response[1].prefix.to_s)).to be == "69.182.11.0/24"
        expect(response[2].network.address.concat("/" + response[2].prefix.to_s)).to be == "69.182.14.0/24"
        expect(response[3].network.address.concat("/" + response[3].prefix.to_s)).to be == "12.3.19.0/25"
        expect(response[4].network.address.concat("/" + response[4].prefix.to_s)).to be == "12.3.19.128/25"
        expect(response[5].network.address.concat("/" + response[5].prefix.to_s)).to be == "40.23.19.0/29"
      end
    end
  end

  describe "subnet_cidr_prefix" do
    context "example-1" do
      before do
        resource_group_name = "rgrp-3"
        vnet_name = "vnet-4"
        @subnet = subnet(resource_group_name, vnet_name, 0)
      end

      it "returns the cidr prefix of the given subnet" do
        response = @dummy_class.subnet_cidr_prefix(@subnet)
        expect(response).to be == 29
      end
    end

    context "example-2" do
      before do
        resource_group_name = "rgrp-2"
        vnet_name = "vnet-3"
        @subnet = subnet(resource_group_name, vnet_name, 1)
      end

      it "returns the cidr prefix of the given subnet" do
        response = @dummy_class.subnet_cidr_prefix(@subnet)
        expect(response).to be == 25
      end
    end
  end

  describe "sort_pools" do
    it "invokes sort methods for available_networks_pool and used_networks_pool" do
      expect(@dummy_class).to receive(:sort_available_networks).and_return([])
      expect(@dummy_class).to receive(:sort_used_networks_by_hosts_size).and_return([])
      response1, response2 = @dummy_class.sort_pools([], [])
      expect(response1).to be == []
      expect(response2).to be == []
    end
  end

  describe "divide_network" do
    context "very large network is passed" do
      context "example-1" do
        it "divides the network into medium sized subnets" do
          response = @dummy_class.divide_network("10.2.0.0/16")
          expect(response).to be == "10.2.0.0/20"
        end
      end

      context "example-2" do
        it "divides the network into medium sized subnets" do
          response = @dummy_class.divide_network("10.2.0.0/19")
          expect(response).to be == "10.2.0.0/20"
        end
      end
    end

    context "medium sized network is passed" do
      context "example-1" do
        it "divides the network into smaller subnets" do
          response = @dummy_class.divide_network("10.2.0.0/22")
          expect(response).to be == "10.2.0.0/24"
        end
      end

      context "example-2" do
        it "divides the network into smaller subnets" do
          response = @dummy_class.divide_network("10.2.0.0/20")
          expect(response).to be == "10.2.0.0/24"
        end
      end
    end

    context "very small network is passed" do
      context "example-1" do
        it "does not divide the network and keeps it the same" do
          response = @dummy_class.divide_network("10.2.0.0/28")
          expect(response).to be == "10.2.0.0/28"
        end
      end

      context "example-2" do
        it "does not divide the network and keeps it the same" do
          response = @dummy_class.divide_network("10.2.0.0/25")
          expect(response).to be == "10.2.0.0/25"
        end
      end
    end
  end

  describe "in_use_network?" do
    context "subnet_network belongs to available_network" do
      context "example-1" do
        before do
          @subnet_network = IPAddress("79.224.43.229/24")
          @available_network = IPAddress("79.224.43.0/24")
        end

        it "returns true" do
          response = @dummy_class.in_use_network?(
            @subnet_network, @available_network
          )
          expect(response).to be == true
        end
      end

      context "example-2" do
        before do
          @subnet_network = IPAddress("152.23.13.65/24")
          @available_network = IPAddress("152.23.0.0/20")
        end

        it "returns true" do
          response = @dummy_class.in_use_network?(
            @subnet_network, @available_network
          )
          expect(response).to be == true
        end
      end
    end

    context "available_network belongs to subnet_network" do
      context "example-1" do
        before do
          @subnet_network = IPAddress("79.224.43.0/24")
          @available_network = IPAddress("79.224.43.229/24")
        end

        it "returns true" do
          response = @dummy_class.in_use_network?(
            @subnet_network, @available_network
          )
          expect(response).to be == true
        end
      end

      context "example-2" do
        before do
          @subnet_network = IPAddress("152.23.0.0/20")
          @available_network = IPAddress("152.23.13.65/24")
        end

        it "returns true" do
          response = @dummy_class.in_use_network?(
            @subnet_network, @available_network
          )
          expect(response).to be == true
        end
      end
    end

    context "none of the network belongs to the other one" do
      context "example-1" do
        before do
          @subnet_network = IPAddress("139.12.78.0/25")
          @available_network = IPAddress("139.12.78.231")
        end

        it "returns false" do
          response = @dummy_class.in_use_network?(
            @subnet_network, @available_network
          )
          expect(response).to be == false
        end
      end

      context "example-2" do
        before do
          @subnet_network = IPAddress("208.140.12.0/24")
          @available_network = IPAddress("208.140.10.0/24")
        end

        it "returns false" do
          response = @dummy_class.in_use_network?(
            @subnet_network, @available_network
          )
          expect(response).to be == false
        end
      end
    end
  end

  describe "new_subnet_address_prefix" do
    context "no subnets exist under the given vnet address space" do
      it "invokes the divide_network method" do
        expect(@dummy_class).to receive(:divide_network)
        @dummy_class.new_subnet_address_prefix("", [])
      end

      it "invokes divide_network method and return the new subnet prefix value" do
        response = @dummy_class.new_subnet_address_prefix("11.23.0.0/16", [])
        expect(response).to be == "11.23.0.0/20"
      end

      it "invokes divide_network method and return the same vnet prefix value for the new subnet prefix" do
        response = @dummy_class.new_subnet_address_prefix("192.168.172.128/25", [])
        expect(response).to be == "192.168.172.128/25"
      end
    end

    context "subnets exist under the given vnet address space" do
      context "space available in the vnet address space for the addition of new subnet" do
        context "example-1" do
          before do
            resource_group_name = "rgrp-1"
            vnet_name = "vnet-1"
            @vnet_address_prefix = "10.1.0.0/16"
            allow(@dummy_class).to receive(:network_resource_client).and_return(
              stub_network_resource_client(nil, resource_group_name, vnet_name)
            )
            @subnets = @dummy_class.subnets_list(
              resource_group_name, vnet_name, @vnet_address_prefix
            )
          end

          it "returns the address prefix for the new subnet" do
            response = @dummy_class.new_subnet_address_prefix(
              @vnet_address_prefix, @subnets
            )
            expect(response).to be == "10.1.1.0/24"
          end
        end

        context "example-2" do
          before do
            resource_group_name = "rgrp-2"
            vnet_name = "vnet-2"
            @vnet_address_prefix = "192.168.172.0/24"
            allow(@dummy_class).to receive(:network_resource_client).and_return(
              stub_network_resource_client(nil, resource_group_name, vnet_name)
            )
            @subnets = @dummy_class.subnets_list(
              resource_group_name, vnet_name, @vnet_address_prefix
            )
          end

          it "returns the address prefix for the new subnet" do
            response = @dummy_class.new_subnet_address_prefix(
              @vnet_address_prefix, @subnets
            )
            expect(response).to be == "192.168.172.128/25"
          end
        end

        context "example-3" do
          before do
            resource_group_name = "rgrp-3"
            vnet_name = "vnet-5"
            @vnet_address_prefix = "69.182.8.0/21"
            allow(@dummy_class).to receive(:network_resource_client).and_return(
              stub_network_resource_client(nil, resource_group_name, vnet_name)
            )
            @subnets = @dummy_class.subnets_list(
              resource_group_name, vnet_name, @vnet_address_prefix
            )
          end

          it "returns the address prefix for the new subnet" do
            response = @dummy_class.new_subnet_address_prefix(
              @vnet_address_prefix, @subnets
            )
            expect(response).to be == "69.182.8.0/24"
          end
        end
      end

      context "space not available in the vnet address space for the addition of new subnet" do
        context "example-1" do
          before do
            resource_group_name = "rgrp-3"
            vnet_name = "vnet-4"
            @vnet_address_prefix = "40.23.19.0/29"
            allow(@dummy_class).to receive(:network_resource_client).and_return(
              stub_network_resource_client(nil, resource_group_name, vnet_name)
            )
            @subnets = @dummy_class.subnets_list(
              resource_group_name, vnet_name, @vnet_address_prefix
            )
          end

          it "returns nil" do
            response = @dummy_class.new_subnet_address_prefix(
              @vnet_address_prefix, @subnets
            )
            expect(response).to eq nil
          end
        end

        context "example-2" do
          before do
            resource_group_name = "rgrp-3"
            vnet_name = "vnet-5"
            @vnet_address_prefix = "12.3.19.0/24"
            allow(@dummy_class).to receive(:network_resource_client).and_return(
              stub_network_resource_client(nil, resource_group_name, vnet_name)
            )
            @subnets = @dummy_class.subnets_list(
              resource_group_name, vnet_name, @vnet_address_prefix
            )
          end

          it "returns nil" do
            response = @dummy_class.new_subnet_address_prefix(
              @vnet_address_prefix, @subnets
            )
            expect(response).to eq nil
          end
        end

        context "example-3" do
          before do
            @vnet_address_prefix = "62.12.3.128/25"
            @subnets = [OpenStruct.new({ "name" => "sbn17",
                                         "address_prefix" => "62.12.3.128/25",
            })]
          end

          it "returns nil" do
            response = @dummy_class.new_subnet_address_prefix(
              @vnet_address_prefix, @subnets
            )
            expect(response).to eq nil
          end
        end
      end
    end
  end

  describe "add_subnet" do
    context "space does not exist in any of the address_prefixes of the virtual network" do
      context "example-1" do
        before do
          resource_group_name = "rgrp-4"
          vnet_name = "vnet-6"
          @vnet_config = { virtualNetworkName: vnet_name,
                           addressPrefixes: [ "130.88.9.0/24", "112.90.2.0/24" ],
                           subnets: [],
          }
          @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
        end

        it "raises error saying no space available to add subnet" do
          expect do
            @dummy_class.add_subnet("sbn18",
              @vnet_config, @subnets)
          end          .to raise_error(RuntimeError,
            "Unable to add subnet sbn18 into the virtual network #{@vnet_config[:virtualNetworkName]}, no address space available !!!")
        end
      end

      context "example-2" do
        before do
          @vnet_config = { virtualNetworkName: "vnet-6",
                           addressPrefixes: [ "10.10.11.0/24" ],
                           subnets: [],
          }
          @subnets = [OpenStruct.new({ "name" => "sbn19",
                                       "address_prefix" => "10.10.11.0/25",
          }),
          OpenStruct.new({ "name" => "sbn20",
                           "address_prefix" => "10.10.11.128/26",
          }),
          OpenStruct.new({ "name" => "sbn21",
                           "address_prefix" => "10.10.11.192/26",
          })]
        end

        it "raises error saying no space available to add subnet" do
          expect do
            @dummy_class.add_subnet("sbn22",
              @vnet_config, @subnets)
          end .to raise_error(RuntimeError,
            "Unable to add subnet sbn22 into the virtual network #{@vnet_config[:virtualNetworkName]}, no address space available !!!")
        end
      end
    end

    context "space exist in the virtual network" do
      context "example-1" do
        before do
          resource_group_name = "rgrp-3"
          vnet_name = "vnet-4"
          @subnet_name = "sbn23"
          new_subnet_prefix = "10.15.0.0/24"
          @vnet_config = { virtualNetworkName: vnet_name,
                           addressPrefixes: [ "10.15.0.0/20", "40.23.19.0/29" ],
                           subnets: [{ "name" => "sbn8",
                                       "properties" => {
                "address_prefix" => "40.23.19.0/29",
              },
            }],
          }
          @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
          @updated_vnet_config = { virtualNetworkName: vnet_name,
                                   addressPrefixes: [ "10.15.0.0/20", "40.23.19.0/29" ],
                                   subnets: [{ "name" => "sbn8",
                                               "properties" => {
                "address_prefix" => "40.23.19.0/29",
              },
            },
            { "name" => "sbn23",
              "properties" => {
                "addressPrefix" => new_subnet_prefix,
              },
            }],
          }
        end

        it "returns the updated vnet_config with the hash added for the new subnet" do
          response = @dummy_class.add_subnet(@subnet_name, @vnet_config, @subnets)
          expect(response).to be == @updated_vnet_config
        end
      end

      context "example-2" do
        before do
          resource_group_name = "rgrp-2"
          vnet_name = "vnet-2"
          @subnet_name = "sbn24"
          new_subnet_prefix = "10.2.16.16/28"
          @vnet_config = { virtualNetworkName: vnet_name,
                           addressPrefixes: [ "10.2.0.0/16", "192.168.172.0/24", "16.2.0.0/24" ],
                           subnets: [{ "name" => "sbn3",
                                       "properties" => {
                "address_prefix" => "10.2.0.0/20",
              },
            },
            { "name" => "sbn4",
              "properties" => {
                "address_prefix" => "192.168.172.0/25",
              },
            },
            { "name" => "sbn5",
              "properties" => {
                "address_prefix" => "10.2.16.0/28",
              },
            }],
          }
          @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
          @updated_vnet_config = { virtualNetworkName: vnet_name,
                                   addressPrefixes: [ "10.2.0.0/16", "192.168.172.0/24", "16.2.0.0/24" ],
                                   subnets: [{ "name" => "sbn3",
                                               "properties" => {
                "address_prefix" => "10.2.0.0/20",
              },
            },
            { "name" => "sbn4",
              "properties" => {
                "address_prefix" => "192.168.172.0/25",
              },
            },
            { "name" => "sbn5",
              "properties" => {
                "address_prefix" => "10.2.16.0/28",
              },
            },
            { "name" => "sbn24",
              "properties" => {
                "addressPrefix" => new_subnet_prefix,
              },
            }],
          }
        end

        it "returns the updated vnet_config with the hash added for the new subnet" do
          response = @dummy_class.add_subnet(@subnet_name, @vnet_config, @subnets)
          expect(response).to be == @updated_vnet_config
        end
      end
    end
  end

  describe "create_vnet_config" do
    context "user passed or default named vnet does not exist in the given resource_group" do
      before do
        @resource_group_name = "rgrp-1"
        @vnet_name = "vnet-11"
        @subnet_name = "sbn11"
        allow(@dummy_class).to receive(:get_vnet).and_return(false)
        @vnet_config = { virtualNetworkName: "vnet-11",
                         addressPrefixes: [ "10.0.0.0/16" ],
                         subnets: [{ "name" => "sbn11",
                                     "properties" => {
              "addressPrefix" => "10.0.0.0/24",
            },
          }],
        }
      end

      it "returns vnet_config with default values for vnet and subnet configurations" do
        response = @dummy_class.create_vnet_config(
          @resource_group_name, @vnet_name, @subnet_name
        )
        expect(response).to be == @vnet_config
      end
    end

    context "user passed or default named vnet exist in the given resource_group" do
      context "user passed or default named subnet exist in the given virtual network" do
        context "example-1" do
          before do
            @resource_group_name = "rgrp-2"
            @vnet_name = "vnet-3"
            @subnet_name = "sbn7"
            allow(@dummy_class).to receive(:network_resource_client).and_return(
              stub_network_resource_client(nil, @resource_group_name, @vnet_name)
            )
            @vnet_config = @vnet_config = { virtualNetworkName: "vnet-3",
                                            addressPrefixes: [ "25.3.16.0/20", "141.154.163.0/26" ],
                                            subnets: [{ "name" => "sbn6",
                                                        "properties" => {
                  "addressPrefix" => "25.3.29.0/25",
                },
              },
              { "name" => "sbn7",
                "properties" => {
                  "addressPrefix" => "25.3.29.128/25",
                },
              }],
            }
          end

          it "returns vnet_config with no change" do
            response = @dummy_class.create_vnet_config(
              @resource_group_name, @vnet_name, @subnet_name
            )
            expect(response).to be == @vnet_config
          end
        end

        context "example-2" do
          before do
            @resource_group_name = "rgrp-3"
            @vnet_name = "vnet-4"
            @subnet_name = "sbn8"
            allow(@dummy_class).to receive(:network_resource_client).and_return(
              stub_network_resource_client(nil, @resource_group_name, @vnet_name)
            )
            @vnet_config = @vnet_config = { virtualNetworkName: "vnet-4",
                                            addressPrefixes: [ "10.15.0.0/20", "40.23.19.0/29" ],
                                            subnets: [{ "name" => "sbn8",
                                                        "properties" => {
                  "addressPrefix" => "40.23.19.0/29",
                },
              }],
            }
          end

          it "returns vnet_config with no change" do
            response = @dummy_class.create_vnet_config(
              @resource_group_name, @vnet_name, @subnet_name
            )
            expect(response).to be == @vnet_config
          end
        end
      end

      context "user passed or default named subnet does not exist in the given virtual network" do
        context "no space available in the given virtual network to add the new subnet" do
          context "example-1" do
            before do
              @resource_group_name = "rgrp-4"
              @vnet_name = "vnet-6"
              @subnet_name = "sbn40"
              allow(@dummy_class).to receive(:network_resource_client).and_return(
                stub_network_resource_client(nil, @resource_group_name, @vnet_name)
              )
            end

            it "raises error" do
              expect do
                @dummy_class.create_vnet_config(
                  @resource_group_name, @vnet_name, @subnet_name
                )
              end.to raise_error(RuntimeError,
                "Unable to add subnet #{@subnet_name} into the virtual network #{@vnet_name}, no address space available !!!")
            end
          end

          context "example-2" do
            before do
              @resource_group_name = "rgrp-5"
              @vnet_name = "vnet-50"
              @subnet_name = "sbn60"

              subnets = [OpenStruct.new({ "name" => "sbn19",
                                          "address_prefix" => "10.10.11.0/25",
              }),
              OpenStruct.new({ "name" => "sbn20",
                               "address_prefix" => "10.10.11.128/26",
              }),
              OpenStruct.new({ "name" => "sbn21",
                               "address_prefix" => "10.10.11.192/26",
              })]

              vnet = OpenStruct.new({
                "location" => "westus",
                "address_space" => OpenStruct.new({
                    "address_prefixes" => [ "10.10.11.0/24" ],
                  }),
                "subnets" => subnets,
              })

              allow(@dummy_class).to receive(:get_vnet).and_return(vnet)
              allow(@dummy_class).to receive(:subnets_list).and_return(subnets)
            end

            it "raises error" do
              expect do
                @dummy_class.create_vnet_config(
                  @resource_group_name, @vnet_name, @subnet_name
                )
              end.to raise_error(RuntimeError,
                "Unable to add subnet #{@subnet_name} into the virtual network #{@vnet_name}, no address space available !!!")
            end
          end
        end

        context "space available in the given virtual network to add the new subnet" do
          context "example for subnet allocation in first prefix" do
            before do
              @resource_group_name = "rgrp-3"
              @vnet_name = "vnet-5"
              @subnet_name = "sbn27"
              new_subnet_prefix = "69.182.8.0/24"
              allow(@dummy_class).to receive(:network_resource_client).and_return(
                stub_network_resource_client(nil, @resource_group_name, @vnet_name)
              )
              @vnet_config = { virtualNetworkName: "vnet-5",
                               addressPrefixes: [ "69.182.8.0/21", "12.3.19.0/24" ],
                               subnets: [{ "name" => "sbn9",
                                           "properties" => {
                    "addressPrefix" => "69.182.9.0/24",
                  },
                },
                { "name" => "sbn10",
                  "properties" => {
                    "addressPrefix" => "69.182.11.0/24",
                  },
                },
                { "name" => "sbn11",
                  "properties" => {
                    "addressPrefix" => "12.3.19.0/25",
                  },
                },
                { "name" => "sbn12",
                  "properties" => {
                    "addressPrefix" => "69.182.14.0/24",
                  },
                },
                { "name" => "sbn13",
                  "properties" => {
                    "addressPrefix" => "12.3.19.128/25",
                  },
                },
                { "name" => "sbn27",
                  "properties" => {
                    "addressPrefix" => new_subnet_prefix,
                  },
                }],
              }
            end

            it "returns vnet_config with new subnet added in first prefix" do
              response = @dummy_class.create_vnet_config(
                @resource_group_name, @vnet_name, @subnet_name
              )
              expect(response).to be == @vnet_config
            end
          end

          context "example for subnet allocation in subsequent prefix but first" do
            before do
              @resource_group_name = "rgrp-6"
              @vnet_name = "vnet-60"
              @subnet_name = "sbn70"
              new_subnet_prefix = "133.72.16.128/25"

              subnets = [OpenStruct.new({ "name" => "sbn19",
                                          "address_prefix" => "10.10.11.0/25",
              }),
              OpenStruct.new({ "name" => "sbn20",
                               "address_prefix" => "10.10.11.128/26",
              }),
              OpenStruct.new({ "name" => "sbn21",
                               "address_prefix" => "10.10.11.192/26",
              }),
              OpenStruct.new({ "name" => "sbn22",
                               "address_prefix" => "192.168.172.0/24",
              }),
              OpenStruct.new({ "name" => "sbn23",
                               "address_prefix" => "133.72.16.0/25",
              })]

              vnet = OpenStruct.new({
                "location" => "westus",
                "address_space" => OpenStruct.new({
                    "address_prefixes" => [ "10.10.11.0/24", "192.168.172.0/24", "133.72.16.0/24" ],
                  }),
                "subnets" => subnets,
              })

              allow(@dummy_class).to receive(:get_vnet).and_return(vnet)
              allow(@dummy_class).to receive(:subnets_list).and_return(subnets)

              @vnet_config = { virtualNetworkName: "vnet-60",
                               addressPrefixes: [ "10.10.11.0/24", "192.168.172.0/24", "133.72.16.0/24" ],
                               subnets: [{ "name" => "sbn19",
                                           "properties" => {
                    "addressPrefix" => "10.10.11.0/25",
                  },
                },
                { "name" => "sbn20",
                  "properties" => {
                    "addressPrefix" => "10.10.11.128/26",
                  },
                },
                { "name" => "sbn21",
                  "properties" => {
                    "addressPrefix" => "10.10.11.192/26",
                  },
                },
                { "name" => "sbn22",
                  "properties" => {
                    "addressPrefix" => "192.168.172.0/24",
                  },
                },
                { "name" => "sbn23",
                  "properties" => {
                    "addressPrefix" => "133.72.16.0/25",
                  },
                },
                { "name" => "sbn70",
                  "properties" => {
                    "addressPrefix" => new_subnet_prefix,
                  },
                }],
              }
            end

            it "returns vnet_config with new subnet added in subsequent prefix but first" do
              response = @dummy_class.create_vnet_config(
                @resource_group_name, @vnet_name, @subnet_name
              )
              expect(response).to be == @vnet_config
            end
          end

          context "divide_network example" do
            before do
              @resource_group_name = "rgrp-3"
              @vnet_name = "vnet-4"
              @subnet_name = "sbn26"
              new_subnet_prefix = "10.15.0.0/24"
              allow(@dummy_class).to receive(:network_resource_client).and_return(
                stub_network_resource_client(nil, @resource_group_name, @vnet_name)
              )
              @vnet_config = @vnet_config = { virtualNetworkName: "vnet-4",
                                              addressPrefixes: [ "10.15.0.0/20", "40.23.19.0/29" ],
                                              subnets: [{ "name" => "sbn8",
                                                          "properties" => {
                    "addressPrefix" => "40.23.19.0/29",
                  },
                },
                { "name" => "sbn26",
                  "properties" => {
                    "addressPrefix" => new_subnet_prefix,
                  },
                }],
              }
            end

            it "returns vnet_config with new subnet added" do
              response = @dummy_class.create_vnet_config(
                @resource_group_name, @vnet_name, @subnet_name
              )
              expect(response).to be == @vnet_config
            end
          end
        end
      end
    end
  end

  describe "GatewaySubnet" do
    context "user provided or default named virtual network exist along with GatewaySubnet and other subnets also present" do
      context "user provided or default named subnet does not exist in the virtual network" do
        before do
          @resource_group_name = "rgrp-4"
          @vnet_name = "vnet-7"
          @subnet_name = "sbn30"
          new_subnet_prefix = "10.3.0.0/24"
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            stub_network_resource_client(nil, @resource_group_name, @vnet_name)
          )
          @vnet_config = { virtualNetworkName: "vnet-7",
                           addressPrefixes: [ "10.3.0.0/16", "160.10.2.0/24" ],
                           subnets: [{ "name" => "sbn15",
                                       "properties" => {
                "addressPrefix" => "160.10.2.192/26",
              },
            },
            { "name" => "GatewaySubnet",
              "properties" => {
                "addressPrefix" => "10.3.1.0/24",
              },
            },
            { "name" => "sbn16",
              "properties" => {
                "addressPrefix" => "160.10.2.0/25",
              },
            },
            { "name" => "sbn30",
              "properties" => {
                "addressPrefix" => new_subnet_prefix,
              },
            }],
          }
        end

        it "returns vnet_config with GatewaySubnet along with other subnets preserved and also new subnet added" do
          response = @dummy_class.create_vnet_config(
            @resource_group_name, @vnet_name, @subnet_name
          )
          expect(response).to be == @vnet_config
        end
      end

      context "user provided or default named subnet exist in the virtual network" do
        before do
          @resource_group_name = "rgrp-4"
          @vnet_name = "vnet-7"
          @subnet_name = "sbn16"
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            stub_network_resource_client(nil, @resource_group_name, @vnet_name)
          )
          @vnet_config = { virtualNetworkName: "vnet-7",
                           addressPrefixes: [ "10.3.0.0/16", "160.10.2.0/24" ],
                           subnets: [{ "name" => "sbn15",
                                       "properties" => {
                "addressPrefix" => "160.10.2.192/26",
              },
            },
            { "name" => "GatewaySubnet",
              "properties" => {
                "addressPrefix" => "10.3.1.0/24",
              },
            },
            { "name" => "sbn16",
              "properties" => {
                "addressPrefix" => "160.10.2.0/25",
              },
            }],
          }
        end

        it "returns vnet_config with no change" do
          response = @dummy_class.create_vnet_config(
            @resource_group_name, @vnet_name, @subnet_name
          )
          expect(response).to be == @vnet_config
        end
      end
    end

    context "user provided or default named subnet value is GatewaySubnet" do
      it "raises error" do
        expect do
          @dummy_class.create_vnet_config(
            "rgrp-1", "vnet-1", "GatewaySubnet"
          )
        end.to raise_error(ArgumentError, "GatewaySubnet cannot be used as the name for --azure-vnet-subnet-name option. GatewaySubnet can only be used for virtual network gateways.")
      end
    end

    context "user provided or default named subnet value is not GatewaySubnet" do
      before do
        @resource_group_name = "rgrp-4"
        @vnet_name = "vnet-7"
        @subnet_name = "sbn26"
        allow(@dummy_class).to receive(:network_resource_client).and_return(
          stub_network_resource_client(nil, @resource_group_name, @vnet_name)
        )
      end

      it "does not raise error" do
        expect do
          @dummy_class.create_vnet_config(
            @resource_group_name, @vnet_name, @subnet_name
          )
        end .to_not raise_error
      end
    end
  end
end
