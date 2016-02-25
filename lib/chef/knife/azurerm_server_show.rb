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

require File.expand_path('../azurerm_base', __FILE__)

class Chef
  class Knife
    class AzurermServerShow < Knife

      include Knife::AzurermBase

      banner "knife azurerm server show SERVER (options)" 

      def run
        $stdout.sync = true
     
        validate_arm_keys!(:azure_resource_group_name) 
        
        service.show_server(@name_args[0], locate_config_value(:azure_resource_group_name))

      end
    end
  end
end
