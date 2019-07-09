#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Copyright:: Copyright 2010-2019, Chef Software Inc.
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

require "securerandom"
require "azure/service_management/utility"

module Azure
  class Roles
    include AzureUtility
    attr_accessor :connection, :roles
    def initialize(connection)
      @connection = connection
      @roles = nil
    end

    # do not use this unless you want a list of all roles(vms) in your subscription
    def all
      @roles = []
      @connection.deploys.all.each do |deploy|
        deploy.roles.each do |role|
          @roles << role
        end
      end
      @roles
    end

    def find_roles_within_hostedservice(hostedservicename)
      host = @connection.hosts.find(hostedservicename)
      host ? host.roles : nil # nil says invalid hosted service
    end

    def find_in_hosted_service(role_name, hostedservicename)
      host = @connection.hosts.find(hostedservicename)
      return nil if host.nil?

      host.find_role(role_name)
    end

    def find(role_name, params = nil)
      if params && params[:azure_dns_name]
        return find_in_hosted_service(role_name, params[:azure_dns_name])
      end

      all if @roles.nil?

      # TODO: - optimize this lookup
      @roles.each do |role|
        return role if role.name == role_name
      end
      nil
    end

    def alone_on_hostedservice(found_role)
      roles = find_roles_within_hostedservice(found_role.hostedservicename)
      return false if roles && roles.length > 1

      true
    end

    def exists?(name)
      find(name) != nil
    end

    def delete(params)
      role = find(params[:name])
      unless role.nil?
        roleXML = nil
        roleXML = @connection.query_azure("hostedservices/#{role.hostedservicename}", "get", "", "embed-detail=true")
        osdisk = roleXML.css(roleXML, "OSVirtualHardDisk")
        disk_name = xml_content(osdisk, "DiskName")
        storage_account_name = xml_content(osdisk, "MediaLink").gsub("http://", "").gsub(/.blob(.*)$/, "")

        if !params[:preserve_azure_os_disk] && !params[:preserve_azure_vhd] && !params[:wait]
          # default compmedia = true. So, it deletes role and associated resources
          check_and_delete_role_and_resources(params, role)
        else
          # compmedia = false. So, it deletes only role and not associated resources
          check_and_delete_role_and_resources(params, role, compmedia = false)
          check_and_delete_disks(params, disk_name)
          check_and_delete_service(params)
        end
        check_and_delete_storage(params, disk_name, storage_account_name)
      end
    end

    def check_and_delete_role_and_resources(params, role, compmedia = true)
      if alone_on_hostedservice(role)
        if !params[:preserve_azure_dns_name] && compmedia
          servicecall = "hostedservices/#{role.hostedservicename}"
        else
          servicecall = "hostedservices/#{role.hostedservicename}/deployments/#{role.deployname}"
        end
      else
        servicecall = "hostedservices/#{role.hostedservicename}/deployments" \
                      "/#{role.deployname}/roles/#{role.name}"
      end
      if compmedia
        @connection.query_azure(servicecall, "delete", "", "comp=media", wait = params[:wait])
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

          attempt == 12 ? (puts "The associated disk could not be deleted due to time out.") : (sleep 25)
        end
        if params[:preserve_azure_vhd]
          @connection.query_azure(servicecall, "delete")
        else
          @connection.query_azure(servicecall, "delete", "", "comp=media", wait = params[:wait])
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

          attempt == 12 ? (puts "The associated disk could not be deleted due to time out.") : (sleep 25)
        end
        begin
          @connection.query_azure("storageservices/#{storage_account_name}", "delete")
        rescue Exception => ex
          ui.warn(ex.message.to_s)
          ui.warn(ex.backtrace.join("\n").to_s)
        end
       end
    end

    def update(name, params)
      role = Role.new(@connection)
      roleExtensionXml = role.setup_extension(params)
      role.update(name, params, roleExtensionXml)
    end

    private :check_and_delete_role_and_resources, :check_and_delete_disks, :check_and_delete_service, :check_and_delete_storage
  end

  class Role
    include AzureUtility
    attr_accessor :connection, :name, :status, :size, :ipaddress, :publicipaddress
    attr_accessor :sshport, :hostedservicename, :deployname, :thumbprint
    attr_accessor :winrmport
    attr_accessor :hostname, :tcpports, :udpports
    attr_accessor :role_xml, :os_type, :os_version

    TCP_ENDPOINTS_MAPPING = { "3389" => "Remote Desktop",
                              "5986" => "PowerShell",
                              "22" => "SSH",
                              "21" => "FTP",
                              "25" => "SMTP",
                              "53" => "DNS",
                              "80" => "HTTP",
                              "110" => "POP3",
                              "143" => "IMAP",
                              "389" => "LDAP",
                              "443" => "HTTPs",
                              "587" => "SMTPS",
                              "995" => "POP3S",
                              "993" => "IMAPS",
                              "1433" => "MSSQL",
                              "3306" => "MySQL" }.freeze

    def initialize(connection)
      @connection = connection
    end

    def parse(roleXML, hostedservicename, deployname)
      @name = xml_content(roleXML, "RoleName")
      @status = xml_content(roleXML, "InstanceStatus")
      @size = xml_content(roleXML, "InstanceSize")
      @ipaddress = xml_content(roleXML, "IpAddress")
      @hostname = xml_content(roleXML, "HostName")
      @hostedservicename = hostedservicename
      @deployname = deployname
      @thumbprint = fetch_thumbprint
      @tcpports = []
      @udpports = []

      endpoints = roleXML.css("InstanceEndpoint")
      @publicipaddress = xml_content(endpoints[0], "Vip") unless endpoints.empty?
      endpoints.each do |endpoint|
        if xml_content(endpoint, "Name").casecmp("ssh").zero?
          @sshport = xml_content(endpoint, "PublicPort")
        elsif xml_content(endpoint, "Name").casecmp("winrm").zero?
          @winrmport = xml_content(endpoint, "PublicPort")
        else
          hash = {}
          hash["Name"] = xml_content(endpoint, "Name")
          hash["Vip"] = xml_content(endpoint, "Vip")
          hash["PublicPort"] = xml_content(endpoint, "PublicPort")
          hash["LocalPort"] = xml_content(endpoint, "LocalPort")

          if xml_content(endpoint, "Protocol") == "tcp"
            @tcpports << hash
          else # == 'udp'
            @udpports << hash
          end
        end
      end
    end

    def parse_role_list_xml(roleListXML)
      @role_xml = roleListXML
      os_disk_xml = roleListXML.css("OSVirtualHardDisk")
      @os_type = xml_content(os_disk_xml, "OS")
      @os_version = xml_content(os_disk_xml, "SourceImageName")
    end

    # Expects endpoint_param_string to be in the form {localport}:{publicport}:{lb_set_name}:{lb_probe_path}
    # Only localport is mandatory.
    def parse_endpoint_from_params(protocol, _azure_vm_name, endpoint_param_string)
      fields = endpoint_param_string.split(":").map(&:strip)
      hash = {}
      hash["LocalPort"] = fields[0]
      hash["Port"] = fields[1] || fields[0]
      hash["LoadBalancerName"] = fields[2] if fields[2] != "EXTERNAL" # TODO: hackity hack.. Shouldn't use magic words.
      hash["LoadBalancedEndpointSetName"] = fields[3]
      hash["Protocol"] = protocol
      if TCP_ENDPOINTS_MAPPING.include?(hash["Port"]) && protocol == "TCP"
        hash["Name"] = TCP_ENDPOINTS_MAPPING[hash["Port"]]
      else
        hash["Name"] = "#{protocol}Endpoint_chef_#{fields[0]}"
      end
      if fields[2]
        hash["LoadBalancerProbe"] = {}
        hash["LoadBalancerProbe"]["Path"] = fields[4]
        hash["LoadBalancerProbe"]["Port"] = fields[0]
        hash["LoadBalancerProbe"]["Protocol"] = fields[4] ? "HTTP" : protocol
      end
      hash
    end

    def find_deploy(params)
      @connection.hosts.find(params[:azure_dns_name]).deploys[0] # TODO: this relies on the 'production only' bug.
    end

    def add_endpoints_to_xml(xml, endpoints, params)
      existing_endpoints = find_deploy(params).input_endpoints

      endpoints.each do |ep|
        if existing_endpoints
          existing_endpoints.each do |eep|
            ep = eep if eep["LoadBalancedEndpointSetName"] && ep["LoadBalancedEndpointSetName"] && (eep["LoadBalancedEndpointSetName"] == ep["LoadBalancedEndpointSetName"])
          end
        end

        if ep["Port"] == params[:port] && ep["Protocol"].casecmp("tcp").zero?
          puts("Skipping tcp-endpoints: #{ep["LocalPort"]} because this port is already in use by ssh/winrm endpoint in current VM.")
          next
        end

        xml.InputEndpoint do
          xml.LoadBalancedEndpointSetName ep["LoadBalancedEndpointSetName"] if ep["LoadBalancedEndpointSetName"]
          xml.LocalPort ep["LocalPort"]
          xml.Name ep["Name"]
          xml.Port ep["Port"]
          if ep["LoadBalancerProbe"]
            xml.LoadBalancerProbe do
              xml.Path ep["LoadBalancerProbe"]["Path"] if ep["LoadBalancerProbe"]["Path"]
              xml.Port ep["LoadBalancerProbe"]["Port"]
              xml.Protocol ep["LoadBalancerProbe"]["Protocol"]
              xml.IntervalInSeconds ep["LoadBalancerProbe"]["IntervalInSeconds"] if ep["LoadBalancerProbe"]["IntervalInSeconds"]
              xml.TimeoutInSeconds ep["LoadBalancerProbe"]["TimeoutInSeconds"] if ep["LoadBalancerProbe"]["TimeoutInSeconds"]
            end
          end
          xml.Protocol ep["Protocol"]
          xml.EnableDirectServerReturn ep["EnableDirectServerReturn"] if ep["EnableDirectServerReturn"]
          xml.LoadBalancerName ep["LoadBalancerName"] if ep["LoadBalancerName"]
          xml.IdleTimeoutInMinutes ep["IdleTimeoutInMinutes"] if ep["IdleTimeoutInMinutes"]
        end
      end
    end

    def fetch_thumbprint
      query_result = connection.query_azure("hostedservices/#{@hostedservicename}/deployments/#{@hostedservicename}/roles/#{@name}")
      query_result.at_css("DefaultWinRmCertificateThumbprint").nil? ? "" : query_result.at_css("DefaultWinRmCertificateThumbprint").text
    end

    def setup(params)
      azure_user_domain_name = params[:azure_user_domain_name] || params[:azure_domain_name]
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.PersistentVMRole(
          "xmlns" => "http://schemas.microsoft.com/windowsazure",
          "xmlns:i" => "http://www.w3.org/2001/XMLSchema-instance"
        ) do
          xml.RoleName { xml.text params[:azure_vm_name] }
          xml.OsVersion("i:nil" => "true")
          xml.RoleType "PersistentVMRole"

          xml.ConfigurationSets do
            if params[:os_type] == "Linux"
              xml.ConfigurationSet("i:type" => "LinuxProvisioningConfigurationSet") do
                xml.ConfigurationSetType "LinuxProvisioningConfiguration"
                xml.HostName params[:azure_vm_name]
                xml.UserName params[:connection_user]
                if params[:ssh_identity_file].nil?
                  xml.UserPassword params[:connection_password]
                  xml.DisableSshPasswordAuthentication "false"
                else
                  xml.DisableSshPasswordAuthentication "true"
                  xml.SSH do
                    xml.PublicKeys do
                      xml.PublicKey do
                        xml.Fingerprint params[:fingerprint].to_s.upcase
                        xml.Path "/home/" + params[:connection_user] + "/.ssh/authorized_keys"
                      end
                    end
                  end
                end
              end
            elsif params[:os_type] == "Windows"
              xml.ConfigurationSet("i:type" => "WindowsProvisioningConfigurationSet") do
                xml.ConfigurationSetType "WindowsProvisioningConfiguration"
                xml.ComputerName params[:azure_vm_name]
                xml.AdminPassword params[:admin_password]
                xml.ResetPasswordOnFirstLogon "false"
                xml.EnableAutomaticUpdates "false"
                if params[:azure_domain_name]
                  xml.DomainJoin do
                    xml.Credentials do
                      xml.Domain azure_user_domain_name
                      xml.Username params[:azure_domain_user]
                      xml.Password params[:azure_domain_passwd]
                    end
                    xml.JoinDomain params[:azure_domain_name]
                    xml.MachineObjectOU params[:azure_domain_ou_dn] if params[:azure_domain_ou_dn]
                  end
                end
                if params[:connection_protocol].casecmp("winrm").zero?
                  if params[:ssl_cert_fingerprint]
                    xml.StoredCertificateSettings do
                      xml.CertificateSetting do
                        xml.StoreLocation "LocalMachine"
                        xml.StoreName "My"
                        xml.Thumbprint params[:ssl_cert_fingerprint]
                      end
                    end
                  end
                  xml.WinRM do
                    xml.Listeners do
                      if params[:winrm_ssl] || params[:ssl_cert_fingerprint]
                        xml.Listener do
                          xml.CertificateThumbprint params[:ssl_cert_fingerprint] if params[:ssl_cert_fingerprint]
                          xml.Protocol "Https"
                        end
                      else
                        xml.Listener do
                          xml.Protocol "Http"
                        end
                       end
                    end
                  end
                end
                xml.AdminUsername params[:connection_user]
                if params[:connection_protocol].casecmp("winrm").zero? && (params[:winrm_max_timeout] || params[:winrm_max_memory_per_shell])
                  xml.AdditionalUnattendContent do
                    xml.Passes do
                      xml.UnattendPass do
                        xml.PassName "oobeSystem"
                        xml.Components do
                          xml.UnattendComponent do
                            xml.ComponentName "Microsoft-Windows-Shell-Setup"
                            xml.ComponentSettings do
                              xml.ComponentSetting do
                                xml.SettingName "AutoLogon"
                                xml.Content Base64.encode64(
                                  Nokogiri::XML::Builder.new do |auto_logon_xml|
                                    auto_logon_xml.AutoLogon do
                                      auto_logon_xml.Username params[:connection_user]
                                      auto_logon_xml.Password do
                                        auto_logon_xml.Value params[:admin_password]
                                        auto_logon_xml.PlainText true
                                      end
                                      auto_logon_xml.LogonCount 1
                                      auto_logon_xml.Enabled true
                                    end
                                  end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
                                ).strip
                              end
                              xml.ComponentSetting do
                                xml.SettingName "FirstLogonCommands"
                                xml.Content Base64.encode64(
                                  Nokogiri::XML::Builder.new do |first_logon_xml|
                                    first_logon_xml.FirstLogonCommands do
                                      if params[:winrm_max_timeout]
                                        first_logon_xml.SynchronousCommand("wcm:action" => "add") do
                                          first_logon_xml.Order 1
                                          first_logon_xml.CommandLine "cmd.exe /c winrm set winrm/config @{MaxTimeoutms=\"#{params[:winrm_max_timeout]}\"}"
                                          first_logon_xml.Description "Bump WinRM max timeout to #{params[:winrm_max_timeout]} milliseconds"
                                        end
                                      end

                                      if params[:winrm_max_memory_per_shell]
                                        first_logon_xml.SynchronousCommand("wcm:action" => "add") do
                                          first_logon_xml.Order 2
                                          first_logon_xml.CommandLine "cmd.exe /c winrm set winrm/config/winrs @{MaxMemoryPerShellMB=\"#{params[:winrm_max_memory_per_shell]}\"}"
                                          first_logon_xml.Description "Bump WinRM max memory per shell to #{params[:winrm_max_memory_per_shell]} MB"
                                        end
                                      end
                                    end
                                  end.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
                                ).strip
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end

            xml.ConfigurationSet("i:type" => "NetworkConfigurationSet") do
              xml.ConfigurationSetType "NetworkConfiguration"
              xml.InputEndpoints do
                # 1. connection_protocol = 'winrm' for windows => Set winrm port
                # 2. connection_protocol = 'ssh' for windows and linux => Set ssh port
                # 3. connection_protocol = 'cloud-api' for windows and linux => Set no port
                if (params[:os_type] == "Windows") && params[:connection_protocol].casecmp("winrm").zero?
                  xml.InputEndpoint do
                    if params[:winrm_ssl]
                      xml.LocalPort "5986"
                    else
                      xml.LocalPort "5985"
                    end
                    xml.Name "WinRM"
                    xml.Port params[:port]
                    xml.Protocol "TCP"
                  end
                elsif params[:connection_protocol].casecmp("ssh").zero?
                  xml.InputEndpoint do
                    xml.LocalPort "22"
                    xml.Name "SSH"
                    xml.Port params[:port]
                    xml.Protocol "TCP"
                  end
                end
                all_endpoints = []

                if params[:tcp_endpoints]
                  params[:tcp_endpoints].split(",").map(&:strip).each do |endpoint|
                    all_endpoints << parse_endpoint_from_params("TCP", params[:azure_vm_name], endpoint)
                  end
                end
                if params[:udp_endpoints]
                  params[:udp_endpoints].split(",").map(&:strip).each do |endpoint|
                    all_endpoints << parse_endpoint_from_params("UDP", params[:azure_vm_name], endpoint)
                  end
                end
                add_endpoints_to_xml(xml, all_endpoints, params) if all_endpoints.any?
              end
              if params[:azure_subnet_name]
                xml.SubnetNames do
                  xml.SubnetName params[:azure_subnet_name]
                end
              end
            end
          end

          # Azure resource extension support
          if params[:connection_protocol] == "cloud-api"
            xml.ResourceExtensionReferences do
              xml.ResourceExtensionReference do
                xml.ReferenceName params[:chef_extension]
                xml.Publisher params[:chef_extension_publisher]
                xml.Name params[:chef_extension]
                xml.Version params[:chef_extension_version]
                xml.ResourceExtensionParameterValues do
                  if params[:chef_extension_public_param]
                    xml.ResourceExtensionParameterValue do
                      xml.Key "PublicParams"
                      xml.Value Base64.encode64(params[:chef_extension_public_param].to_json)
                      xml.Type "Public"
                    end
                  end
                  if params[:chef_extension_private_param]
                    xml.ResourceExtensionParameterValue do
                      xml.Key "PrivateParams"
                      xml.Value Base64.encode64(params[:chef_extension_private_param].to_json)
                      xml.Type "Private"
                    end
                  end
                end
                xml.State "Enable"
              end
            end
          end

          if params[:azure_availability_set]
            xml.AvailabilitySetName params[:azure_availability_set]
          end

          xml.VMImageName params[:azure_source_image] if params[:is_vm_image]

          xml.Label Base64.encode64(params[:azure_vm_name]).strip

          # OSVirtualHardDisk not required in case azure_source_image is a VMImage
          unless params[:is_vm_image]
            xml.OSVirtualHardDisk do
              disk_name = params[:azure_os_disk_name] || "disk_" + SecureRandom.uuid
              xml.DiskName disk_name
              domain_suffix = params[:azure_api_host_name] ? params[:azure_api_host_name].scan(/core.*/)[0] : ""
              xml.MediaLink "http://" + params[:azure_storage_account] + ".blob." + domain_suffix + "/vhds/" + disk_name + ".vhd"
              xml.SourceImageName params[:azure_source_image]
            end
          end

          xml.RoleSize params[:azure_vm_size]
          xml.ProvisionGuestAgent true if params[:connection_protocol] == "cloud-api"
        end
      end
      builder.doc
    end

    def create(params, roleXML)
      servicecall = "hostedservices/#{params[:azure_dns_name]}/deployments" \
                    "/#{params["deploy_name"]}/roles"
      @connection.query_azure(servicecall, "post", roleXML.to_xml)
    end

    def setup_extension(params)
      ## add Chef Extension config in role_xml retrieved from the server
      puts "Adding Chef Extension config in server role..."
      role_xml = update_role_xml_for_extension(params[:role_xml], params)

      ## role_xml can't be used for update as it has additional tags like
      ## role_name, osversion etc. which update API does not support, also the
      ## xml is the child of parent node 'Deployment' in XML, so instead of
      ## modifying the role_xml to fit for our requirements, we create
      ## new XML (with Chef Extension config and other pre-existing VM config)
      ## using the required values of the updated role_xml
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.PersistentVMRole(
          "xmlns" => "http://schemas.microsoft.com/windowsazure",
          "xmlns:i" => "http://www.w3.org/2001/XMLSchema-instance"
        ) do
          xml.ConfigurationSets role_xml.at_css("ConfigurationSets").children unless role_xml.at_css("ConfigurationSets").nil?
          xml.ResourceExtensionReferences role_xml.at_css("ResourceExtensionReferences").children unless role_xml.at_css("ResourceExtensionReferences").nil?
          xml.AvailabilitySetName role_xml.at_css("AvailabilitySetName").children unless role_xml.at_css("AvailabilitySetName").nil?
          xml.DataVirtualHardDisks role_xml.at_css("DataVirtualHardDisks").children unless role_xml.at_css("DataVirtualHardDisks").nil?
          xml.OSVirtualHardDisk role_xml.at_css("OSVirtualHardDisk").children unless role_xml.at_css("OSVirtualHardDisk").nil?
          xml.RoleSize role_xml.at_css("RoleSize").children unless role_xml.at_css("RoleSize").nil?
          xml.ProvisionGuestAgent role_xml.at_css("ProvisionGuestAgent").children unless role_xml.at_css("ProvisionGuestAgent").nil?
        end
      end

      builder.doc.to_xml.gsub("&lt\;", "<").gsub("&gt\;", ">")
    end

    def update_role_xml_for_extension(roleXML, params)
      ## check if 'ResourceExtensionReferences' node already exist in the XML,
      ## if no add it, else retrieve the object of the existing node
      add_resource_extension_references = roleXML.at_css("ResourceExtensionReferences").nil?

      if add_resource_extension_references
        resource_extension_references = Nokogiri::XML::Node.new("ResourceExtensionReferences", roleXML)
      else
        resource_extension_references = roleXML.css("ResourceExtensionReferences")
      end

      ## check if Azure Chef Extension is already installed on the given server,
      ## if no than install it, else raise error saying that the extension is
      ## already installed
      ext = nil
      unless add_resource_extension_references
        unless resource_extension_references.at_css("ReferenceName").nil?
          resource_extension_references.css("ReferenceName").each { |node| ext = node if node.content == params[:chef_extension] }
        end
      end

      add_resource_extension_reference = ext.nil?

      ## create Azure Chef Extension config and add it in the role_xml
      if add_resource_extension_reference
        resource_extension_reference = Nokogiri::XML::Node.new("ResourceExtensionReference", roleXML)

        reference_name = Nokogiri::XML::Node.new("ReferenceName", roleXML)
        reference_name.content = params[:chef_extension]
        resource_extension_reference.add_child(reference_name)

        publisher = Nokogiri::XML::Node.new("Publisher", roleXML)
        publisher.content = params[:chef_extension_publisher]
        resource_extension_reference.add_child(publisher)

        name = Nokogiri::XML::Node.new("Name", roleXML)
        name.content = params[:chef_extension]
        resource_extension_reference.add_child(name)

        version = Nokogiri::XML::Node.new("Version", roleXML)
        version.content = params[:chef_extension_version]
        resource_extension_reference.add_child(version)

        resource_extension_parameter_values = Nokogiri::XML::Node.new("ResourceExtensionParameterValues", roleXML)
        if params[:chef_extension_public_param]
          resource_extension_parameter_value = Nokogiri::XML::Node.new("ResourceExtensionParameterValue", roleXML)

          key = Nokogiri::XML::Node.new("Key", roleXML)
          key.content = "PublicParams"
          resource_extension_parameter_value.add_child(key)

          value = Nokogiri::XML::Node.new("Value", roleXML)
          value.content = Base64.encode64(params[:chef_extension_public_param].to_json)
          resource_extension_parameter_value.add_child(value)

          type = Nokogiri::XML::Node.new("Type", roleXML)
          type.content = "Public"
          resource_extension_parameter_value.add_child(type)

          resource_extension_parameter_values.add_child(resource_extension_parameter_value)
        end

        if params[:chef_extension_private_param]
          resource_extension_parameter_value = Nokogiri::XML::Node.new("ResourceExtensionParameterValue", roleXML)

          key = Nokogiri::XML::Node.new("Key", roleXML)
          key.content = "PrivateParams"
          resource_extension_parameter_value.add_child(key)

          value = Nokogiri::XML::Node.new("Value", roleXML)
          value.content = Base64.encode64(params[:chef_extension_private_param].to_json)
          resource_extension_parameter_value.add_child(value)

          type = Nokogiri::XML::Node.new("Type", roleXML)
          type.content = "Private"
          resource_extension_parameter_value.add_child(type)

          resource_extension_parameter_values.add_child(resource_extension_parameter_value)
        end

        resource_extension_reference.add_child(resource_extension_parameter_values)

        state = Nokogiri::XML::Node.new("State", roleXML)
        state.content = "enable"
        resource_extension_reference.add_child(state)

        if add_resource_extension_references
          resource_extension_references.add_child(resource_extension_reference)
        else
          resource_extension_references.last.add_child(resource_extension_reference)
        end

        roleXML.add_child(resource_extension_references) if add_resource_extension_references

        add_provision_guest_agent = roleXML.at_css("ProvisionGuestAgent").nil?

        if add_provision_guest_agent
          provision_guest_agent = Nokogiri::XML::Node.new("ProvisionGuestAgent", roleXML)
          provision_guest_agent.content = true
        else
          provision_guest_agent = roleXML.css("ProvisionGuestAgent")
          provision_guest_agent.first.content = true
        end

        roleXML.add_child(provision_guest_agent) if add_provision_guest_agent
      else ## raise error as Chef Extension is already installed on the server
        raise "Chef Extension is already installed on the server #{params[:azure_vm_name]}."
      end

      roleXML
    end

    def update(name, params, roleXML)
      puts "Updating server role..."
      servicecall = "hostedservices/#{params[:azure_dns_name]}" \
                    "/deployments/#{params[:deploy_name]}/roles/#{name}"
      ret_val = @connection.query_azure(servicecall, "put", roleXML, "", true, true, "application/xml")
      error_code, error_message = error_from_response_xml(ret_val)
      unless error_code.empty?
        Chef::Log.debug(ret_val.to_s)
        raise "Unable to update role:" + error_code + " : " + error_message
      end
    end
  end
end
