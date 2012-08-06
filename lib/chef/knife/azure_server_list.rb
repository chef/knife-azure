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

        validate!

        server_list = [
          ui.color('Status', :bold),
          ui.color('Service', :bold),
          ui.color('Deployment', :bold),
          ui.color('Role', :bold),
          ui.color('Host', :bold),
          ui.color('IP Address', :bold),
          ui.color('SSH Port', :bold),
          ui.color('WinRM Port', :bold)
        ]
        items = connection.roles.all
        items.each do |server|
          server_list << begin
                           state = server.status.to_s.downcase
                           case state
                           when 'shutting-down','terminated','stopping','stopped'
                             ui.color(state, :red)
                           when 'pending'
                             ui.color(state, :yellow)
                           else
                             ui.color('ready', :green)
                           end
          end
          server_list << server.hostedservicename.to_s
          server_list << server.deployname.to_s
          server_list << server.name.to_s
          server_list << server.hostname.to_s
          server_list << server.sshipaddress.to_s
          server_list << server.sshport.to_s
          server_list << server.winrmport.to_s
        end
        puts ''
        puts ui.list(server_list, :columns_across, 8)
      end
    end
  end
end
