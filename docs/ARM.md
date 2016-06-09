## Detailed Usage for ARM mode

### Common Configuration

ARM configuration options can be specified in your knife.rb file only.

The following options are required for all azurerm subcommands:

    option :azure_subscription_id            Your Azure subscription ID
    option :azure_tenant_id                  Your subscription's tenant id
    option :azure_client_id                  Your Active Directory Application id
    option :azure_client_secret              Your Active Directory Application's password

Note: The options mentioned above can be obtained from this [step](https://github.com/chef/knife-azure#arm-mode)

### Azure Server Create Subcommand
This subcommand provisions a new server in Azure and then performs a Chef bootstrap.

User can either provide just `--azure-image-os-type` or other image reference parameters i.e. `--azure-image-reference-publisher`, `--azure-image-reference-offer`, `--azure-image-reference-sku` and `--azure-image-reference-version` to specify the image.

Accepted values for `--azure-image-os-type` are `ubuntu`, `centos`, `rhel`, `debian ` and `windows`. It creates the server using standard image parameters for respective OS. However, they can be overridden using `--azure-image-reference-publisher`, `--azure-image-reference-offer`, `--azure-image-reference-sku` and `--azure-image-reference-version` options.
`--azure-image-os-type` option should not be used with other image reference parameters.

To see a list of commonly used image parameters, please refer https://azure.microsoft.com/en-in/documentation/articles/resource-groups-vm-searching/#table-of-commonly-used-images

For Windows:

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name MyNewVMName
  --azure-service-location 'WEST US'
  --azure-image-os-type windows
  -x myuser -P mypassword
  -r "recipe[cbk1::rec2]"
  -c ~/.chef/knife.rb
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name MyNewVMName
  --azure-service-location 'WEST US'
  --azure-image-reference-publisher 'MicrosoftWindowsServer'
  --azure-image-reference-offer 'WindowsServer'
  --azure-image-reference-sku '2012-R2-Datacenter'
  --azure-image-reference-version 'latest'
  -x myuser -P mypassword
  -r "recipe[cbk1::rec2]"
  -c ~/.chef/knife.rb
```

For Centos:

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name MyNewVMName
  --azure-service-location 'WEST US'
  --azure-image-os-type centos
  --azure-vm-size Small
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/knife.rb
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name MyNewVMName
  --azure-service-location 'WEST US'
  --azure-image-reference-publisher 'OpenLogic'
  --azure-image-reference-offer 'CentOS'
  --azure-image-reference-sku '6.5'
  --azure-image-reference-version 'latest'
  --ssh-user myuser --ssh-password mypassword
  --azure-vm-size Small
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/knife.rb
```

For Ubuntu:

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name MyNewVMName
  --azure-service-location 'WEST US'
  --azure-image-os-type ubuntu
  --ssh-user myuser --ssh-password mypassword
  --azure-vm-size Small
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/knife.rb
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name MyNewVMName
  --azure-service-location 'WEST US'
  --azure-image-reference-publisher 'Canonical'
  --azure-image-reference-offer 'UbuntuServer'
  --azure-image-reference-sku '14.04.2-LTS'
  --azure-image-reference-version 'latest'
  --ssh-user myuser --ssh-password mypassword
  --azure-vm-size Small
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/knife.rb
```

For Rhel:

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name MyNewVMName
  --azure-service-location 'WEST US'
  --azure-image-os-type rhel
  --ssh-user myuser --ssh-password mypassword
  --azure-vm-size Small
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/knife.rb
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name MyNewVMName
  --azure-service-location 'WEST US'
  --azure-image-reference-publisher 'RedHat'
  --azure-image-reference-offer 'RHEL'
  --azure-image-reference-sku '7.2'
  --azure-image-reference-version 'latest'
  --ssh-user myuser --ssh-password mypassword
  --azure-vm-size Small
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/knife.rb
```

For Debian:

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name MyNewVMName
  --azure-service-location 'WEST US'
  --azure-image-os-type debian
  --ssh-user myuser --ssh-password mypassword
  --azure-vm-size Small
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/knife.rb
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name MyNewVMName
  --azure-service-location 'WEST US'
  --azure-image-reference-publisher 'credativ'
  --azure-image-reference-offer 'Debian'
  --azure-image-reference-sku '7'
  --azure-image-reference-version 'latest'
  --ssh-user myuser --ssh-password mypassword
  --azure-vm-size Small
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/knife.rb
```

User can use existing virtual network and subnet while server create by providing `--azure-vnet-name` and `--azure-vnet-subnet-name` options.

Note:

1. If these options are not given, default vnet and subnet with the VM name will be created.
2. User needs to provide valid existing vnet name and subnet name otherwise it will raise vnet or subnet not found error.
3. Vnet should belong to the same resource group that is provided in the command.
4. Subnet should belong to the same vnet that is provided in the command.

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name MyNewVMName
  --azure-service-location 'WEST US'
  --azure-image-os-type ubuntu
  --ssh-user myuser --ssh-password mypassword
  --azure-vm-size Small
  --azure-vnet-name 'VnetName'
  --azure-vnet-subnet-name 'VnetSubnetName'
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/knife.rb
```

#### --server-count option
User can pass `--server-count` option to specify the number of servers to be created with same configuration.
```
--server-count COUNT         Number of servers to create with same configuration. Maximum count is 5. Default value is 1.

Command:
knife azurerm server create
--azure-resource-group-name MyResourceGrpName
--azure-vm-name MyNewVMName
--azure-service-location 'WEST US'
--azure-image-os-type centos
--azure-vm-size Small
--server-count 3
-x myuser -P mypassword
```
This will create 3 VMs with names: `MyNewVMName0`, `MyNewVMName1` and `MyNewVMName2`


### Azure Server Delete Subcommand
Deletes an existing ARM server in the currently configured Azure account. By default, this does not delete the associated resource-group, associated node and client objects from the Chef server.
For deleting associated resource-group along with server use --delete-resource-group flag.
For deleting associated node and client objects from the Chef server, add the --purge flag.

```
knife azurerm server delete MyVMName --azure-resource-group-name MyResourceGrpName -c ~/.chef/knife.rb

knife azurerm server delete MyVMName --azure-resource-group-name MyResourceGrpName -c ~/.chef/knife.rb --purge  #purge chef node

knife azurerm server delete MyVMName --azure-resource-group-name MyResourceGrpName -c ~/.chef/knife.rb --delete-resource-group #deletes resource group
```

### Azure Server List Subcommand
Outputs a list of all ARM servers in the currently configured Azure account. PLEASE NOTE - this shows all instances associated with the account, some of which may not be currently managed by the Chef server.

```
knife azurerm server list
```

### Azure Server Show Subcommand
Outputs the details of an ARM server.

```
knife azurerm server show MyVMName --azure-resource-group-name MyResourceGrpName -c ~/.chef/knife.rb
```