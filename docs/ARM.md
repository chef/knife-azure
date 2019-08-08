## Detailed Usage for ARM mode

### Common Configuration

ARM configuration options can be specified in your config.rb file only.

The following options are required for all azurerm subcommands:

    option :azure_subscription_id            Your Azure subscription ID
    option :azure_tenant_id                  Your subscription's tenant id
    option :azure_client_id                  Your Active Directory Application id
    option :azure_client_secret              Your Active Directory Application's password

Note: The options mentioned above can be obtained from this [step](docs/configuration.md#arm-mode).

### Azure Server Create Subcommand
This subcommand provisions a new server in Azure and then performs a Chef bootstrap.

User can either provide just `--azure-image-os-type` or other image reference parameters i.e. `--azure-image-reference-publisher`, `--azure-image-reference-offer`, `--azure-image-reference-sku` and `--azure-image-reference-version` to specify the image.

Accepted values for `--azure-image-os-type` are `ubuntu`, `centos`, `rhel`, `debian ` and `windows`. It creates the server using standard image parameters for respective OS. Along with `--azure-image-os-type` option, `--azure-image-reference-sku` can also be passed, else default value of `--azure-image-reference-sku` will be used.

However, they can be overridden using `--azure-image-reference-publisher`, `--azure-image-reference-offer`, `--azure-image-reference-sku` and `--azure-image-reference-version` options.

Note: `--azure-image-os-type` option should not be passed with `--azure-image-reference-publisher`, `--azure-image-reference-offer` and `--azure-image-reference-version` option

To see a list of commonly used image parameters, please refer https://azure.microsoft.com/en-in/documentation/articles/resource-groups-vm-searching/#table-of-commonly-used-images

By default --azure-vm-size will be Standard_A1_v2 and For all valid --azure-vm-size values you can refer to this [docs](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes).

For Windows:

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-os-type windows
  -U myuser -P mypassword
  -r "recipe[cbk1::rec2]"
  -c ~/.chef/config.rb
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-reference-publisher 'MicrosoftWindowsServer'
  --azure-image-reference-offer 'WindowsServer'
  --azure-image-reference-sku '2012-R2-Datacenter'
  --azure-image-reference-version 'latest'
  -U myuser -P mypassword
  -r "recipe[cbk1::rec2]"
  -c ~/.chef/config.rb
```

For Centos:

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-os-type centos
  --azure-image-reference-sku '6.5'
  --azure-vm-size Standard_A1_v2
  --connection-user myuser --connection-password mypassword
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/config.rb
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-reference-publisher 'OpenLogic'
  --azure-image-reference-offer 'CentOS'
  --azure-image-reference-sku '6.5'
  --azure-image-reference-version 'latest'
  --connection-user myuser --connection-password mypassword
  --azure-vm-size Standard_A1_v2
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/config.rb
```

For Ubuntu:

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-os-type ubuntu
  --azure-image-reference-sku '14.04.2-LTS'
  --connection-user myuser --connection-password mypassword
  --azure-vm-size Standard_A1_v2
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/config.rb
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-reference-publisher 'Canonical'
  --azure-image-reference-offer 'UbuntuServer'
  --azure-image-reference-sku '14.04.2-LTS'
  --azure-image-reference-version 'latest'
  --connection-user myuser --connection-password mypassword
  --azure-vm-size Standard_A1_v2
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/config.rb
```

For Rhel:

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-os-type rhel
  --connection-user myuser --connection-password mypassword
  --azure-vm-size Standard_A1_v2
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/config.rb
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-reference-publisher 'RedHat'
  --azure-image-reference-offer 'RHEL'
  --azure-image-reference-sku '7.2'
  --azure-image-reference-version 'latest'
  --connection-user myuser --connection-password mypassword
  --azure-vm-size Standard_A1_v2
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/config.rb
```

For Debian:

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-os-type debian
  --connection-user myuser --connection-password mypassword
  --azure-vm-size Standard_A1_v2
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/config.rb
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-reference-publisher 'credativ'
  --azure-image-reference-offer 'Debian'
  --azure-image-reference-sku '7'
  --azure-image-reference-version 'latest'
  --connection-user myuser --connection-password mypassword
  --azure-vm-size Standard_A1_v2
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/config.rb
```

User can also pass names for virtual network and subnet while server create by providing `--azure-vnet-name` and `--azure-vnet-subnet-name` options. Following are the possible scenarios for the usage of these two options:

1. ***--azure-vnet-name* and *--azure-vnet-subnet-name* options not provided by user** : `--azure-vm-name` will be taken as the default value for both the options.

2. ***--azure-vnet-name* and *--azure-vnet-subnet-name* options provided by user** : User provided values will be assigned to these options respectively.

3. ***--azure-vnet-name* option provided by user but *--azure-vnet-subnet-name* option not provided by user** : `--azure-vm-name` will be assigned as the default value to the `--azure-vnet-subnet-name` option.

4. ***--azure-vnet-subnet-name* option provided by user but *--azure-vnet-name* option not provided by user** : It will raise error saying `--azure-vnet-name` option must also be specified with the `--azure-vnet-subnet-name` option.


**Note**:

***
*Vnet* and *Subnet* names can be *user provided* or it can also be *default valued*.
***

- *Vnet* and *Subnet*, if do not exist, will be newly created in the resource group while server creation.
- *Vnet* and *Subnet*, if exist, will be used while server creation.
- *Vnet*, if exists and *Subnet*, does not exist, then new subnet will be added in the virtual network.
- *Vnet name* can be specified with or without *Subnet name*. However, *Subnet name* can only be specified with *Vnet name*.
- Value as `GatewaySubnet` cannot be used as the name for the `--azure-vnet-subnet-name option`.

***New subnet addition in virtual network or use of existing subnet for server creation completely depends on the address space availability in the virtual network or in the existing subnet itself respectively.***

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-os-type ubuntu
  --connection-user myuser --connection-password mypassword
  --azure-vm-size Standard_A1_v2
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/config.rb
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-os-type ubuntu
  --connection-user myuser --connection-password mypassword
  --azure-vm-size Standard_A1_v2
  --azure-vnet-name 'VnetName'
  --azure-vnet-subnet-name 'VnetSubnetName'
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/config.rb
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-os-type ubuntu
  --connection-user myuser --connection-password mypassword
  --azure-vm-size Standard_A1_v2
  --azure-vnet-name 'VnetName'
  -r "recipe[cbk1::rec1]"
  -c ~/.chef/config.rb
```

#### --server-count option
User can pass `--server-count` option to specify the number of servers to be created with same configuration.
```
--server-count COUNT         Number of servers to create with same configuration. Maximum count is 5. Default value is 1.

Command:
knife azurerm server create
--azure-resource-group-name MyResourceGrpName
--azure-vm-name my-new-vm-name
--azure-service-location 'westus'
--azure-image-os-type centos
--azure-vm-size Standard_A1_v2
--server-count 3
-U myuser -P mypassword
```
This will create 3 VMs with names: `my-new-vm-name0`, `my-new-vm-name1` and `my-new-vm-name2`

#### --extended-logs option
User can pass `--extended-logs` option to show detailed chef convergence logs.
```
--extended-logs              Optional. It shows chef convergence logs in detail.
Command:
knife azurerm server create
--azure-resource-group-name MyResourceGrpName
--azure-vm-name my-new-vm-name
--azure-service-location 'westus'
--azure-image-os-type centos
--azure-vm-size Standard_A1_v2
--extended-logs
-U myuser -P mypassword
```

#### --tcp-endpoints option
User can pass `--tcp-endpoints` option to open the comma seperated ports passed with the option
```
-t, --tcp-endpoints PORT_LIST    Comma-separated list of TCP ports to open e.g. '100,123'
Command:
knife azurerm server create
--azure-resource-group-name MyResourceGrpName
--azure-vm-name my-new-vm-name
--azure-service-location 'westus'
--azure-image-os-type centos
--azure-vm-size Standard_A1_v2
--tcp-endpoints '100,123'
-U myuser -P mypassword
```

#### --ohai-hints option
User can pass `--ohai-hints` option to set the hints passed in the ohai configuration of the target node
```
--ohai-hints HINT_OPTIONS    Hint option names to be set in Ohai configuration of the target node.
                             Supported values are: `vm_name, public_fqdn and platform.`
                             User can pass either one of the above value or combination of them.
                             e.g. 'vm_name,public_fqdn'
                             Default value is 'default' if the option is not set, in which case all three parameters
                             will be passed to ohai configuration
Command:
knife azurerm server create
--azure-resource-group-name MyResourceGrpName
--azure-vm-name my-new-vm-name
--azure-service-location 'westus'
--azure-image-os-type centos
--azure-vm-size Standard_A1_v2
--ohai-hints 'vm_name,platform'
-U myuser -P mypassword
```

#### --azure-storage-account
User can pass `--azure-storage-account` option to set storage account name.
```
-a, --azure-storage-account NAME Required for advanced server-create option.
                                      A name for the storage account that is unique within Windows Azure.
                                      Storage account names must be between 3 and 24 characters in length
                                      and use numbers and lower-case letters only. Please note that the 24
                                      character limit includes a prepended unique string generated by
                                      knife-azure. In the event that you receive an error that your
                                      storage account name is not valid, you may simply need to shorten
                                      your selected storage account name to account for this.
                                      This name is the DNS prefix name and can be used to access blobs, queues
                                      and tables in the storage account.
                                      Default value is `vm name`

Command:
knife azurerm server create
--azure-resource-group-name MyResourceGrpName
--azure-vm-name my-new-vm-name
--azure-service-location 'westus'
--azure-image-os-type centos
--azure-vm-size Standard_A1_v2
--azure-storage-account 'teststorage'
-U myuser -P mypassword
```

#### --chef-daemon-interval
User can pass `--chef-daemon-interval` option to specify the frequency(in minutes) at which chef-service runs. Default value is `30` minutes. If you don't want chef-service to be installed, set `--chef-daemon-interval` as 0.
```
--chef-daemon-interval INTERVAL  Optional. It specifies the frequency
                                  (in minutes) at which the chef-service runs.
                                  Pass 0 if you don't want the chef-service to be installed on the target machine.

Command:
knife azurerm server create
--azure-resource-group-name MyResourceGrpName
--azure-vm-name my-new-vm-name
--azure-service-location 'westus'
--azure-image-os-type centos
--azure-vm-size Standard_A1_v2
--azure-storage-account 'teststorage'
-U myuser -P mypassword
```

#### --azure-availability-set
User can pass `--azure-availability-set` name option to add virtual machine into that. Availability set limit 2-5.
```
--azure-availability-set NAME   Optional. Name of availability set to add virtual machine into.

Command:
knife azurerm server create
--azure-resource-group-name MyResourceGrpName
--azure-vm-name my-new-vm-name
--azure-availability-set MyAvailabilitySetName
--azure-service-location 'eastus'
--azure-image-os-type windows
--node-ssl-verify-mode none
-U myuser -P mypassword
-c ~/.chef/config.rb
```

### Azure Server Delete Subcommand
Deletes an existing ARM server in the currently configured Azure account. By default, this does not delete the associated resource-group, associated node and client objects from the Chef server.
For deleting associated resource-group along with server use --delete-resource-group flag.
For deleting associated node and client objects from the Chef server, add the --purge flag.

```
knife azurerm server delete MyVMName --azure-resource-group-name MyResourceGrpName -c ~/.chef/config.rb

knife azurerm server delete MyVMName --azure-resource-group-name MyResourceGrpName -c ~/.chef/config.rb --purge  #purge chef node

knife azurerm server delete MyVMName --azure-resource-group-name MyResourceGrpName -c ~/.chef/config.rb --delete-resource-group #deletes resource group
```

### Azure Server List Subcommand
Outputs a list of all ARM servers in the currently configured Azure account. PLEASE NOTE - this shows all instances associated with the account, some of which may not be currently managed by the Chef server.

```
knife azurerm server list
```

### Azure Server Show Subcommand
Outputs the details of an ARM server.

```
knife azurerm server show MyVMName --azure-resource-group-name MyResourceGrpName -c ~/.chef/config.rb
```

#### `daemon` feature
We have added option `daemon` for Windows OS which configures the chef-client as a service or as a scheduled task for unattended execution. Accepted values are `none`, `service` and `task`.
    none - Currently prevents the chef-client service or scheduled task to be configured.
    service - Configures the chef-client to run automatically in the background as a service.
    task - Configures the chef-client to run automatically in the background as a scheduled task. So chef-client runs in a defined interval which is 30 mins by default.

Option `chef_daemon_interval` can be used for running the chef-client as a service or as a scheduled task in defined interval automatically in the background. Its value is 30 mins by default.

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-os-type windows
  -U myuser -P mypassword
  -r "recipe[cbk1::rec2]"
  -c ~/.chef/config.rb
  --daemon 'task'
  --chef-daemon-interval '18'
```
OR
```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name my-new-vm-name
  --azure-service-location 'westus'
  --azure-image-reference-publisher 'MicrosoftWindowsServer'
  --azure-image-reference-offer 'WindowsServer'
  --azure-image-reference-sku '2012-R2-Datacenter'
  --azure-image-reference-version 'latest'
  -U myuser -P mypassword
  -r "recipe[cbk1::rec2]"
  -c ~/.chef/config.rb
  --daemon 'task'
  --chef-daemon-interval '18'
```

It's possible to pass bootstrap options to the extension which get specified in `client.rb` file on the VM. Following options can be passed:

    --environment
    --node-name
    --secret-file
    --server
    --validation-client-name
    --[no-]node-verify-api-cert
    --bootstrap-version
    --node-ssl-verify-mode
    --bootstrap-proxy
    --chef-daemon-interval
    --extended-logs
