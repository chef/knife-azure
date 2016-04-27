#
# Author:: Nimisha Sharad (nimisha.sharad@clogeny.com)
# Copyright:: Copyright (c) 2015-2016 Opscode, Inc.
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

    def create_deployment_template(params)
      if params[:chef_extension_public_param][:bootstrap_options][:chef_node_name]
        chef_node_name = "[concat(parameters('chef_node_name'),copyIndex())]"
      end

      template = {
        "$schema"=> "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        "contentVersion"=> "1.0.0.0",
        "parameters"=> {
          "adminUserName"=> {
            "type"=> "string",
            "metadata"=> {
              "description"=> "User name for the Virtual Machine."
            }
          },
          "adminPassword"=> {
            "type"=> "securestring",
            "metadata"=> {
              "description"=> "Password for the Virtual Machine."
            }
          },
          "numberOfInstances" => {
            "type" => "int",
            "defaultValue" => 1,
            "metadata" => {
              "description" => "Number of VM instances to create. Default is 1"
            }
          },
          "dnsLabelPrefix"=> {
            "type"=> "string",
            "metadata"=> {
              "description"=> "Unique DNS Name for the Public IP used to access the Virtual Machine."
            }
          },
          "imageSKU"=> {
            "type"=> "string",
            "metadata"=> {
              "description"=> "Version of the image"
            }
          },
          "imageVersion" => {
            "type"=> "string",
            "defaultValue" => "latest",
            "metadata" => {
              "description" => "Azure image reference version."
            }
          },
          "validation_key"=> {
              "type"=> "string",
              "metadata"=> {
                "description"=> "JSON Escaped Validation Key"
              }
            },
            "chef_server_url"=> {
              "type"=> "string",
              "metadata"=> {
                "description"=> "Organization URL for the Chef Server. Example https://ChefServerDnsName.cloudapp.net/organizations/Orgname"
              }
            },
            "validation_client_name"=> {
              "type"=> "string",
              "metadata"=> {
                "description"=> "Validator key name for the organization. Example : MyOrg-validator"
              }
            },
            "runlist"=> {
              "type"=> "string",
              "metadata"=> {
                "description"=> "Optional Run List to Execute"
              }
            },
            "autoUpdateClient" => {
              "type" => "string",
              "metadata" => {
                "description" => "Optional Flag for auto update"
              }
            },
            "deleteChefConfig" => {
              "type" => "string",
              "metadata" => {
                "description" => "Optional Flag for deleteChefConfig"
              }
            },
            "uninstallChefClient" => {
              "type" => "string",
              "metadata" => {
                "description" => "Optional Flag for uninstallChefClient"
              }
            },
             "chef_node_name" => {
              "type" => "string",
              "metadata" => {
                "description" => "The name for the node (VM) in the Chef Organization"
              }
            },
            "validation_key_format" => {
              "type"=> "string",
              "allowedValues"=> ["plaintext", "base64encoded"],
              "defaultValue"=> "plaintext",
              "metadata" => {
                "description"=> "Format in which Validation Key is given. e.g. plaintext, base64encoded"
              }
            }
        },
        "variables"=> {
          "storageAccountName"=> "[concat(uniquestring(resourceGroup().id), '#{params[:azure_storage_account]}')]",
          "imagePublisher"=> "#{params[:azure_image_reference_publisher]}",
          "imageOffer"=> "#{params[:azure_image_reference_offer]}",
          "OSDiskName"=> "#{params[:azure_os_disk_name]}",
          "nicName"=> "#{params[:azure_vm_name]}",
          "addressPrefix"=> "10.0.0.0/16",
          "subnetName"=> "#{params[:azure_vnet_subnet_name]}",
          "subnetPrefix"=> "10.0.0.0/24",
          "storageAccountType"=> "#{params[:azure_storage_account_type]}",
          "publicIPAddressName"=> "#{params[:azure_vm_name]}",
          "publicIPAddressType"=> "Dynamic",
          "vmStorageAccountContainerName"=> "#{params[:azure_vm_name]}",
          "vmName"=> "#{params[:azure_vm_name]}",
          "vmSize"=> "Standard_D1",
          "virtualNetworkName"=> "#{params[:azure_vnet_name]}",
          "vnetID"=> "[resourceId('Microsoft.Network/virtualNetworks',variables('virtualNetworkName'))]",
          "subnetRef"=> "[concat(variables('vnetID'),'/subnets/',variables('subnetName'))]",
          "apiVersion"=> "2015-06-15",
          "vmExtensionName"=> "#{params[:chef_extension]}",
        },
        "resources"=> [
          {
            "type"=> "Microsoft.Storage/storageAccounts",
            "name"=> "[variables('storageAccountName')]",
            "apiVersion"=> "[variables('apiVersion')]",
            "location"=> "[resourceGroup().location]",
            "properties"=> {
              "accountType"=> "[variables('storageAccountType')]"
            }
          },
          {
            "apiVersion"=> "[variables('apiVersion')]",
            "type" => "Microsoft.Network/publicIPAddresses",
            "name" => "[concat(variables('publicIPAddressName'),copyIndex())]",
            "location"=> "[resourceGroup().location]",
            "copy"=> {
              "name" => "publicIPLoop",
              "count"=> "[parameters('numberOfInstances')]"
            },
            "properties" => {
              "publicIPAllocationMethod" => "[variables('publicIPAddressType')]",
              "dnsSettings" => {
                "domainNameLabel" => "[concat(parameters('dnsLabelPrefix'), copyIndex())]"
              }
            }
          },
          {
            "apiVersion"=> "[variables('apiVersion')]",
            "type"=> "Microsoft.Network/virtualNetworks",
            "name"=> "[variables('virtualNetworkName')]",
            "location"=> "[resourceGroup().location]",
            "properties"=> {
              "addressSpace"=> {
                "addressPrefixes"=> [
                  "[variables('addressPrefix')]"
                ]
              },
              "subnets"=> [
                {
                  "name"=> "[variables('subnetName')]",
                  "properties"=> {
                    "addressPrefix"=> "[variables('subnetPrefix')]"
                  }
                }
              ]
            }
          },
          {
            "apiVersion"=> "[variables('apiVersion')]",
            "type"=> "Microsoft.Network/networkInterfaces",
            "name"=> "[concat(variables('nicName'),copyIndex())]",
            "location"=> "[resourceGroup().location]",
            "copy" => {
              "name" => "nicLoop",
              "count" => "[parameters('numberOfInstances')]"
            },
            "dependsOn" => [
              "[concat('Microsoft.Network/publicIPAddresses/', concat(variables('publicIPAddressName'),copyIndex()))]",
              "[concat('Microsoft.Network/virtualNetworks/', variables('virtualNetworkName'))]"
            ],
            "properties"=> {
              "ipConfigurations"=> [
                {
                  "name"=> "ipconfig1",
                  "properties"=> {
                    "privateIPAllocationMethod"=> "Dynamic",
                    "publicIPAddress"=> {
                      "id"=> "[resourceId('Microsoft.Network/publicIPAddresses',concat(variables('publicIPAddressName'),copyIndex()))]"
                    },
                    "subnet"=> {
                      "id"=> "[variables('subnetRef')]"
                    }
                  }
                }
              ]
            }
          },
          {
            "apiVersion"=> "[variables('apiVersion')]",
            "type"=> "Microsoft.Compute/virtualMachines",
            "name"=> "[concat(variables('vmName'),copyIndex())]",
            "location"=> "[resourceGroup().location]",
            "copy" => {
              "name" => "vmLoop",
              "count" => "[parameters('numberOfInstances')]"
            },
            "dependsOn"=> [
              "[concat('Microsoft.Storage/storageAccounts/', variables('storageAccountName'))]",
              "[concat('Microsoft.Network/networkInterfaces/', variables('nicName'), copyIndex())]",
            ],
            "properties"=> {
              "hardwareProfile"=> {
                "vmSize"=> "[variables('vmSize')]"
              },
              "osProfile"=> {
                "computerName"=> "[concat(variables('vmName'),copyIndex())]",
                "adminUserName"=> "[parameters('adminUserName')]",
                "adminPassword"=> "[parameters('adminPassword')]"
              },
              "storageProfile"=> {
                "imageReference"=> {
                  "publisher"=> "[variables('imagePublisher')]",
                  "offer"=> "[variables('imageOffer')]",
                  "sku"=> "[parameters('imageSKU')]",
                  "version"=> "[parameters('imageVersion')]"
                },
                "osDisk"=> {
                  "name"=> "[variables('OSDiskName')]",
                  "vhd"=> {
                    "uri"=> "[concat('http://',variables('storageAccountName'),'.blob.core.windows.net/',variables('vmStorageAccountContainerName'),'/',concat(variables('vmName'),copyIndex()),'.vhd')]"
                  },
                  "caching"=> "ReadWrite",
                  "createOption"=> "FromImage"
                }
              },
              "networkProfile"=> {
                "networkInterfaces"=> [
                  {
                    "id"=> "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('nicName'), copyIndex()))]"
                  }
                ]
              },
              "diagnosticsProfile"=> {
                "bootDiagnostics"=> {
                  "enabled"=> "true",
                  "storageUri"=> "[concat('http://',variables('storageAccountName'),'.blob.core.windows.net')]"
                }
              }
            }
          },
          {
            "type" => "Microsoft.Compute/virtualMachines/extensions",
            "name" => "[concat(variables('vmName'),copyIndex(),'/', variables('vmExtensionName'))]",
            "apiVersion" => "2015-05-01-preview",
            "location" => "[resourceGroup().location]",
            "copy" => {
              "name" => "extensionLoop",
              "count" => "[parameters('numberOfInstances')]"
            },
            "dependsOn" => [
              "[concat('Microsoft.Compute/virtualMachines/', variables('vmName'), copyIndex())]"
            ],
            "properties" => {
              "publisher" => "#{params[:chef_extension_publisher]}",
              "type" => "#{params[:chef_extension]}",
              "typeHandlerVersion" => "#{params[:chef_extension_version]}",
              "settings" => {
                "bootstrap_options" => {
                  "chef_node_name" => chef_node_name,
                  "chef_server_url" => "[parameters('chef_server_url')]",
                  "validation_client_name" => "[parameters('validation_client_name')]"
                },
                "runlist" => "[parameters('runlist')]",
                "autoUpdateClient" => "[parameters('autoUpdateClient')]",
                "deleteChefConfig" => "[parameters('deleteChefConfig')]",
                "uninstallChefClient" => "[parameters('uninstallChefClient')]",
                "validation_key_format" => "[parameters('validation_key_format')]"
              },
              "protectedSettings" => {
                "validation_key" => "[parameters('validation_key')]"
              }
            }
          }
        ]
      }
    end

    def create_deployment_parameters(params, platform)
      if platform == 'Windows'
        admin_user = params[:winrm_user]
        admin_password = params[:admin_password]
      else
        admin_user = params[:ssh_user]
        admin_password = params[:ssh_password]
      end

      parameters = {
        "adminUserName" => {
          "value" => "#{admin_user}"
        },
        "adminPassword"=> {
          "value"=> "#{admin_password}"
        },
        "dnsLabelPrefix"=> {
          "value"=> "#{params[:azure_vm_name]}"
        },
        "imageSKU"=> {
          "value"=> "#{params[:azure_image_reference_sku]}"
        },
        "numberOfInstances" => {
          "value" => "#{params[:server_count]}".to_i
        },
        "validation_key"=> {
          "value"=> "#{params[:chef_extension_private_param][:validation_key]}"
        },
        "chef_server_url"=> {
          "value"=> "#{params[:chef_extension_public_param][:bootstrap_options][:chef_server_url]}"
        },
        "validation_client_name"=> {
          "value"=> "#{params[:chef_extension_public_param][:bootstrap_options][:validation_client_name]}"
        },
        "runlist" => {
          "value" => "#{params[:chef_extension_public_param][:runlist]}"
        },
        "autoUpdateClient" => {
          "value" => "#{params[:chef_extension_public_param][:autoUpdateClient]}"
        },
        "deleteChefConfig" => {
          "value" => "#{params[:chef_extension_public_param][:deleteChefConfig]}"
        },
        "uninstallChefClient" => {
          "value" => "#{params[:chef_extension_public_param][:uninstallChefClient]}"
        },
        "chef_node_name" => {
          "value"=> "#{params[:chef_extension_public_param][:bootstrap_options][:chef_node_name]}"
        }
      }
    end

  end
end