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

require File.expand_path("../azure_base", __FILE__)

class Chef
  class Knife
    class AzureVnetCreate < Knife
      include Knife::AzureBase

      banner "knife azure vnet create (options)"

      option :azure_network_name,
        short: "-n NETWORK_NAME",
        long: "--azure-network-name NETWORK_NAME",
        description:           "Specifies the name of the virtual network to create."

      option :azure_affinity_group,
        short: "-a GROUP",
        long: "--azure-affinity-group GROUP",
        description:           "Specifies the affinity group to associate with the vnet."

      option :azure_address_space,
        long: "--azure-address-space CIDR",
        description:           "Specifies the address space of the vnet using CIDR notation."

      option :azure_subnet_name,
        long: "--azure-subnet-name CIDR",
        description:           "Specifies the Subnet Name."

      def run
        $stdout.sync = true

        Chef::Log.info("validating...")
        validate_asm_keys!(:azure_network_name, :azure_affinity_group, :azure_address_space)

        params = {
          azure_vnet_name: locate_config_value(:azure_network_name),
          azure_ag_name: locate_config_value(:azure_affinity_group),
          azure_address_space: locate_config_value(:azure_address_space),
          azure_subnet_name: locate_config_value(:azure_subnet_name) || "Subnet-#{Random.rand(10)}",
        }

        rsp = service.create_vnet(params)
        print "\n"
        if rsp.at_css("Status").nil?
          if rsp.at_css("Code").nil? || rsp.at_css("Message").nil?
            puts "Unknown Error. try -VV"
          else
            puts "#{rsp.at_css("Code").content}: "\
                 "#{rsp.at_css("Message").content}"
          end
        else
          puts "Creation status: #{rsp.at_css("Status").content}"
        end
      end
    end
  end
end
