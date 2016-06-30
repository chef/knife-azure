#
# Author:: Aliasgar Batterywala (<aliasgar.batterywala@clogeny.com>)
# Copyright:: Copyright (c) 2016 Opscode, Inc.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

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
    @resource_groups = [{'rgrp-1' => {
      'vnets' => [{'vnet-1' => OpenStruct.new({
        'location' => 'westus',
        'properties' => OpenStruct.new({
          'address_space' => OpenStruct.new({
            'address_prefixes' => [ '10.1.0.0/16' ]
          }),
          'subnets' => [OpenStruct.new({'name'=> 'sbn1',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '10.1.0.0/24'
            })
          }),
          OpenStruct.new({'name'=> 'sbn2',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '10.1.48.0/20'
            })
          })]
        })
      })}]
    }},
    {'rgrp-2' => {
      'vnets' => [{'vnet-2' => OpenStruct.new({
        'location' => 'westus',
        'properties' => OpenStruct.new({
          'address_space' => OpenStruct.new({
            'address_prefixes' => [ '10.2.0.0/16', '192.168.172.0/24', '16.2.0.0/24' ]
          }),
          'subnets' => [OpenStruct.new({'name'=> 'sbn3',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '10.2.0.0/20'
            })
          }),
          OpenStruct.new({'name'=> 'sbn4',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '192.168.172.0/25'
            })
          }),
          OpenStruct.new({'name'=> 'sbn5',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '10.2.14.0/28'
            })
          })]
        })
      })},
      {'vnet-3' => OpenStruct.new({
        'location' => 'westus',
        'properties' => OpenStruct.new({
          'address_space' => OpenStruct.new({
            'address_prefixes' => [ '25.3.16.0/20', '141.154.163.0/26']
          }),
          'subnets' => [OpenStruct.new({'name'=> 'sbn6',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '25.3.29.0/25'
            })
          }),
          OpenStruct.new({'name'=> 'sbn7',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '25.3.29.128/25'
            })
          })]
        })
      })}]
    }},
    {'rgrp-3' => {
      'vnets' => [{'vnet-4' => OpenStruct.new({
        'location' => 'westus',
        'properties' => OpenStruct.new({
          'address_space' => OpenStruct.new({
            'address_prefixes' => [ '10.15.0.0/20', '40.23.19.0/29' ]
          }),
          'subnets' => [OpenStruct.new({'name'=> 'sbn8',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '40.23.19.0/29'
            })
          })]
        })
      })},
      {'vnet-5' => OpenStruct.new({
        'location' => 'westus',
        'properties' => OpenStruct.new({
          'address_space' => OpenStruct.new({
            'address_prefixes' => [ '69.182.8.0/21', '12.3.19.0/24' ]
          }),
          'subnets' => [OpenStruct.new({'name'=> 'sbn9',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '69.182.9.0/24'
            })
          }),
          OpenStruct.new({'name'=> 'sbn10',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '69.182.11.0/24'
            })
          }),
          OpenStruct.new({'name'=> 'sbn11',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '12.3.19.0/25'
            })
          }),
          OpenStruct.new({'name'=> 'sbn12',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '69.182.14.0/24'
            })
          }),
          OpenStruct.new({'name'=> 'sbn13',
            'properties'=> OpenStruct.new({
              'address_prefix'=> '12.3.19.128/25'
            })
          })]
        })
      })}]
    }}]

    @dummy_class = Azure::ARM::DummyClass.new
  end

  def subnet(resource_group_name, vnet_name, subnet_index = nil)
    subnets_list = stub_subnets_list_response(resource_group_name, vnet_name)

    subnet_index.nil? ? subnets_list : subnets_list[subnet_index]
  end

  describe 'subnets_list_specific_address_space' do
    context 'subnets exist in the given address_prefix of the virtual network' do
      context 'example-1' do
        before do
          resource_group_name = 'rgrp-2'
          vnet_name = 'vnet-2'
          @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
          @subnets_address_prefix = [ subnet(resource_group_name, vnet_name, 0),
            subnet(resource_group_name, vnet_name, 2)
          ]
        end

        it 'returns the list of subnets which belongs to the given address_prefix of the virtual network' do
          response = @dummy_class.subnets_list_specific_address_space('10.2.0.0/16', @subnets)
          expect(response.class).to be == Array
          expect(response).to be == @subnets_address_prefix
        end
      end

      context 'example-2' do
        before do
          resource_group_name = 'rgrp-1'
          vnet_name = 'vnet-1'
          @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
          @subnets_address_prefix = [ subnet(resource_group_name, vnet_name, 0),
            subnet(resource_group_name, vnet_name, 1)
          ]
        end

        it 'returns the list of subnets which belongs to the given address_prefix of the virtual network' do
          response = @dummy_class.subnets_list_specific_address_space('10.1.0.0/16', @subnets)
          expect(response.class).to be == Array
          expect(response).to be == @subnets_address_prefix
        end
      end
    end

    context 'no subnets exist in the given address_prefix of the virtual network - example1' do
      context 'example-1' do
        before do
          resource_group_name = 'rgrp-3'
          vnet_name = 'vnet-4'
          @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
          @subnets_address_prefix = []
        end

        it 'returns the empty list of subnets' do
          response = @dummy_class.subnets_list_specific_address_space('10.15.0.0/20', @subnets)
          expect(response.class).to be == Array
          expect(response).to be == @subnets_address_prefix
        end
      end

      context 'example-2' do
        before do
          resource_group_name = 'rgrp-2'
          vnet_name = 'vnet-3'
          @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
        end

        it 'returns the empty list of subnets' do
          response = @dummy_class.subnets_list_specific_address_space('141.154.163.0/26', @subnets)
          expect(response.class).to be == Array
          expect(response.empty?).to be == true
        end
      end
    end
  end

  describe 'subnets_list' do
    context 'when address_prefix is not passed' do
      context 'example-1' do
        before do
          @resource_group_name = 'rgrp-2'
          @vnet_name = 'vnet-2'
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            stub_network_resource_client(nil, @resource_group_name, @vnet_name))
          @subnets_vnet_name = [ subnet(@resource_group_name, @vnet_name) ].flatten!
        end

        it 'returns a list of all the subnets present under the given virtual network' do
          response = @dummy_class.subnets_list(@resource_group_name, @vnet_name)
          expect(response.class).to be == Array
          expect(response).to be == @subnets_vnet_name
        end
      end

      context 'example-2' do
        before do
          @resource_group_name = 'rgrp-2'
          @vnet_name = 'vnet-3'
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            stub_network_resource_client(nil, @resource_group_name, @vnet_name))
          @subnets_vnet_name = [ subnet(@resource_group_name, @vnet_name) ].flatten!
        end

        it 'returns a list of all the subnets present under the given virtual network' do
          response = @dummy_class.subnets_list(@resource_group_name, @vnet_name)
          expect(response.class).to be == Array
          expect(response).to be == @subnets_vnet_name
        end
      end
    end

    context 'when address_prefix is passed' do
      context 'example-1' do
        before do
          @resource_group_name = 'rgrp-2'
          @vnet_name = 'vnet-2'
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            stub_network_resource_client(nil, @resource_group_name, @vnet_name))
          @subnets_address_prefix = [ subnet(@resource_group_name, @vnet_name, 1) ]
        end

        it 'returns a list of all the subnets present under the given virtual network' do
          response = @dummy_class.subnets_list(@resource_group_name, @vnet_name, '192.168.172.0/24')
          expect(response.class).to be == Array
          expect(response).to be == @subnets_address_prefix
        end
      end

      context 'example-2' do
        before do
          @resource_group_name = 'rgrp-3'
          @vnet_name = 'vnet-5'
          allow(@dummy_class).to receive(:network_resource_client).and_return(
            stub_network_resource_client(nil, @resource_group_name, @vnet_name))
          @subnets_address_prefix = [ subnet(@resource_group_name, @vnet_name, 0),
            subnet(@resource_group_name, @vnet_name, 1),
            subnet(@resource_group_name, @vnet_name, 3)
          ]
        end

        it 'returns a list of all the subnets present under the given virtual network' do
          response = @dummy_class.subnets_list(@resource_group_name, @vnet_name, '69.182.8.0/21')
          expect(response.class).to be == Array
          expect(response).to be == @subnets_address_prefix
        end
      end
    end
  end

  describe 'subnet' do
    before do
      @subnet = {
        'name'=> 'my_sbn',
        'properties'=> {
          'addressPrefix'=> '10.20.30.40/20'
        }
      }
    end

    it 'returns the hash for subnet' do
      response = @dummy_class.subnet('my_sbn', '10.20.30.40/20')
      expect(response.class).to be == Hash
      expect(response).to be == @subnet
    end
  end

  describe 'vnet_address_spaces' do
    context 'example-1' do
      before do
        resource_group_name = 'rgrp-1'
        vnet_name = 'vnet-1'
        @vnet = @resource_groups[0][resource_group_name]['vnets'][0][vnet_name]
        @address_prefixes = [ '10.1.0.0/16' ]
      end

      it 'returns address_prefixes for the given virtual network existing under the given resource group' do
        response = @dummy_class.vnet_address_spaces(@vnet)
        expect(response.class).to be == Array
        expect(response).to be == @address_prefixes
      end
    end

    context 'example-2' do
      before do
        resource_group_name = 'rgrp-2'
        vnet_name = 'vnet-2'
        @vnet = @resource_groups[1][resource_group_name]['vnets'][0][vnet_name]
        @address_prefixes = [ '10.2.0.0/16', '192.168.172.0/24', '16.2.0.0/24' ]
      end

      it 'returns address_prefixes for the given virtual network existing under the given resource group' do
        response = @dummy_class.vnet_address_spaces(@vnet)
        expect(response.class).to be == Array
        expect(response).to be == @address_prefixes
      end
    end
  end

  describe 'subnet_address_prefix' do
    context 'example-1' do
      before do
        resource_group_name = 'rgrp-2'
        vnet_name = 'vnet-2'
        @subnet = subnet(resource_group_name, vnet_name, 1)
      end

      it 'returns the address_prefix of the subnet present under the given resource_group and vnet_name at the 1st index' do
        response = @dummy_class.subnet_address_prefix(@subnet)
        expect(response.class).to be == String
        expect(response).to be == '192.168.172.0/25'
      end
    end

    context 'example-2' do
      before do
        resource_group_name = 'rgrp-3'
        vnet_name = 'vnet-5'
        @subnet = subnet(resource_group_name, vnet_name, 4)
      end

      it 'returns the address_prefix of the subnet present under the given resource_group and vnet_name at the 4th index' do
        response = @dummy_class.subnet_address_prefix(@subnet)
        expect(response.class).to be == String
        expect(response).to be == '12.3.19.128/25'
      end
    end
  end

  describe 'sort_available_networks' do
    context 'example-1' do
      before do
        @available_networks = [ IPAddress('10.16.48.0/20'),
          IPAddress('10.16.32.0/24'),
          IPAddress('12.23.19.0/24'),
          IPAddress('221.17.234.0/29'),
          IPAddress('133.78.152.0/25'),
          IPAddress('11.13.48.0/20')
        ]
      end

      it 'sorts the given pool of available_networks in ascending order of the network\'s address' do
        response = @dummy_class.sort_available_networks(@available_networks)
        expect("#{response[0].network.address}/#{response[0].prefix}").to be == '10.16.32.0/24'
        expect("#{response[1].network.address}/#{response[1].prefix}").to be == '10.16.48.0/20'
        expect("#{response[2].network.address}/#{response[2].prefix}").to be == '11.13.48.0/20'
        expect("#{response[3].network.address}/#{response[3].prefix}").to be == '12.23.19.0/24'
        expect("#{response[4].network.address}/#{response[4].prefix}").to be == '133.78.152.0/25'
        expect("#{response[5].network.address}/#{response[5].prefix}").to be == '221.17.234.0/29'
      end
    end

    context 'example-2' do
      before do
        @available_networks = [ IPAddress('159.10.0.0/16'),
          IPAddress('28.65.42.0/24'),
          IPAddress('165.98.0.0/20'),
          IPAddress('192.168.172.0/24'),
          IPAddress('31.66.12.128/25'),
          IPAddress('10.9.0.0/16')
        ]
      end

      it 'sorts the given pool of available_networks in ascending order of the network\'s address' do
        response = @dummy_class.sort_available_networks(@available_networks)
        expect("#{response[0].network.address}/#{response[0].prefix}").to be == '10.9.0.0/16'
        expect("#{response[1].network.address}/#{response[1].prefix}").to be == '28.65.42.0/24'
        expect("#{response[2].network.address}/#{response[2].prefix}").to be == '31.66.12.128/25'
        expect("#{response[3].network.address}/#{response[3].prefix}").to be == '159.10.0.0/16'
        expect("#{response[4].network.address}/#{response[4].prefix}").to be == '165.98.0.0/20'
        expect("#{response[5].network.address}/#{response[5].prefix}").to be == '192.168.172.0/24'
      end
    end
  end

  describe 'sort_subnets_by_cidr_prefix' do
    context 'example-1' do
      before do
        resource_group_name = 'rgrp-2'
        vnet_name = 'vnet-2'
        @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
        resource_group_name = 'rgrp-1'
        vnet_name = 'vnet-1'
        @subnets.push(stub_subnets_list_response(
          resource_group_name, vnet_name)).flatten!
      end

      it 'returns the sorted list of subnets in ascending order of their cidr prefix' do
        response = @dummy_class.sort_subnets_by_cidr_prefix(@subnets)
        expect(response[0].properties.address_prefix).to be == '10.2.0.0/20'
        expect(response[1].properties.address_prefix).to be == '10.1.48.0/20'
        expect(response[2].properties.address_prefix).to be == '10.1.0.0/24'
        expect(response[3].properties.address_prefix).to be == '10.2.14.0/28'
        expect(response[4].properties.address_prefix).to be == '192.168.172.0/25'
      end
    end

    # context 'example-2' do
    #   before do
    #     resource_group_name = 'rgrp-3'
    #     vnet_name = 'vnet-5'
    #     @subnets = stub_subnets_list_response(resource_group_name, vnet_name)
    #   end

    #   it 'returns the sorted list of subnets in ascending order of their cidr prefix' do
    #     response = @dummy_class.sort_subnets_by_cidr_prefix(@subnets)
    #     expect(response[1].properties.address_prefix).to be == '12.3.19.0/25'
    #     expect(response[0].properties.address_prefix).to be == '12.3.19.128/25'
    #     expect(response[2].properties.address_prefix).to be == '69.182.11.0/24'
    #     expect(response[3].properties.address_prefix).to be == '69.182.14.0/24'
    #     expect(response[4].properties.address_prefix).to be == '69.182.9.0/24'
    #   end
    # end
  end
end
