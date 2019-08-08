#
# Author:: Nimisha Sharad (nimisha.sharad@clogeny.com)
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

module Azure::ARM
  module ARMDeploymentTemplate
    def ohai_hints(hint_names, resource_ids)
      hints_json = {}

      hint_names.each do |hint_name|
        case hint_name
        when "vm_name"
          hints_json["vm_name"] = "[reference(#{resource_ids["vmId"]}).osProfile.computerName]" unless hints_json.key? "vm_name"
        when "public_fqdn"
          hints_json["public_fqdn"] = "[reference(#{resource_ids["pubId"]}).dnsSettings.fqdn]" unless hints_json.key? "public_fqdn"
        when "platform"
          hints_json["platform"] = "[concat(reference(#{resource_ids["vmId"]}).storageProfile.imageReference.offer, concat(' ', reference(#{resource_ids["vmId"]}).storageProfile.imageReference.sku))]" unless hints_json.key? "platform"
        end
      end

      hints_json
    end

    def tcp_ports(tcp_ports, vm_name)
      tcp_ports = tcp_ports.split(",")
      sec_grp_json =
        {
          "apiVersion" => "[variables('apiVersion')]",
          "type" => "Microsoft.Network/networkSecurityGroups",
          "name" => "[variables('secgrpname')]",
          "location" => "[resourceGroup().location]",
          "properties" => {
            "securityRules" => [
            ],
          },
        }
      # Security Rule priority can be set between 100 and 4096
      rule_no = 300
      incremental = 0
      for port in tcp_ports
        rule_no += 2
        sec_grp_json["properties"]["securityRules"].push(
          "name" => vm_name + "_rule_" + incremental.to_s,
          "properties" => {
            "description" => "Port Provided by user",
            "protocol" => "Tcp",
            "sourcePortRange" => "*",
            "destinationPortRange" => port,
            "sourceAddressPrefix" => "*",
            "destinationAddressPrefix" => "*",
            "access" => "Allow",
            "priority" => rule_no,
            "direction" => "Inbound",
          }
        )
        incremental += 1
      end
      sec_grp_json
    end

    def create_deployment_template(params)
      if params[:chef_extension_public_param][:bootstrap_options][:chef_node_name]
        chef_node_name = "[concat(parameters('chef_node_name'),copyIndex())]"
        chef_node_name = "[parameters('chef_node_name')]" if params[:server_count].to_i == 1
      end

      if params[:server_count].to_i > 1
        # publicIPAddresses Resource Variables
        publicIPAddressName = "[concat(variables('publicIPAddressName'),copyIndex())]"
        domainNameLabel = "[concat(parameters('dnsLabelPrefix'), copyIndex())]"

        # networkInterfaces Resource Variables
        nicName = "[concat(variables('nicName'),copyIndex())]"
        depNic1 = "[concat('Microsoft.Network/publicIPAddresses/', concat(variables('publicIPAddressName'),copyIndex()))]"
        pubId = "[resourceId('Microsoft.Network/publicIPAddresses',concat(variables('publicIPAddressName'),copyIndex()))]"

        # virtualMachines Resource Variables
        vmName = "[concat(variables('vmName'),copyIndex())]"
        vmSize = "[concat(variables('vmSize'),copyIndex())]"
        vmId = "[resourceId('Microsoft.Compute/virtualMachines', concat(variables('vmName'),copyIndex()))]"
        depVm2 = "[concat('Microsoft.Network/networkInterfaces/', variables('nicName'), copyIndex())]"
        computerName = "[concat(variables('vmName'),copyIndex())]"
        uri = "[concat('http://',variables('storageAccountName'),'.blob.core.windows.net/',variables('vmStorageAccountContainerName'),'/',concat(variables('vmName'),copyIndex()),'.vhd')]"
        netid = "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('nicName'), copyIndex()))]"

        # Extension Variables
        extName = "[concat(variables('vmName'),copyIndex(),'/', variables('vmExtensionName'))]"
        depExt = "[concat('Microsoft.Compute/virtualMachines/', variables('vmName'), copyIndex())]"

      else
        # publicIPAddresses Resource Variables
        publicIPAddressName = "[variables('publicIPAddressName')]"
        domainNameLabel = "[parameters('dnsLabelPrefix')]"

        # networkInterfaces Resource Variables
        nicName = "[concat(variables('nicName'))]"
        depNic1 = "[concat('Microsoft.Network/publicIPAddresses/', variables('publicIPAddressName'))]"
        pubId = "[resourceId('Microsoft.Network/publicIPAddresses',variables('publicIPAddressName'))]"

        # virtualMachines Resource Variables
        vmName = "[variables('vmName')]"
        vmSize = "[variables('vmSize')]"
        vmId = "[resourceId('Microsoft.Compute/virtualMachines', variables('vmName'))]"
        depVm2 = "[concat('Microsoft.Network/networkInterfaces/', variables('nicName'))]"
        computerName = "[variables('vmName')]"
        uri = "[concat('http://',variables('storageAccountName'),'.blob.core.windows.net/',variables('vmStorageAccountContainerName'),'/',variables('vmName'),'.vhd')]"
        netid = "[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]"

        # Extension Variables
        extName = "[concat(variables('vmName'),'/', variables('vmExtensionName'))]"
        depExt = "[concat('Microsoft.Compute/virtualMachines/', variables('vmName'))]"
      end

      # NetworkSecurityGroups Resource Variables
      sec_grp_name = "[variables('secgrpname')]"
      sec_grp = "[concat('Microsoft.Network/networkSecurityGroups/', variables('secgrpname'))]"
      sec_grp_id = "[resourceId('Microsoft.Network/networkSecurityGroups/', variables('secgrpname'))]"

      resource_ids = {}
      hint_names = params[:chef_extension_public_param][:hints]

      hint_names.each do |hint_name|
        case hint_name
        when "public_fqdn"
          resource_ids["pubId"] = pubId.delete("[").delete("]") unless resource_ids.key? "pubId"
        when "vm_name", "platform"
          resource_ids["vmId"] = vmId.delete("[").delete("]") unless resource_ids.key? "vmId"
        end
      end

      hints_json = ohai_hints(hint_names, resource_ids)

      template = {
        "$schema" => "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        "contentVersion" => "1.0.0.0",
        "parameters" => {
          "adminUserName" => {
            "type" => "string",
            "metadata" => {
              "description" => "User name for the Virtual Machine.",
            },
          },
          "adminPassword" => {
            "type" => "securestring",
            "metadata" => {
              "description" => "Password for the Virtual Machine.",
            },
          },
          "availabilitySetName" => {
            "type" => "string",
          },
          "availabilitySetPlatformFaultDomainCount" => {
            "type" => "string",
          },
          "availabilitySetPlatformUpdateDomainCount" => {
            "type" => "string",
          },
          "numberOfInstances" => {
            "type" => "int",
            "defaultValue" => 1,
            "metadata" => {
              "description" => "Number of VM instances to create. Default is 1",
            },
          },
          "dnsLabelPrefix" => {
            "type" => "string",
            "metadata" => {
              "description" => "Unique DNS Name for the Public IP used to access the Virtual Machine.",
            },
          },
          "imageSKU" => {
            "type" => "string",
            "metadata" => {
              "description" => "Version of the image",
            },
          },
          "imageVersion" => {
            "type" => "string",
            "defaultValue" => "latest",
            "metadata" => {
              "description" => "Azure image reference version.",
            },
          },
          "validation_key" => {
            "type" => "string",
            "metadata" => {
              "description" => "JSON Escaped Validation Key",
            },
          },

          "chef_server_crt" => {
            "type" => "string",
            "metadata" => {
              "description" => "Optional. SSL cerificate provided by user.",
            },
          },
          "chef_server_url" => {
            "type" => "string",
            "metadata" => {
              "description" => "Organization URL for the Chef Server. Example https://ChefServerDnsName.cloudapp.net/organizations/Orgname",
            },
          },
          "validation_client_name" => {
            "type" => "string",
            "metadata" => {
              "description" => "Validator key name for the organization. Example : MyOrg-validator",
            },
          },
          "runlist" => {
            "type" => "string",
            "metadata" => {
              "description" => "Optional Run List to Execute",
            },
          },
          "environment" => {
            "type" => "string",
            "metadata" => {
              "description" => "Chef environment for the node (VM) in the Chef Organization",
            },
          },
          "chef_node_name" => {
            "type" => "string",
            "metadata" => {
              "description" => "The name for the node (VM) in the Chef Organization",
            },
          },
          "validation_key_format" => {
            "type" => "string",
            "allowedValues" => %w{plaintext base64encoded},
            "defaultValue" => "plaintext",
            "metadata" => {
              "description" => "Format in which Validation Key is given. e.g. plaintext, base64encoded",
            },
          },
          "client_rb" => {
            "type" => "string",
            "metadata" => {
              "description" => "Optional. Path to a client.rb file for use by the bootstrapped node.",
            },
          },
          "bootstrap_version" => {
            "type" => "string",
            "metadata" => {
              "description" => "Optional. The version of Chef to install.",
            },
          },
          "custom_json_attr" => {
            "type" => "string",
            "metadata" => {
              "description" => "Optional. A JSON string to be added to the first run of chef-client.",
            },
          },
          "node_ssl_verify_mode" => {
            "type" => "string",
            "metadata" => {
              "description" => "Optional. Whether or not to verify the SSL cert for all HTTPS requests.",
            },
          },
          "node_verify_api_cert" => {
            "type" => "string",
            "metadata" => {
              "description" => "Optional. Verify the SSL cert for HTTPS requests to the Chef server API.",
            },
          },
          "encrypted_data_bag_secret" => {
            "type" => "string",
            "metadata" => {
              "description" => "Optional. The secret key to use to encrypt data bag item values.",
            },
          },
          "bootstrap_proxy" => {
            "type" => "string",
            "metadata" => {
              "description" => "Optional. The proxy server for the node being bootstrapped.",
            },
          },
          "sshKeyData" => {
            "type" => "string",
            "metadata" => {
              "description" => "SSH rsa public key file as a string.",
            },
          },
          "disablePasswordAuthentication" => {
            "type" => "string",
            "metadata" => {
              "description" => "Set to true if using ssh key for authentication.",
            },
          },
        },
        "variables" => {
          "storageAccountName" => "[concat(uniquestring(resourceGroup().id), '#{params[:azure_storage_account]}')]",
          "imagePublisher" => "#{params[:azure_image_reference_publisher]}",
          "imageOffer" => "#{params[:azure_image_reference_offer]}",
          "OSDiskName" => "#{params[:azure_os_disk_name]}",
          "nicName" => "#{params[:azure_vm_name]}",
          "subnetName" => "#{params[:azure_vnet_subnet_name]}",
          "storageAccountType" => "#{params[:azure_storage_account_type]}",
          "publicIPAddressName" => "#{params[:azure_vm_name]}",
          "publicIPAddressType" => "Dynamic",
          "vmStorageAccountContainerName" => "#{params[:azure_vm_name]}",
          "vmName" => "#{params[:azure_vm_name]}",
          "vmSize" => "#{params[:vm_size]}",
          "virtualNetworkName" => "#{params[:vnet_config][:virtualNetworkName]}",
          "secgrpname" => "#{params[:azure_sec_group_name]}",
          "vnetID" => "[resourceId('Microsoft.Network/virtualNetworks',variables('virtualNetworkName'))]",
          "subnetRef" => "[concat(variables('vnetID'),'/subnets/',variables('subnetName'))]",
          "apiVersion" => "2015-06-15",
          "vmExtensionName" => "#{params[:chef_extension]}",
          "sshKeyPath" => "[concat('/home/',parameters('adminUserName'),'/.ssh/authorized_keys')]",
        },
        "resources" => [
          {
            "type" => "Microsoft.Storage/storageAccounts",
            "name" => "[variables('storageAccountName')]",
            "apiVersion" => "[variables('apiVersion')]",
            "location" => "[resourceGroup().location]",
            "properties" => {
              "accountType" => "[variables('storageAccountType')]",
            },
          },
          {
            "apiVersion" => "[variables('apiVersion')]",
            "type" => "Microsoft.Network/publicIPAddresses",
            "name" => publicIPAddressName,
            "location" => "[resourceGroup().location]",
            "copy" => {
              "name" => "publicIPLoop",
              "count" => "[parameters('numberOfInstances')]",
            },
            "properties" => {
              "publicIPAllocationMethod" => "[variables('publicIPAddressType')]",
              "dnsSettings" => {
                "domainNameLabel" => domainNameLabel,
              },
            },
          },
          {
            "apiVersion" => "[variables('apiVersion')]",
            "type" => "Microsoft.Network/virtualNetworks",
            "name" => "[variables('virtualNetworkName')]",
            "location" => "[resourceGroup().location]",
            "properties" => {
              "addressSpace" => {
                "addressPrefixes" => params[:vnet_config][:addressPrefixes],
              },
              "subnets" => params[:vnet_config][:subnets],
            },
          },
          {
            "apiVersion" => "[variables('apiVersion')]",
            "type" => "Microsoft.Network/networkInterfaces",
            "name" => nicName,
            "location" => "[resourceGroup().location]",
            "copy" => {
              "name" => "nicLoop",
              "count" => "[parameters('numberOfInstances')]",
            },
            "dependsOn" => [
              depNic1,
              "[concat('Microsoft.Network/virtualNetworks/', variables('virtualNetworkName'))]",
            ],
            "properties" => {
              "ipConfigurations" => [
                {
                  "name" => "ipconfig1",
                  "properties" => {
                    "privateIPAllocationMethod" => "Dynamic",
                    "publicIPAddress" => {
                      "id" => pubId,
                    },
                    "subnet" => {
                      "id" => "[variables('subnetRef')]",
                    },
                  },
                },
              ],
            },
          },
          {
            "apiVersion" => "[variables('apiVersion')]",
            "type" => "Microsoft.Compute/virtualMachines",
            "name" => vmName,
            "location" => "[resourceGroup().location]",
            "copy" => {
              "name" => "vmLoop",
              "count" => "[parameters('numberOfInstances')]",
            },
            "dependsOn" => [
              "[concat('Microsoft.Storage/storageAccounts/', variables('storageAccountName'))]",
              depVm2,
            ],
            "properties" => {
              "hardwareProfile" => {
                "vmSize" => "[variables('vmSize')]",
              },
              "osProfile" => {
                "computerName" => computerName,
                "adminUserName" => "[parameters('adminUserName')]",
                "adminPassword" => "[parameters('adminPassword')]",
                "linuxConfiguration" => ( if params[:disablePasswordAuthentication] == "true"
                                            {  "disablePasswordAuthentication" => "[parameters('disablePasswordAuthentication')]",
                                               "ssh" => {
                                                 "publicKeys" => [{
                                                   "path" => "[variables('sshKeyPath')]",
                                                   "keyData" => "[parameters('sshKeyData')]",
                                                 }],
                                               },
                                            }
                                          end),
              },
              "storageProfile" => {
                "imageReference" => {
                  "publisher" => "[variables('imagePublisher')]",
                  "offer" => "[variables('imageOffer')]",
                  "sku" => "[parameters('imageSKU')]",
                  "version" => "[parameters('imageVersion')]",
                },
                "osDisk" => {
                  "name" => "[variables('OSDiskName')]",
                  "vhd" => {
                    "uri" => uri,
                  },
                  "caching" => "ReadWrite",
                  "createOption" => "FromImage",
                },
              },
              "networkProfile" => {
                "networkInterfaces" => [
                  {
                    "id" => netid,
                  },
                ],
              },
              "diagnosticsProfile" => {
                "bootDiagnostics" => {
                  "enabled" => "true",
                  "storageUri" => "[concat('http://',variables('storageAccountName'),'.blob.core.windows.net')]",
                },
              },
            },
          },
          {
            "type" => "Microsoft.Compute/virtualMachines/extensions",
            "name" => extName,
            "apiVersion" => "2015-05-01-preview",
            "location" => "[resourceGroup().location]",
            "copy" => {
              "name" => "extensionLoop",
              "count" => "[parameters('numberOfInstances')]",
            },
            "dependsOn" => [
              depExt,
            ],
            "properties" => {
              "publisher" => "#{params[:chef_extension_publisher]}",
              "type" => "#{params[:chef_extension]}",
              "typeHandlerVersion" => "#{params[:chef_extension_version]}",
              "autoUpgradeMinorVersion" => "#{params[:auto_upgrade_minor_version]}",
              "settings" => {
                "bootstrap_version" => "[parameters('bootstrap_version')]",
                "bootstrap_options" => {
                  "chef_node_name" => chef_node_name,
                  "chef_server_url" => "[parameters('chef_server_url')]",
                  "validation_client_name" => "[parameters('validation_client_name')]",
                  "node_ssl_verify_mode" => "[parameters('node_ssl_verify_mode')]",
                  "node_verify_api_cert" => "[parameters('node_verify_api_cert')]",
                  "bootstrap_proxy" => "[parameters('bootstrap_proxy')]",
                  "environment" => "[parameters('environment')]",
                },
                "runlist" => "[parameters('runlist')]",
                "validation_key_format" => "[parameters('validation_key_format')]",
                "hints" => hints_json,
                "client_rb" => "[parameters('client_rb')]",
                "custom_json_attr" => "[parameters('custom_json_attr')]",
              },
              "protectedSettings" => {
                "validation_key" => "[parameters('validation_key')]",
                "chef_server_crt" => "[parameters('chef_server_crt')]",
                "encrypted_data_bag_secret" => "[parameters('encrypted_data_bag_secret')]",
              },
            },
          },
        ],
      }

      if params[:azure_availability_set]
        set_val = {
          "name" => "[parameters('availabilitySetName')]",
          "type" => "Microsoft.Compute/availabilitySets",
          "apiVersion" => "[variables('apiVersion')]",
          "location" => "[resourceGroup().location]",
          "properties" => {
            "platformFaultDomainCount" => "[parameters('availabilitySetPlatformFaultDomainCount')]",
            "platformUpdateDomainCount" => "[parameters('availabilitySetPlatformUpdateDomainCount')]",
          },
        }

        length = template["resources"].length.to_i - 1
        for i in 0..length do
          if template["resources"][i]["type"] == "Microsoft.Compute/virtualMachines"
            template["resources"][i]["dependsOn"] << "[concat('Microsoft.Compute/availabilitySets/', parameters('availabilitySetName'))]"
            template["resources"][i]["properties"]["availabilitySet"] = { "id" => "[resourceId('Microsoft.Compute/availabilitySets', parameters('availabilitySetName'))]" }
          end
        end
        template["resources"].insert(length, set_val)
      end

      if params[:tcp_endpoints]
        sec_grp_json = tcp_ports(params[:tcp_endpoints], params[:azure_vm_name])
        template["resources"].insert(1, sec_grp_json)
        length = template["resources"].length.to_i - 1
        for i in 0..length do
          if template["resources"][i]["type"] == "Microsoft.Network/virtualNetworks"
            template["resources"][i] = template["resources"][i].merge({ "dependsOn" => [sec_grp] })
          end
          if template["resources"][i]["type"] == "Microsoft.Network/networkInterfaces"
            template["resources"][i]["properties"] = template["resources"][i]["properties"].merge({ "networkSecurityGroup" => { "id" => sec_grp_id } })
          end
        end
      end

      if params[:chef_extension_public_param][:extendedLogs] == "true"
        template["resources"].each do |resource|
          if resource["type"] == "Microsoft.Compute/virtualMachines/extensions"
            resource["properties"]["settings"]["extendedLogs"] = params[:chef_extension_public_param][:extendedLogs]
          end
        end
      end

      if params[:chef_extension_public_param][:chef_daemon_interval]
        template["resources"].each do |resource|
          if resource["type"] == "Microsoft.Compute/virtualMachines/extensions"
            resource["properties"]["settings"]["chef_daemon_interval"] = params[:chef_extension_public_param][:chef_daemon_interval]
          end
        end
      end

      if params[:chef_extension_public_param][:daemon]
        template["resources"].each do |resource|
          if resource["type"] == "Microsoft.Compute/virtualMachines/extensions"
            resource["properties"]["settings"]["daemon"] = params[:chef_extension_public_param][:daemon]
          end
        end
      end
      if params[:server_count].to_i > 1 && params[:chef_extension_private_param][:validation_key].nil?
        template["resources"].last["properties"]["protectedSettings"]["client_pem"] = "[parameters(concat('client_pem',copyIndex()))]"
        0.upto (params[:server_count].to_i - 1) do |count|
          template["parameters"]["client_pem" + count.to_s] = {
            "type" => "string",
            "metadata" => {
              "description" => "Required for validtorless bootstrap.",
            },
          }
        end
      else
        template["resources"].last["properties"]["protectedSettings"]["client_pem"] = "[parameters('client_pem')]"
        template["parameters"]["client_pem"] = {
          "type" => "string",
          "metadata" => {
            "description" => "Required for validtorless bootstrap.",
          },
        }
      end
      template
    end

    def create_deployment_parameters(params)
      admin_user = params[:connection_user]
      admin_password = params[:connection_password]

      parameters = {
        "adminUserName" => {
          "value" => "#{admin_user}",
        },
        "adminPassword" => {
          "value" => "#{admin_password}",
        },
        "availabilitySetName" => {
            "value" => "#{params[:azure_availability_set]}",
        },
        "availabilitySetPlatformFaultDomainCount" => {
            "value" => "2",
        },
        "availabilitySetPlatformUpdateDomainCount" => {
            "value" => "5",
        },
        "dnsLabelPrefix" => {
          "value" => "#{params[:azure_vm_name]}",
        },
        "imageSKU" => {
          "value" => "#{params[:azure_image_reference_sku]}",
        },
        "numberOfInstances" => {
          "value" => "#{params[:server_count]}".to_i,
        },
        "validation_key" => {
          "value" => "#{params[:chef_extension_private_param][:validation_key]}",
        },

        "chef_server_crt" => {
          "value" => "#{params[:chef_extension_private_param][:chef_server_crt]}",
        },
        "encrypted_data_bag_secret" => {
          "value" => "#{params[:chef_extension_private_param][:encrypted_data_bag_secret]}",
        },
        "chef_server_url" => {
          "value" => "#{params[:chef_extension_public_param][:bootstrap_options][:chef_server_url]}",
        },
        "validation_client_name" => {
          "value" => "#{params[:chef_extension_public_param][:bootstrap_options][:validation_client_name]}",
        },
        "node_ssl_verify_mode" => {
          "value" => "#{params[:chef_extension_public_param][:bootstrap_options][:node_ssl_verify_mode]}",
        },
        "node_verify_api_cert" => {
          "value" => "#{params[:chef_extension_public_param][:bootstrap_options][:node_verify_api_cert]}",
        },
        "bootstrap_proxy" => {
          "value" => "#{params[:chef_extension_public_param][:bootstrap_options][:bootstrap_proxy]}",
        },
        "runlist" => {
          "value" => "#{params[:chef_extension_public_param][:runlist]}",
        },
        "environment" => {
          "value" => "#{params[:chef_extension_public_param][:bootstrap_options][:environment]}",
        },
        "chef_node_name" => {
          "value" => "#{params[:chef_extension_public_param][:bootstrap_options][:chef_node_name]}",
        },
        "client_rb" => {
          "value" => "#{params[:chef_extension_public_param][:client_rb]}",
        },
        "bootstrap_version" => {
          "value" => "#{params[:chef_extension_public_param][:bootstrap_options][:bootstrap_version]}",
        },
        "custom_json_attr" => {
          "value" => "#{params[:chef_extension_public_param][:custom_json_attr]}",
        },
        "sshKeyData" => {
          "value" => "#{params[:ssh_public_key]}",
        },
        "disablePasswordAuthentication" => {
          "value" => "#{params[:disablePasswordAuthentication]}",
        },
      }
      if params[:server_count].to_i > 1 && params[:chef_extension_private_param][:validation_key].nil?
        0.upto (params[:server_count].to_i - 1) do |count|
          parameters["client_pem#{count}"] = {
              "value" => "#{params[:chef_extension_private_param][("client_pem" + count.to_s).to_sym]}",
            }
        end
      else
        parameters["client_pem"] = {
            "value" => "#{params[:chef_extension_private_param][:client_pem]}",
          }
      end
      parameters
    end
  end
end
