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
    class AzureAgCreate < Knife
      include Knife::AzureBase

      banner "knife azure ag create (options)"

      option :azure_affinity_group,
        short: "-a GROUP",
        long: "--azure-affinity-group GROUP",
        description: "Specifies new affinity group name."

      option :azure_ag_desc,
        long: "--azure-ag-desc DESC",
        description: "Optional. Description for new affinity group."

      option :azure_service_location,
        short: "-m LOCATION",
        long: "--azure-service-location LOCATION",
        description: "Specifies the geographic location - the name of "\
                        "the data center location that is valid for your "\
                        "subscription. Eg: West US, East US, "\
                        "East Asia, Southeast Asia, North Europe, West Europe"

      def run
        $stdout.sync = true

        Chef::Log.info("validating...")
        validate_asm_keys!(:azure_affinity_group,
          :azure_service_location)

        params = {
          azure_ag_name: locate_config_value(:azure_affinity_group),
          azure_ag_desc: locate_config_value(:azure_ag_desc),
          azure_location: locate_config_value(:azure_service_location),
        }

        rsp = service.create_affinity_group(params)
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
