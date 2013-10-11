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
require 'securerandom'
class Azure
  class Roles
    include AzureUtility
    attr_accessor :connection, :roles
    def initialize(connection)
      @connection = connection
      @roles = nil
    end
    # do not use this unless you want a list of all roles(vms) in your subscription
    def all
      @roles = Array.new
      @connection.deploys.all.each do |deploy|
        deploy.roles.each do |role|
          @roles << role
        end
      end
      @roles
    end

    def find_roles_within_hostedservice(hostedservicename)
      host = @connection.hosts.find(hostedservicename)
      (host) ? host.roles : nil # nil says invalid hosted service
    end

    def find_in_hosted_service(role_name, hostedservicename)
      host = @connection.hosts.find(hostedservicename)
      return nil if host.nil?
      host.find_role(role_name)
    end

    def find(role_name, params= nil)
      if params && params[:azure_dns_name]
        return find_in_hosted_service(role_name, params[:azure_dns_name])
      end

      all if @roles == nil

      # TODO - optimize this lookup
      @roles.each do |role|
        if(role.name == role_name)
          return role
        end
      end
      nil
    end

    def alone_on_hostedservice(found_role)
      roles = find_roles_within_hostedservice(found_role.hostedservicename)
      if roles && roles.length > 1
        return false
      end
      return true
    end

    def exists?(name)
      find(name) != nil
    end

    def delete(name, params)
      role = find(name)
      if role != nil
        if alone_on_hostedservice(role)
          servicecall = "hostedservices/#{role.hostedservicename}/deployments" +
          "/#{role.deployname}"
        else
          servicecall = "hostedservices/#{role.hostedservicename}/deployments" +
          "/#{role.deployname}/roles/#{role.name}"
        end

        roleXML = nil

        unless params[:preserve_azure_os_disk]
            roleXML = @connection.query_azure(servicecall, "get")
        end

        @connection.query_azure(servicecall, "delete")
        # delete role from local cache as well.
        @connection.hosts.find(role.hostedservicename).delete_role(role)
        @roles.delete(role) if @roles

        unless params[:preserve_azure_dns_name]
          unless params[:azure_dns_name].nil?
            roles_using_same_service = find_roles_within_hostedservice(params[:azure_dns_name])
            if roles_using_same_service.size <= 1
              servicecall = "hostedservices/" + params[:azure_dns_name]
              @connection.query_azure(servicecall, "delete")
            end
          end
        end

        unless params[:preserve_azure_os_disk]
          osdisk = roleXML.css(roleXML, 'OSVirtualHardDisk')
          disk_name = xml_content(osdisk, 'DiskName')
          servicecall = "disks/#{disk_name}"
          storage_account = @connection.query_azure(servicecall, "get")

          # OS Disk can only be deleted if it is detached from the VM.
          # So Iteratively check for disk detachment from the VM while waiting for 5 minutes ,
          # exit otherwise after 12 attempts.
          for attempt in 0..12
             break if @connection.query_azure(servicecall, "get").search("AttachedTo").text == ""
             if attempt == 12 then puts "The associated disk could not be deleted due to time out." else sleep 25 end
          end

          unless params[:preserve_azure_vhd]
           @connection.query_azure(servicecall, 'delete', '', 'comp=media')
          else
            @connection.query_azure(servicecall, 'delete')
          end

          if params[:delete_azure_storage_account]
            storage_account_name = xml_content(storage_account, "MediaLink")
            storage_account_name = storage_account_name.gsub("http://", "").gsub(/.blob(.*)$/, "")

            begin
              @connection.query_azure("storageservices/#{storage_account_name}", "delete")
            rescue Exception => ex
              ui.warn("#{ex.message}")
              ui.warn("#{ex.backtrace.join("\n")}")
            end

          end

        end


      end
    end

  end

  class Role
    include AzureUtility
    attr_accessor :connection, :name, :status, :size, :ipaddress, :publicipaddress
    attr_accessor :sshport, :hostedservicename, :deployname
    attr_accessor :winrmport
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
      @publicipaddress = xml_content(endpoints[0], 'Vip') if !endpoints.empty?
      endpoints.each do |endpoint|
        if xml_content(endpoint, 'Name').downcase == 'ssh'
          @sshport = xml_content(endpoint, 'PublicPort')
        elsif xml_content(endpoint, 'Name').downcase == 'winrm'
          @winrmport = xml_content(endpoint, 'PublicPort')
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
          xml.RoleName {xml.text params[:azure_vm_name]}
          xml.OsVersion('i:nil' => 'true')
          xml.RoleType 'PersistentVMRole'
          xml.ConfigurationSets {
            if params[:os_type] == 'Linux'

              xml.ConfigurationSet('i:type' => 'LinuxProvisioningConfigurationSet') {
              xml.ConfigurationSetType 'LinuxProvisioningConfiguration'
              xml.HostName params[:azure_vm_name]
              xml.UserName params[:ssh_user]
              unless params[:identity_file].nil?
                xml.DisableSshPasswordAuthentication 'true'
                xml.SSH {
                   xml.PublicKeys {
                     xml.PublicKey {
                       xml.Fingerprint params[:fingerprint]
                       xml.Path '/home/' + params[:ssh_user] + '/.ssh/authorized_keys'
                     }
                   }
                }
              else
                xml.UserPassword params[:ssh_password]
                xml.DisableSshPasswordAuthentication 'false'
              end
              }
            elsif params[:os_type] == 'Windows'
              xml.ConfigurationSet('i:type' => 'WindowsProvisioningConfigurationSet') {
              xml.ConfigurationSetType 'WindowsProvisioningConfiguration'
              xml.ComputerName params[:azure_vm_name]
              xml.AdminPassword params[:admin_password]
              xml.ResetPasswordOnFirstLogon 'false'
              xml.EnableAutomaticUpdates 'false'
              if params[:bootstrap_proto] == "winrm"
                xml.AdminUsername params[:winrm_user]
              else
                xml.AdminUsername params[:ssh_user]
              end
              }
            end

          xml.ConfigurationSet('i:type' => 'NetworkConfigurationSet') {
            xml.ConfigurationSetType 'NetworkConfiguration'
            xml.InputEndpoints {
              if params[:bootstrap_proto].downcase == 'ssh'
                xml.InputEndpoint {
                xml.LocalPort '22'
                xml.Name 'SSH'
                xml.Port params[:port]
                xml.Protocol 'TCP'
              }
              elsif params[:bootstrap_proto].downcase == 'winrm' and params[:os_type] == 'Windows'
                xml.InputEndpoint {
                  xml.LocalPort '5985'
                  xml.Name 'WinRM'
                  xml.Port params[:port]
                  xml.Protocol 'TCP'
                }
              end

            if params[:tcp_endpoints]
              params[:tcp_endpoints].split(',').each do |endpoint|
                ports = endpoint.split(':')
                if !(ports.length > 1 && ports[1] == params[:port] || ports.length == 1 && ports[0] == params[:port])
                  xml.InputEndpoint {
                    xml.LocalPort ports[0]
                    xml.Name 'tcpport_' + ports[0] + '_' + params[:azure_vm_name]
                    if ports.length > 1
                      xml.Port ports[1]
                    else
                      xml.Port ports[0]
                    end
                    xml.Protocol 'TCP'
                  }
                else
                  warn_message = ports.length > 1 ? "#{ports.join(':')} because this ports are" : "#{ports[0]} because this port is"
                  puts("Skipping tcp-endpoints: #{warn_message} already in use by ssh/winrm endpoint in current VM.")
                end
              end
            end

            if params[:udp_endpoints]
              params[:udp_endpoints].split(',').each do |endpoint|
                ports = endpoint.split(':')
                xml.InputEndpoint {
                  xml.LocalPort ports[0]
                  xml.Name 'udpport_' + ports[0] + '_' + params[:azure_vm_name]
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
            if params[:azure_subnet_name]
              xml.SubnetNames {
                xml.SubnetName params[:azure_subnet_name]
              }
            end
          }
          }
          if params[:azure_availability_set]
            xml.AvailabilitySetName params[:azure_availability_set]
          end
          xml.Label Base64.encode64(params[:azure_vm_name]).strip
          xml.OSVirtualHardDisk {
            disk_name = params[:azure_os_disk_name] || "disk_" + SecureRandom.uuid
            xml.DiskName disk_name
            xml.MediaLink 'http://' + params[:azure_storage_account] + '.blob.core.windows.net/vhds/' + disk_name + '.vhd'
            xml.SourceImageName params[:azure_source_image]
          }
          xml.RoleSize params[:azure_vm_size]
        }
      end
      builder.doc
    end
    def create(params, roleXML)
      servicecall = "hostedservices/#{params[:azure_dns_name]}/deployments" +
      "/#{params['deploy_name']}/roles"
      @connection.query_azure(servicecall, "post", roleXML.to_xml)
    end
  end
end
