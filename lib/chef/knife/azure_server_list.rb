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
    class AzureServerList < Knife

      include Knife::AzureBase

      banner "knife azure server list (options)"

      def run
        $stdout.sync = true

        if(locate_config_value(:azure_api_mode) == "asm")
          validate_asm_keys!
        elsif(locate_config_value(:azure_api_mode) == "arm")
          validate_arm_keys!
        end

        service.list_servers
      end

      def display_arm_output items
        server_labels = ['VM Name', 'Location', 'Provisioning State', 'OS Type']
        server_list =  server_labels.map {|label| ui.color(label, :bold)}

        items.each do |server|
          server_list << server.name.to_s
          server_list << server.location.to_s
          server_list << begin
                           state = server.properties.provisioning_state.to_s.downcase
                           case state
                           when 'shutting-down','terminated','stopping','stopped'
                             ui.color(state, :red)
                           when 'pending'
                             ui.color(state, :yellow)
                           else
                             ui.color('ready', :green)
                           end
                         end
          server_list << server.properties.storage_profile.os_disk.os_type.to_s
        end
        puts ''
        puts ui.list(server_list, :uneven_columns_across, 4)
      end
    end
  end
end
