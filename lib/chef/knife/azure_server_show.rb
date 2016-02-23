#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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

require File.expand_path('../azure_base', __FILE__)

class Chef
  class Knife
    class AzureServerShow < Knife

      include Knife::AzureBase

      banner "knife azure server show SERVER [SERVER]"

       option :resource_group,
         :long => "--resource-group RESOURCE_GROUP",
         :description => "Optional. Specifies the resource group of server. If not specified then server name is considered as resource group"
       

      def run
        $stdout.sync = true
        if(locate_config_value(:azure_api_mode) == "asm")
          validate_asm_keys!

          @name_args.each do |name|
            service.show_server name
          end

        elsif(locate_config_value(:azure_api_mode) == "arm")
          validate_arm_keys!
          
          #INFO - if resource is not provided then consider VMName as Resource Group
          if locate_config_value(:resource_group)   
            resource_group = locate_config_value(:resource_group)
          else
            resource_group = @name_args[0]
          end 
          
          service.show_server(@name_args[0], resource_group)
        end  

      end
    end
  end
end
