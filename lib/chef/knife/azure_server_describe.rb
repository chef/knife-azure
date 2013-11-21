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
    class AzureServerDescribe < Knife

      include Knife::AzureBase

      banner "knife azure server describe ROLE [ROLE]"

      def run
        $stdout.sync = true

        validate!

        @name_args.each do |name|
          role = connection.roles.find name
          puts ''
          if (role)
            details = Array.new
            details << ui.color('Role name', :bold, :blue)
            details << role.name
            details << ui.color('Status', :bold, :blue)
            details << role.status
            details << ui.color('Size', :bold, :blue)
            details << role.size
            details << ui.color('Hosted service name', :bold, :blue)
            details << role.hostedservicename
            details << ui.color('Deployment name', :bold, :blue)
            details << role.deployname
            details << ui.color('Host name', :bold, :blue)
            details << role.hostname
            unless role.sshport.nil?
              details << ui.color('SSH port', :bold, :blue)
              details << role.sshport
            end
            unless role.winrmport.nil?
              details << ui.color('WinRM port', :bold, :blue)
              details << role.winrmport
            end
            details << ui.color('Public IP', :bold, :blue)
            details << role.publicipaddress
            puts ui.list(details, :columns_across, 2)
            if role.tcpports.length > 0 || role.udpports.length > 0
              details.clear
              details << ui.color('Ports open', :bold, :blue)
              details << ui.color('Local port', :bold, :blue)
              details << ui.color('IP', :bold, :blue)
              details << ui.color('Public port', :bold, :blue)
              if role.tcpports.length > 0
                role.tcpports.each do |port|
                  details << 'tcp'
                  details << port['LocalPort']
                  details << port['Vip']
                  details << port['PublicPort']
                end
              end
              if role.udpports.length > 0
                role.udpports.each do |port|
                  details << 'udp'
                  details << port['LocalPort']
                  details << port['Vip']
                  details << port['PublicPort']
                end
              end
              puts ui.list(details, :columns_across, 4)
            end
          end
        end
      end
    end
  end
end
