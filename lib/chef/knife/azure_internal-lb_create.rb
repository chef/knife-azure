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

require File.expand_path("../azure_base", __FILE__)

class Chef
  class Knife
    class AzureInternalLbCreate < Knife
      include Knife::AzureBase

      banner "knife azure internal lb create (options)"

      option :azure_load_balancer,
        short: "-n NAME",
        long: "--azure-load-balancer NAME",
        description: "Required. Specifies new load balancer name."

      option :azure_lb_static_vip,
        long: "--azure-lb-static-vip VIP",
        description: "Optional. The Virtual IP that will be used for the load balancer."

      option :azure_subnet_name,
        long: "--azure-subnet-name SUBNET_NAME",
        description: "Required if static VIP is set. Specifies the subnet name "\
                        "the load balancer is located in."

      option :azure_dns_name,
        long: "--azure-dns-name DNS_NAME",
        description: "The DNS prefix name that will be used to add this load balancer to. This must be an existing service/deployment."

      def run
        $stdout.sync = true

        Chef::Log.info("validating...")
        validate_asm_keys!(:azure_load_balancer)

        params = {
          azure_load_balancer: locate_config_value(:azure_load_balancer),
          azure_lb_static_vip: locate_config_value(:azure_lb_static_vip),
          azure_subnet_name: locate_config_value(:azure_subnet_name),
          azure_dns_name: locate_config_value(:azure_dns_name),
        }

        rsp = service.create_internal_lb(params)
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
