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

    def delete(params)
      role = find(params[:name])
      if role != nil
        roleXML = nil
        roleXML = @connection.query_azure("hostedservices/#{role.hostedservicename}", "get", "", "embed-detail=true")
        osdisk = roleXML.css(roleXML, 'OSVirtualHardDisk')
        disk_name = xml_content(osdisk, 'DiskName')
        storage_account_name = xml_content(osdisk, 'MediaLink').gsub("http://", "").gsub(/.blob(.*)$/, "")

        if !params[:preserve_azure_os_disk] && !params[:preserve_azure_vhd] && !params[:wait]
          # default compmedia = true. So, it deletes role and associated resources
          check_and_delete_role_and_resources(params, role)
        else
          # compmedia = false. So, it deletes only role and not associated resources
          check_and_delete_role_and_resources(params, role, compmedia=false)
          check_and_delete_disks(params, disk_name)
          check_and_delete_service(params)
        end
        check_and_delete_storage(params, disk_name, storage_account_name)
      end
    end

    def check_and_delete_role_and_resources(params, role, compmedia=true)
      if alone_on_hostedservice(role)
        if !params[:preserve_azure_dns_name] && compmedia
          servicecall = "hostedservices/#{role.hostedservicename}"
        else
          servicecall = "hostedservices/#{role.hostedservicename}/deployments/#{role.deployname}"
        end
      else
        servicecall = "hostedservices/#{role.hostedservicename}/deployments" +
        "/#{role.deployname}/roles/#{role.name}"
      end
      if compmedia
        @connection.query_azure(servicecall, "delete", "", "comp=media", wait=params[:wait])
      else
        @connection.query_azure(servicecall, "delete")
      end

      # delete role from local cache as well.
      @connection.hosts.find(role.hostedservicename).delete_role(role)
      @roles.delete(role) if @roles
    end

    def check_and_delete_disks(params, disk_name)
      servicecall = "disks/#{disk_name}"
      unless params[:preserve_azure_os_disk]
        # OS Disk can only be deleted if it is detached from the VM.
        # So Iteratively check for disk detachment from the VM while waiting for 5 minutes ,
        # exit otherwise after 12 attempts.
        for attempt in 0..12
           break if @connection.query_azure(servicecall, "get").search("AttachedTo").text == ""
           if attempt == 12 then puts "The associated disk could not be deleted due to time out." else sleep 25 end
        end
        unless params[:preserve_azure_vhd]
          @connection.query_azure(servicecall, 'delete', '', 'comp=media', wait=params[:wait])
        else
          @connection.query_azure(servicecall, 'delete')
        end
      end
    end

    def check_and_delete_service(params)
      unless params[:preserve_azure_dns_name]
        unless params[:azure_dns_name].nil?
          roles_using_same_service = find_roles_within_hostedservice(params[:azure_dns_name])
          if roles_using_same_service.size <= 1
            servicecall = "hostedservices/" + params[:azure_dns_name]
            @connection.query_azure(servicecall, "delete")
          end
        end
      end
    end

    def check_and_delete_storage(params, disk_name, storage_account_name)
     if params[:delete_azure_storage_account]
        # Iteratively check for disk deletion
        for attempt in 0..12
           break unless @connection.query_azure("disks").search("Name").text.include?(disk_name)
           if attempt == 12 then puts "The associated disk could not be deleted due to time out." else sleep 25 end
        end
        begin
          @connection.query_azure("storageservices/#{storage_account_name}", "delete")
        rescue Exception => ex
          ui.warn("#{ex.message}")
          ui.warn("#{ex.backtrace.join("\n")}")
        end
      end
    end

    private :check_and_delete_role_and_resources, :check_and_delete_disks, :check_and_delete_service, :check_and_delete_storage

  end

  class Role
    include AzureUtility
    attr_accessor :connection, :name, :status, :size, :ipaddress, :publicipaddress
    attr_accessor :sshport, :hostedservicename, :deployname, :thumbprint
    attr_accessor :winrmport
    attr_accessor :hostname, :tcpports, :udpports

      TCP_ENDPOINTS_MAPPING = { '3389' => 'Remote Desktop',
                              '5986' => 'PowerShell',
                              '22' => 'SSH',
                              '21' => 'FTP',
                              '25' => 'SMTP',
                              '53' => 'DNS',
                              '80' => 'HTTP',
                              '110' => 'POP3',
                              '143' => 'IMAP',
                              '389' => 'LDAP',
                              '443' => 'HTTPs',
                              '587' => 'SMTPS',
                              '995' => 'POP3S',
                              '993' => 'IMAPS',
                              '1433' => 'MSSQL',
                              '3306' => 'MySQL'
                              }

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
      @thumbprint = fetch_thumbprint
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

    # Expects endpoint_param_string to be in the form {localport}:{publicport}:{lb_set_name}:{lb_probe_path}
    # Only localport is mandatory.
    def parse_endpoint_from_params(protocol, azure_vm_name, endpoint_param_string)
      fields = endpoint_param_string.split(':').map(&:strip)
      hash = {}
      hash['LocalPort'] = fields[0]
      hash['Port'] = fields[1] || fields[0]
      hash['LoadBalancerName'] = fields[2] if fields[2] != 'EXTERNAL' # TODO: hackity hack.. Shouldn't use magic words.
      hash['LoadBalancedEndpointSetName'] = fields[3]
      hash['Protocol'] = protocol
      if TCP_ENDPOINTS_MAPPING.include?(hash['Port']) && protocol == 'TCP'
        hash['Name'] = TCP_ENDPOINTS_MAPPING[hash['Port']]
      else
        hash['Name'] = "#{protocol}Endpoint_chef_#{fields[0]}"
      end
      if fields[2]
        hash['LoadBalancerProbe'] = {}
        hash['LoadBalancerProbe']['Path'] = fields[4]
        hash['LoadBalancerProbe']['Port'] = fields[0]
        hash['LoadBalancerProbe']['Protocol'] = fields[4] ? 'HTTP' : protocol
      end
      hash
    end

    def find_deploy(params)
      @connection.hosts.find(params[:azure_dns_name]).deploys[0] # TODO this relies on the 'production only' bug.
    end

    def add_endpoints_to_xml(xml, endpoints, params)
      existing_endpoints = find_deploy(params).input_endpoints

      endpoints.each do |ep|

        if existing_endpoints
          existing_endpoints.each do |eep|
            ep = eep if eep['LoadBalancedEndpointSetName'] && ep['LoadBalancedEndpointSetName'] && ( eep['LoadBalancedEndpointSetName'] == ep['LoadBalancedEndpointSetName'] )
          end
        end

        if ep['Port'] == params[:port] && ep['Protocol'].downcase == 'tcp'
          puts("Skipping tcp-endpoints: #{ep['LocalPort']} because this port is already in use by ssh/winrm endpoint in current VM.")
          next
        end

        xml.InputEndpoint {
          xml.LoadBalancedEndpointSetName ep['LoadBalancedEndpointSetName'] if ep['LoadBalancedEndpointSetName']
          xml.LocalPort ep['LocalPort']
          xml.Name ep['Name']
          xml.Port ep['Port']
          if ep['LoadBalancerProbe']
            xml.LoadBalancerProbe {
              xml.Path ep['LoadBalancerProbe']['Path'] if ep['LoadBalancerProbe']['Path']
              xml.Port ep['LoadBalancerProbe']['Port']
              xml.Protocol ep['LoadBalancerProbe']['Protocol']
              xml.IntervalInSeconds ep['LoadBalancerProbe']['IntervalInSeconds'] if ep['LoadBalancerProbe']['IntervalInSeconds']
              xml.TimeoutInSeconds ep['LoadBalancerProbe']['TimeoutInSeconds'] if ep['LoadBalancerProbe']['TimeoutInSeconds']
            }
          end
          xml.Protocol ep['Protocol']
          xml.EnableDirectServerReturn ep['EnableDirectServerReturn'] if ep['EnableDirectServerReturn']
          xml.LoadBalancerName ep['LoadBalancerName'] if ep['LoadBalancerName']
          xml.IdleTimeoutInMinutes ep['IdleTimeoutInMinutes'] if ep['IdleTimeoutInMinutes']
        }
      end
    end

    def fetch_thumbprint
      query_result = connection.query_azure("hostedservices/#{@hostedservicename}/deployments/#{@hostedservicename}/roles/#{@name}")
      query_result.at_css("DefaultWinRmCertificateThumbprint").nil? ? '' : query_result.at_css("DefaultWinRmCertificateThumbprint").text
    end

    def setup(params)
      azure_user_domain_name = params[:azure_user_domain_name] || params[:azure_domain_name]
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
                         xml.Fingerprint params[:fingerprint].to_s.upcase
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
                if params[:azure_domain_name]
                  xml.DomainJoin {
                    xml.Credentials {
                      xml.Domain azure_user_domain_name
                     xml.Username params[:azure_domain_user]
                    xml.Password params[:azure_domain_passwd]
                   }
                   xml.JoinDomain params[:azure_domain_name]
                   xml.MachineObjectOU params[:azure_domain_ou_dn] if params[:azure_domain_ou_dn]
                  }
                end
                  if params[:bootstrap_proto].downcase == 'winrm'
                    if params[:ssl_cert_fingerprint]
                      xml.StoredCertificateSettings {
                        xml.CertificateSetting {
                          xml.StoreLocation "LocalMachine"
                          xml.StoreName "My"
                          xml.Thumbprint params[:ssl_cert_fingerprint]
                        }
                      }
                    end
                    xml.WinRM {
                      xml.Listeners {
                       if params[:winrm_transport] == "ssl" || params[:ssl_cert_fingerprint]
                        xml.Listener {
                          xml.CertificateThumbprint params[:ssl_cert_fingerprint] if params[:ssl_cert_fingerprint]
                          xml.Protocol 'Https'
                        }
                        else
                        xml.Listener {
                          xml.Protocol 'Http'
                        }
                        end
                      }
                    }
                  end
                xml.AdminUsername params[:winrm_user]
                if params[:bootstrap_proto].downcase == 'winrm' && (params[:winrm_max_timeout] || params[:winrm_max_memoryPerShell])
                  xml.AdditionalUnattendContent {
                    xml.Passes {
                      xml.UnattendPass {
                        xml.PassName 'oobeSystem'
                        xml.Components {
                          xml.UnattendComponent {
                            xml.ComponentName 'Microsoft-Windows-Shell-Setup'
                            xml.ComponentSettings {
                              xml.ComponentSetting {
                                xml.SettingName 'AutoLogon'
                                xml.Content Base64.encode64(
                                  Nokogiri::XML::Builder.new do |auto_logon_xml|
                                    auto_logon_xml.AutoLogon {
                                      auto_logon_xml.Username params[:winrm_user]
                                      auto_logon_xml.Password {
                                        auto_logon_xml.Value params[:admin_password]
                                        auto_logon_xml.PlainText true
                                      }
                                      auto_logon_xml.LogonCount 1
                                      auto_logon_xml.Enabled true
                                    }
                                  end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
                                ).strip
                              }
                              xml.ComponentSetting {
                                xml.SettingName 'FirstLogonCommands'
                                xml.Content Base64.encode64(
                                  Nokogiri::XML::Builder.new do |first_logon_xml|
                                    first_logon_xml.FirstLogonCommands {
                                      if params[:winrm_max_timeout]
                                        first_logon_xml.SynchronousCommand('wcm:action' => 'add') {
                                          first_logon_xml.Order 1
                                          first_logon_xml.CommandLine "cmd.exe /c winrm set winrm/config @{MaxTimeoutms=\"#{params[:winrm_max_timeout]}\"}"
                                          first_logon_xml.Description "Bump WinRM max timeout to #{params[:winrm_max_timeout]} milliseconds"
                                        }
                                      end

                                      if params[:winrm_max_memoryPerShell]
                                        first_logon_xml.SynchronousCommand('wcm:action' => 'add') {
                                          first_logon_xml.Order 2
                                          first_logon_xml.CommandLine "cmd.exe /c winrm set winrm/config/winrs @{MaxMemoryPerShellMB=\"#{params[:winrm_max_memoryPerShell]}\"}"
                                          first_logon_xml.Description "Bump WinRM max memory per shell to #{params[:winrm_max_memoryPerShell]} MB"
                                        }
                                      end
                                    }
                                  end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
                                ).strip
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                end
              }
            end

            xml.ConfigurationSet('i:type' => 'NetworkConfigurationSet') {
              xml.ConfigurationSetType 'NetworkConfiguration'
              xml.InputEndpoints {

                #1. bootstrap_proto = 'winrm' for windows => Set winrm port
                #2. bootstrap_proto = 'ssh' for windows and linux => Set ssh port
                #3. bootstrap_proto = 'cloud-api' for windows and linux => Set no port
                if params[:os_type] == 'Windows' and params[:bootstrap_proto].downcase == 'winrm'
                  xml.InputEndpoint {
                  if params[:winrm_transport] == "ssl"
                    xml.LocalPort '5986'
                  else
                    xml.LocalPort '5985'
                  end
                  xml.Name 'WinRM'
                  xml.Port params[:port]
                  xml.Protocol 'TCP'
                }
                elsif(params[:bootstrap_proto].downcase == 'ssh')
                  xml.InputEndpoint {
                  xml.LocalPort '22'
                  xml.Name 'SSH'
                  xml.Port params[:port]
                  xml.Protocol 'TCP'
                }
                end
                all_endpoints = Array.new

                if params[:tcp_endpoints]
                  params[:tcp_endpoints].split(',').map(&:strip).each do |endpoint|
                    all_endpoints << parse_endpoint_from_params('TCP', params[:azure_vm_name], endpoint)
                  end
                end
                if params[:udp_endpoints]
                  params[:udp_endpoints].split(',').map(&:strip).each do |endpoint|
                    all_endpoints << parse_endpoint_from_params('UDP', params[:azure_vm_name], endpoint)
                  end
                end
                add_endpoints_to_xml(xml, all_endpoints, params) if all_endpoints.any?
              }
              if params[:azure_subnet_name]
                xml.SubnetNames {
                  xml.SubnetName params[:azure_subnet_name]
                }
              end
            }
          }

          # Azure resource extension support
          if params[:bootstrap_proto] == 'cloud-api'
            xml.ResourceExtensionReferences {
              xml.ResourceExtensionReference {
                xml.ReferenceName params[:chef_extension]
                xml.Publisher params[:chef_extension_publisher]
                xml.Name params[:chef_extension]
                xml.Version params[:chef_extension_version]
                xml.ResourceExtensionParameterValues {
                  if params[:chef_extension_public_param]
                    xml.ResourceExtensionParameterValue {
                      xml.Key "PublicParams"
                      xml.Value params[:chef_extension_public_param]
                      xml.Type "Public"
                    }
                  end
                  if params[:chef_extension_private_param]
                    xml.ResourceExtensionParameterValue {
                      xml.Key "PrivateParams"
                      xml.Value params[:chef_extension_private_param]
                      xml.Type "Private"
                    }
                  end
                }
                xml.State "Enable"
              }
            }
          end

          if params[:azure_availability_set]
            xml.AvailabilitySetName params[:azure_availability_set]
          end

          xml.VMImageName params[:azure_source_image] if params[:is_vm_image]

          xml.Label Base64.encode64(params[:azure_vm_name]).strip

          #OSVirtualHardDisk not required in case azure_source_image is a VMImage
          unless(params[:is_vm_image])
            xml.OSVirtualHardDisk {
              disk_name = params[:azure_os_disk_name] || "disk_" + SecureRandom.uuid
              xml.DiskName disk_name
              domain_suffix = params[:azure_api_host_name].scan(/core.*/)[0]
              xml.MediaLink 'http://' + params[:azure_storage_account] + '.blob.' + domain_suffix + '/vhds/' + disk_name + '.vhd'
              xml.SourceImageName params[:azure_source_image]
            }
          end

          xml.RoleSize params[:azure_vm_size]
          xml.ProvisionGuestAgent true if params[:bootstrap_proto] == 'cloud-api'
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
