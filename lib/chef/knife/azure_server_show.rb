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
         :long => "--resource-group RESOURCE_NAME",
         :description => "Optional. Specifies the resource group of server. If not specified then server name is considered as resource group"
       

      def run
        $stdout.sync = true
        if(locate_config_value(:azure_api_mode) == "asm")
          validate_asm_keys!
        elsif(locate_config_value(:azure_api_mode) == "arm")
          validate_arm_keys!
          
          if locate_config_value(:resource_group)   
            resource_group = locate_config_value(:resource_group)
          else
            resource_group = @name_args[0]
          end 
          
          service.show_server(@name_args[0], resource_group)

        end  


        if(locate_config_value(:azure_api_mode) == "asm") 
        @name_args.each do |name|
          role = service.show_server name
          puts ''
          if (role)
            details = Array.new
            details << ui.color('Role name', :bold, :cyan)
            details << role.name
            details << ui.color('Status', :bold, :cyan)
            details << role.status
            details << ui.color('Size', :bold, :cyan)
            details << role.size
            details << ui.color('Hosted service name', :bold, :cyan)
            details << role.hostedservicename
            details << ui.color('Deployment name', :bold, :cyan)
            details << role.deployname
            details << ui.color('Host name', :bold, :cyan)
            details << role.hostname
            unless role.sshport.nil?
              details << ui.color('SSH port', :bold, :cyan)
              details << role.sshport
            end
            unless role.winrmport.nil?
              details << ui.color('WinRM port', :bold, :cyan)
              details << role.winrmport
            end
            details << ui.color('Public IP', :bold, :cyan)
            details << role.publicipaddress
            unless role.thumbprint.empty?
              details << ui.color('Thumbprint', :bold, :cyan)
              details << role.thumbprint
            end
            puts ui.list(details, :columns_across, 2)
            if role.tcpports.length > 0 || role.udpports.length > 0
              details.clear
              details << ui.color('Ports open', :bold, :cyan)
              details << ui.color('Local port', :bold, :cyan)
              details << ui.color('IP', :bold, :cyan)
              details << ui.color('Public port', :bold, :cyan)
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
      end #

      
      end
    end
  end
end
