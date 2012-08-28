#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
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

class Azure
  class Roles
    include AzureUtility
    attr_accessor :connection, :roles
    def initialize(connection)
      @connection = connection
      @roles = nil
    end
    def all
      @roles = Array.new
      @connection.deploys.all.each do |deploy|
        deploy.roles.each do |role|
          @roles << role
        end
      end
      @roles
    end
    def find(name)
      if @roles == nil
        all
      end
      @roles.each do |role|
        if(role.name == name)
          return role 
        end
      end
      nil   
    end
    def alone_on_host(name)
      found_role = find(name)
      @roles.each do |role|
        if (role.name != found_role.name && 
            role.deployname == found_role.deployname && 
            role.hostedservicename == found_role.hostedservicename)
          return false;
        end
      end
      true
    end
    def exists(name)
      find(name) != nil
    end
    def delete(name, params)
      role = find(name)
      if role != nil
        if alone_on_host(name)
          servicecall = "hostedservices/#{role.hostedservicename}/deployments" +
          "/#{role.deployname}"
        else
          servicecall = "hostedservices/#{role.hostedservicename}/deployments" +
          "/#{role.deployname}/roles/#{role.name}"
        end
        roleXML = nil
        if params[:purge_os_disk]
            roleXML = @connection.query_azure(servicecall, "get")
        end
        @connection.query_azure(servicecall, "delete") 

        if params[:purge_os_disk]
          osdisk = roleXML.css(roleXML, 'OSVirtualHardDisk')
          disk_name = xml_content(osdisk, 'DiskName')
          servicecall = "disks/#{disk_name}"
          @connection.query_azure(servicecall, "delete")
        end
      end
    end
  end
  class Role
    include AzureUtility
    attr_accessor :connection, :name, :status, :size, :ipaddress
    attr_accessor :sshport, :sshipaddress, :hostedservicename, :deployname
    attr_accessor :winrmport, :winrmipaddress
    attr_accessor :hostname, :tcpports, :udpports

    def initialize(connection)
      @connection = connection
    end
    def parse(roleXML, hostedservicename, deployname)
      @name = xml_content(roleXML, 'RoleName')
      @status = xml_content(roleXML, 'InstanceStatus')
      @size = xml_content(roleXML, 'InstanceSize')
      @ipaddress = xml_content(roleXML, 'IpAddress')
      @hostname = xml_content(roleXML, 'HostName')
      @hostedservicename = hostedservicename
      @deployname = deployname
      @tcpports = Array.new
      @udpports = Array.new
      
      endpoints = roleXML.css('InstanceEndpoint')
      endpoints.each do |endpoint|
        if xml_content(endpoint, 'Name').downcase == 'ssh'
          @sshport = xml_content(endpoint, 'PublicPort')
          @sshipaddress = xml_content(endpoint, 'Vip')
        elsif xml_content(endpoint, 'Name').downcase == 'winrm'
          @winrmport = xml_content(endpoint, 'PublicPort')
          @winrmipaddress = xml_content(endpoint, 'Vip')
        else
          hash = Hash.new
          hash['Name'] = xml_content(endpoint, 'Name')
          hash['Vip'] = xml_content(endpoint, 'Vip')
          hash['PublicPort'] = xml_content(endpoint, 'PublicPort')
          hash['LocalPort'] = xml_content(endpoint, 'LocalPort')
          if xml_content(endpoint, 'Protocol') == 'tcp'
            @tcpports << hash
          else # == 'udp'
            @udpports << hash
          end
        end
      end
    end
    def setup(params)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.PersistentVMRole(
          'xmlns'=>'http://schemas.microsoft.com/windowsazure',
          'xmlns:i'=>'http://www.w3.org/2001/XMLSchema-instance'
        ) {
          xml.RoleName {xml.text params[:role_name]}
          xml.OsVersion('i:nil' => 'true')
          xml.RoleType 'PersistentVMRole'
          xml.ConfigurationSets {
            if params[:os_type] == 'Linux'
              
              xml.ConfigurationSet('i:type' => 'LinuxProvisioningConfigurationSet') {
              xml.ConfigurationSetType 'LinuxProvisioningConfiguration'
              xml.HostName params[:host_name] 
              xml.UserName params[:ssh_user]
              xml.UserPassword params[:ssh_password]
              xml.DisableSshPasswordAuthentication 'false'
              }
            elsif params[:os_type] == 'Windows'
              xml.ConfigurationSet('i:type' => 'WindowsProvisioningConfigurationSet') {
              xml.ConfigurationSetType 'WindowsProvisioningConfiguration'
              xml.ComputerName params[:host_name] 
              xml.AdminPassword params[:admin_password]
              xml.ResetPasswordOnFirstLogon 'false'
              xml.EnableAutomaticUpdates 'false'

              }
            end

          xml.ConfigurationSet('i:type' => 'NetworkConfigurationSet') {
            xml.ConfigurationSetType 'NetworkConfiguration'
            xml.InputEndpoints {
              if params[:bootstrap_proto].downcase == 'ssh'
                xml.InputEndpoint {
                xml.LocalPort '22' 
                xml.Name 'SSH'
                xml.Port '22'
                xml.Protocol 'TCP'
              }
              elsif params[:bootstrap_proto].downcase == 'winrm' and params[:os_type] == 'Windows'
                xml.InputEndpoint {
                  xml.LocalPort '5985'
                  xml.Name 'WinRM'
                  xml.Port '5985'
                  xml.Protocol 'TCP'
                }
              end
 
            if params[:tcp_endpoints]
              params[:tcp_endpoints].split(',').each do |endpoint|
                ports = endpoint.split(':')
                xml.InputEndpoint {
                  xml.LocalPort ports[0]
                  xml.Name 'tcpport_' + ports[0] + '_' + params[:host_name]
                  if ports.length > 1
                    xml.Port ports[1]
                  else
                    xml.Port ports[0]
                  end 
                  xml.Protocol 'TCP'
                }
              end
            end
            if params[:udp_endpoints]
              params[:udp_endpoints].split(',').each do |endpoint|
                ports = endpoint.split(':')
                xml.InputEndpoint {
                  xml.LocalPort ports[0]
                  xml.Name 'udpport_' + ports[0] + '_' + params[:host_name]
                  if ports.length > 1
                    xml.Port ports[1]
                  else
                    xml.Port ports[0]
                  end 
                  xml.Protocol 'UDP'
                }
              end
            end
            }
          }
          }
          xml.Label Base64.encode64(params[:role_name]).strip
          xml.OSVirtualHardDisk {
            xml.MediaLink 'http://' + params[:storage_account] + '.blob.core.windows.net/vhds/' + (params[:os_disk_name] || Time.now.strftime('disk_%Y_%m_%d_%H_%M')) + '.vhd'
            xml.SourceImageName params[:source_image]
          }
          xml.RoleSize params[:role_size]
        }
      end 
      builder.doc
    end
    def create(params, roleXML)
      servicecall = "hostedservices/#{params[:hosted_service_name]}/deployments" +
      "/#{params['deploy_name']}/roles"
      @connection.query_azure(servicecall, "post", roleXML.to_xml) 
    end
  end
end
