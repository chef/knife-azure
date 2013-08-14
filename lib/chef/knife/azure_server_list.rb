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

        server_labels = ['DNS Name', 'VM Name', 'Status', 'IP Address', 'SSH Port', 'WinRM Port' ]
        server_list =  server_labels.map {|label| ui.color(label, :bold)}
        begin
          items = connection.roles.all
        rescue ConnectionExceptions::QueryAzureException => e
          ui.error e.message
          exit 1
        end

        items.each do |server|
          server_list << server.hostedservicename.to_s+".cloudapp.net"  # Info about the DNS name at http://msdn.microsoft.com/en-us/library/ee460806.aspx
          server_list << server.name.to_s
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
          server_list << server.publicipaddress.to_s
          server_list << server.sshport.to_s
          server_list << server.winrmport.to_s
        end
        puts ''
        puts ui.list(server_list, :uneven_columns_across, 6)
      end
    end
  end
end
