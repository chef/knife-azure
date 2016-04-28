# Knife Azure

[![Gem Version](https://badge.fury.io/rb/knife-azure.svg)](https://rubygems.org/gems/knife-azure)
[![Build Status](https://travis-ci.org/chef/knife-azure.svg?branch=master)](https://travis-ci.org/chef/knife-azure)


## Description
A [knife] (http://docs.chef.io/knife.html) plugin to create,
delete, and enumerate
[Microsoft Azure] (https://azure.microsoft.com)
resources to be managed by Chef.

## Installation
Be sure you are running the latest version of Chef DK, which can be installed
via:

    https://downloads.chef.io/chef-dk/

This plugin is distributed as a Ruby Gem. To install it, run:

```bash
chef gem install knife-azure
```

Depending on your system's configuration, you may need to run this command
with root/administrator privileges.

## Modes
`knife-azure 1.6.0.rc.0` onwards, we are adding support for Azure Resource Manager. You can easily switch between the

* Service management: commands using the Azure service management API
* Resource manager: commands using the Azure Resource Manager API

They are not designed to work together. Commands starting with `knife azure` use ASM mode, while commands starting with `knife azurerm` use ARM mode.

PLEASE NOTE that `Azuererm` subcommands are experimental and of alpha quality. Not suitable for production use. Please use ASM subcommands for production.

## Configuration

### ASM mode
For this plugin to interact with Azure's REST API, you will need to give Knife
information about your Azure account and credentials. The easiest way to do
this is to sign in to the Azure portal and download a publishsettings file
from https://manage.windowsazure.com/publishsettings/index?client=xplat to a
local file system location, and
then refer to the local file via an entry in your knife.rb:

    knife[:azure_publish_settings_file] = "~/myazure.publishsettings"

Alternatively, all subcommands for this plugin will accept an
--azure-publish-settings-file option to allow you to specify the path to that
file with each command invocation.

The plug-in also accepts authentication information specified using an
alternative set of options -- see the section on "Alternative Management
Certificate Specification" for details.

The plug-in can also read Azure account and credentials from the `Azure Profile` if Knife does not have the entry for `publish_settings_file`.
An `Azure Profile` is a `JSON` file with subscription and environment information in it. Its default location is `~/.azure/azureProfile.json`.

The Azure Profile file can be created and manipulated using the [Azure CLI](http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-command-line-tools/). You can
also refer [Azure Xplat-CLI](https://github.com/Azure/azure-xplat-cli#use-publish-settings-file-management-certificate-authentication).

If Azure Profile file has entries for multiple subscriptions then you can choose the default using `azure account set <subscription_name>`. The same default subscription will
be picked up that you have configured.

### ARM mode
ARM mode requires setting up service principal for authentication and permissioning. For setting up a service principal from the command line please refer
[Authenticating a service principal with Azure Resource Manager](http://aka.ms/cli-service-principal) or
[Unattended Authentication](http://aka.ms/auth-unattended). For detailed explanation of authentication in Azure,
see [Developer’s guide to auth with Azure Resource Manager API](http://aka.ms/arm-auth-dev-guide).

After creating the service principal, you should have these 3 values, a client id (GUID), client secret(string) and tenant id (GUID).


## Basic Examples for ASM
The following examples assume that you've configured the publishsettings file
location in your knife.rb:

      # List images for use in creating new VM's:
      $ knife azure image list

      # List all VM's (including those not be managed by Chef)
      $ knife azure server list

      # Create and bootstrap a Windows VM over winrm (winrm is the default for Windows)
      $ knife azure server create --azure-dns-name MyNewServerName --azure-vm-size Medium -I a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-20150825-en.us-127GB.vhd --azure-service-location 'West US' --winrm-user myuser --winrm-password 'mypassword'

      # Create and bootstrap a Windows VM over winrm using SSL (winrm is the default for Windows)
      $ knife azure server create --azure-dns-name MyNewServerName --azure-vm-size Medium -I a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-20150825-en.us-127GB.vhd --azure-service-location 'West US' --winrm-user myuser --winrm-password 'mypassword' --winrm-transport ssl --winrm-ssl-verify-mode verify_none

      # Create and bootstrap an Ubuntu VM over ssh
      $ knife azure server create -N MyNewNode --azure-vm-size Medium -I b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_1-LTS-amd64-server-20140927-en-us-30GB -m 'West US' --ssh-user myuser --identity-file ~/.ssh/myprivatekey_rsa

      # Create and bootstrap an Windows VM through the Azure API --
      # No winrm or ssh transport or Internet access required
      $ knife azure server create --azure-dns-name MyNewServerName --azure-vm-size Medium -I a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-20150825-en.us-127GB.vhd --azure-service-location 'West US' --winrm-user myuser --winrm-password 'mypassword' --bootstrap-protocol cloud-api

      # Delete a server and purge it from the Chef server
      $ knife azure server delete MyNewNode --purge -y

Use the --help option to read more about each subcommand. Eg:

    knife azure server create --help

## Detailed Usage for ASM mode

### Common Configuration
Most configuration options can be specified either in your knife.rb file or as command line parameters. The CLI parameters override the knife.rb parameters.

The following options are required for all subcommands:

    option :azure_publish_settings_file      Path to your .publishsettings file

OR

    option :azure_subscription_id            Your Azure subscription ID
    option :azure_mgmt_cert                  Management certificate in PEM format
    option :azure_api_host_name              Your Azure API host name

### Azure Image List Subcommand
Outputs a list of all linux images that are available to use for provisioning. You should choose one of these to use for the :azure_source_image parameter to the server create command. You can use the filter option to see a detailed image list.

    knife azure image list

### Azure Server Create Subcommand
This subcommand provisions a new server in Azure and then performs a Chef bootstrap. The goal of the bootstrap is to get Chef installed on the target system so it can run Chef Client with a Chef Server.

#### Windows Bootstrapping Requirements
knife-azure depends on knife-windows: https://github.com/chef/knife-windows
to bootstrap Windows machines via WinRM (Basic, NTLM and Kerberos authentication) or ssh.

The distro/template to be used for bootstrapping is: https://github.com/chef/knife-windows/blob/master/lib/chef/knife/bootstrap/windows-chef-client-msi.erb

Windows source images should have the WinRM service enabled and the
authentication should be set accordingly (Basic, NTLM and Kerberos). Firewall rules should be added accordingly to the source images. Refer to the link to configure this:
https://github.com/chef/knife-windows#nodes

#### Azure-specific Options
      :azure_dns_name                   Required. The DNS prefix name that can be used to access the cloud
                                        service which is unique within Microsoft Azure. If you want to add
                                        new VM to an existing service/deployment, specify an exiting
                                        dns-name, along with --azure-connect-to-existing-dns option. Otherwise
                                        a new deployment is created.
      :azure_service_location           Required. Specifies the geographic location of the resource as the
                                        name of a datacenter location that is valid for your subscription. Eg:
                                        West US, East US, East Asia, Southeast Asia, North Europe, West Europe.
      :azure_source_image               Required. Specifies the name of the disk image to use to create
                                        the virtual machine. Do a "knife azure image list" to see a
                                        list of available images.
      :azure_storage_account            A name for the storage account that is unique within Microsoft Azure.
                                        Storage account names must be between 3 and 24 characters in
                                        length and use numbers and lower-case letters only. This name is
                                        the DNS prefix name and can be used to access blobs, queues, and
                                        tables in the storage account.
      :azure_vm_name                    Specifies the name for the virtual machine. The name must
                                        be unique within the deployment.
      :azure_os_disk_name               Optional. Specifies the friendly name of the disk containing
                                        the guest OS image in the image repository.
      :azure_vm_size                    Size of virtual machine. Default is Small.
                                        (ExtraSmall, Small, Medium, Large, ExtraLarge)
      :azure_connect_to_existing_dns    Set this flag to add the new VM to an existing
                                        deployment/service. Must give the name of the existing
                                        DNS correctly in the --azure-dns-name option
      :azure_availability_set           Optional. Name of availability set to add virtual machine into.

#### Azure VM Quick Create
You can create a server with minimal configuration. On the Azure Management Portal, this corresponds to a "Quick Create - VM". Sample command for quick create (for an Ubuntu instance):

    knife azure server create
                --azure-publish-settings-file '/path/to/your/cert.publishsettingsfile'
                --azure-dns-name 'myservice'
                --azure-service-location 'West US'
                --azure-source-image 'source-image-name'
                --ssh-user 'jetstream'
                --identity-file '~/.ssh/myazure_rsa'

Note that the --identity-file option, which enables specification of a private
key authorized to communicate securely with the created server during the
bootstrap process, will also configure the user specified by --ssh-user with
the public key that corresponds to the private key specified by
--identity-file. This configuration persists even after the create subcommand
has completed successfully, so that the key specified with --identity-file can
be used with ssh clients for subsequent access to the server as the user
specified by --ssh-user.

You can set these options from knife.rb. A typical knife.rb is
shown below:

    knife[:azure_publish_settings_file] = '/path/to/your/cert.publishsettingsfile'
    knife[:azure_dns_name] = 'myservice'
    knife[:azure_service_location] = 'West US'
    knife[:azure_source_image] = 'source-image-name'
    knife[:ssh_user] = 'jetstream'
    knife[:identity_file] = '~/.ssh/myazure_rsa'

#### Azure VM Advanced Create
You can set various other options in the advanced create.
  Eg: If you want to set the Azure VM Name different from that of the Azure DNS Name, set the option :azure_vm_name.
  Eg: If you want to specify a Storage Account Name, set the option :azure_storage_account

To connect to an existing DNS/service, you can use a command as below:

    knife azure server create
                --azure-subscription-id 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                --azure-mgmt-cert '/path/to/your/mgmtCert.pem'
                --azure-api-host-name 'management.core.windows.net'
                --azure-connect-to-existing-dns
                --azure-dns-name 'myservice'
                --azure-vm-name 'myvm02'
                --azure-service-location 'West US'
                --azure-source-image 'source-image-name'
                --ssh-user 'jetstream'
                --ssh-password 'jetstream@123'

These options may also be configured from knife.rb, as in this example:

    knife[:azure_subscription_id] = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    knife[:azure_mgmt_cert] = '/path/to/your/mgmtCert.pem'
    knife[:azure_api_host_name] = 'management.core.windows.net'
    knife[:azure_service_location] = 'West US'
    knife[:azure_dns_name]='myservice'
    knife[:azure_vm_name]='myvm02'
    knife[:ssh_user]='jetstream'
    knife[:identity_file]='/path/to/RSA/private/key'
    knife[:azure_storage_account]='auxpreview104'
    knife[:azure_os_disk_name]='disk107'
    knife[:tcp-endpoints]='80:80,3389:5678'
    knife[:udp-endpoints]='123:123'

#### Endpoint configuration

Endpoints are configured using tcp-endpoints and udp-endpoints. This is a string in the form:
{localPort}:{publicPort}:{load_balancer_set_name}:{load_balancer_probe_path}

Examples:

    knife[:tcp-endpoints]='80'                            # Allow Port 80 inbound
    knife[:tcp-endpoints]='80:8080'                       # Allow Port 80 inbound and map it to local port 8080
    knife[:tcp-endpoints]='80:8080:web-set'               # Allow Port 80 and add it to the load balancing set called 'web-set'
    knife[:tcp-endpoints]='80:8080:web-set:/healthcheck'  # Allow Port 80, add it to the load balancing set, and use an HTTP probe at path "/healthcheck"

Note that the load balancing set will be created if it does not exist. If it exists within another VM in the cloud service, it will re-use those values for the probe.

#### Options for Bootstrapping a Windows Node in Azure

    :bootstrap_protocol            Default is winrm for a windows image
    :winrm_password                The WinRM password
    :winrm_authentication_protocol Defaults to negotiate, supports kerberos, can be set to basic for debugging
    :winrm_transport               Defaults to plaintext, use ssl for improved privacy
    :winrm_port                    Defaults to 5985 plaintext transport, or 5986 for SSL
    :ca_trust_file                 The CA certificate file to use to verify the server when using SSL
    :winrm_ssl_verify_mode         Defaults to verify_peer, use verify_none to skip validation of the server certificate during testing
    :kerberos_keytab_file          The Kerberos keytab file used for authentication
    :kerberos_realm                The Kerberos realm used for authentication
    :kerberos_service              The Kerberos service used for authentication


#### Options to configure WinRM for Bootstrapping a Windows Node
Theses options are useful if you have long-running run-lists and if the chef run might use a lot of memory. In most cases people don't need to set these, but if they see certain timeout or memory related errors during bootstrap, particularly on Win2k8r2, it may make sense to move these beyond the default.

    :winrm_max_timeout             Set winrm max timeout in minutes
    :winrm_max_memoryPerShell      Set winrm max memory per shell in MB

    Command:
    knife azure server create
            --azure-dns-name 'myserver'
            --azure-source-image 'windows-2012-image-id'
            --azure-service-location 'West US'
            --winrm-user azure
            --winrm-password 'azure@123'
            --winrm-max-timeout 30
            --winrm-max-memoryPerShell 400

#### Azure Windows Node Create
The quick create option requires the following options for a windows instance:

    knife azure server create
                --azure-publish-settings-file '/path/to/your/cert.publishsettingsfile'
                --azure-dns-name 'myserverdnsname'
                --azure-service-location 'West US'
                --azure-source-image 'windows-2012-image-id'
                --winrm-user 'jetstream'
                --winrm-password 'jetstream@123'
                --distro 'windows-chef-client-msi'

Sample knife.rb for bootstrapping Windows Node with basic authentication

    knife[:bootstrap_protocol] = 'winrm'
    knife[:winrm_password] = 'mgcvTuvV2Rh'
    knife[:winrm_user] = 'myuser'
    knife[:winrm_port] = '5985'
    knife[:distro] = 'windows-chef-client-msi'
    knife[:azure_source_image]='windows-2012-image-id'

#### `cloud-api` bootstrap feature
By specifying the value `cloud-api` for the `bootstrap_protocol` option of `knife azure server create` instead of `winrm` or `ssh`, Microsoft Azure will install Chef Client using its own internal mirror of Chef Client (it does not download it from Chef's Internet facing URL's as in the conventional winrm / ssh bootstrap). The process as a whole is asynchronous, so once the `knife azure server create` command has create the VM, full provisioning and Chef bootstrap will continue to occur even if the `knife` command is terminated before it completes.

In general, systems bootstrapped via `cloud-api` do not require incoming or outgoing Internet access.

    knife azure server create
                --azure-publish-settings-file '/path/to/your/cert.publishsettingsfile'
                --azure-dns-name 'myserverdnsname'
                --azure-service-location 'West US'
                --azure-source-image 'windows-2012-image-id'
                --winrm-user 'jetstream'
                --winrm-password 'jetstream@123'
                --bootstrap-protocol 'cloud-api'
                --delete-chef-extension-config

We have also added cloud-api support for Centos now, for this you just need to select centos image in above example.

`--delete-chef-extension-config` determines if Chef configuration files should be removed when Azure removes the Chef resource extension from the VM or not. This option is only valid for the 'cloud-api' bootstrap protocol. The default value is false. This is useful when `update` and `uninstall` commands are run for the extension on the VM created.

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


#### Azure Server Create with Domain Join
Following options are used for creating server with domain join

    :azure_domain_name      Specifies the domain name to join. If the domains name is not specified, --azure-domain-user must specify the user principal name (UPN) format (user@fully-qualified-DNS-domain) or the fully-qualified-DNS-domain\\username format
    :azure_domain_user      Specifies the username who has access to join the domain.Supported format: username(if domain is already specified in --azure-domain-name option),fully-qualified-DNS-domain\username, user@fully-qualified-DNS-domain
    :azure_domain_passwd    Specifies the password for domain user who has access to join the domain

    Command:
    knife azure server create -I a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-Datacenter-20151022-en.us-127GB.vhd --azure-vm-size Medium  -x 'azure' -P 'admin@123' --azure-domain-passwd 'admin@123' --azure-domain-user 'some.domain.com\user' --azure-domain-name 'some.domain.com' -c '~\chef-repo\.chef\knife.rb' --azure-network-name 'mynetwork' --azure-subnet-name 'subnet1' --azure-service-location 'West US'


### Azure Server Delete Subcommand
Deletes an existing server in the currently configured Azure account. By
default, this does not delete the associated node and client objects from the
Chef server. To do so, add the --purge flag. Also by default, the DNS name, also called "cloud service", is deleted if you are deleting the last VM from that service. By default, the OS disk is also deleted. The underlying VHD blob is also deleted by default. If you want to retain them add the --preserve flag as shown below. To delete the storage account, add the --delete-azure-storage-account flag since by default the storage account is not deleted.

    knife azure server delete "myvm01"
    knife azure server delete "myvm01" --purge  #purge chef node
    knife azure server delete "myvm01" --preserve-azure-os-disk
    knife azure server delete "myvm01" --preserve-azure-vhd
    knife azure server delete "myvm01" --preserve-azure-dns-name
    knife azure server delete "myvm01" --delete-azure-storage-account

Since the VM name can be the same across DNS name, you must specify the DNS
name also to delete the VM. Sample command to delete a VM for a given DNS name:

    knife azure server delete "myvm01" --azure-dns-name "mydnsname"
    knife azure server delete "myvm01" "myvm02" --azure-dns-name "mydnsname"

### Azure Server List Subcommand
Outputs a list of all servers in the currently configured Azure account. PLEASE NOTE - this shows all instances associated with the account, some of which may not be currently managed by the Chef server.

    knife azure server list

### Azure AG List Subcommand
Outputs a list of defined affinity groups in the azure subscription.

    knife azure ag list

### Azure AG Create Subcommand
Creates a new affinity group in the specified service location.

    knife azure ag create -a 'mynewag' -m 'West US' --azure-ag-desc 'Optional Description'

Knife options:

    :azure_affinity_group       Specifies new affinity group name.
    :azure_service_location     Specifies the geographic location.
    :azure_ag_desc              Optional. Description for new affinity group.

### Azure Internal LB List Subcommand
Outputs a lit of defined load balancers for all cloud services. Public facing load balancers are not shown here.

### Azure Internal LB Create Subcommand
Creates a new Internal Load Balancer within a cloud service.

    knife azure internal lb create -n 'my_lb' --azure-lb-static-vip '10.0.0.123' --azure-subnet_name 'Subnet_1' --azure-dns-name 'service_name'

Knife options:
      :azure_load_balancer      Required. Specifies the name of the Load Balancer.
      :azure_lb_static_vip      Optional. Allows you to set a static IP for the VIP.
      :azure_subnet_name        Required ONLY IF azure_lb_static_ip is set. Specifies the subnet that the static IP resides in.
      :azure_dns_name           Required. The cloud service that this internal Load Balancer will be added to.

### Azure Vnet List Subcommand
Outputs a list of defined virtual networks in the azure subscription.

    knife azure vnet list

### Azure Vnet Create Subcommand
Creates a new or modifies an existing virtual network. If an existing virtual network is named, the
affinity group and address space are replaced with the new values.

    knife azure vnet create -n 'mynewvn' -a 'existingag' --azure_address_space '10.0.0.0/24'

Knife options:

    :azure_network_name         Specifies the name of the virtual network to create.
    :azure_affinity_group       Specifies the affinity group to associate with the vnet.
    :azure_address_space        Specifies the address space of the vnet using CIDR notation.

For CIDR notation, see here: http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing
Address available are defined in RFC 1918: http://en.wikipedia.org/wiki/Private_network

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

Accepted values for `--azure-image-os-type` are `ubuntu`, `centos`, `redhat`, `debian ` and `windows`. It creates the server using standard image parameters for respective OS. However, they can be overridden using `--azure-image-reference-publisher`, `--azure-image-reference-offer`, `--azure-image-reference-sku` and `--azure-image-reference-version` options.
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

For Redhat:

```
knife azurerm server create
  --azure-resource-group-name MyResourceGrpName
  --azure-vm-name MyNewVMName
  --azure-service-location 'WEST US'
  --azure-image-os-type redhat
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


## Alternative Management Certificate Specification
In addition to specifying the management certificate using the publishsettings
file, you can also specify it in PEM format. Follow these steps to generate the certificate in the PEM format:

1. Download the settings file from https://manage.windowsazure.com/publishsettings/index?client=xplat
2. Extract the data from the ManagementCertificate field into a separate file named - cert.pfx
3. Decode the certificate file:

#### On Linux/Mac(Homebrew)

    base64 -d cert.pfx > cert_decoded.pfx

#### On Windows
You can decode and extract the PFX file using powershell or a free windows base 64 decoder such as http://www.fourmilab.ch/webtools/base64/base64.zip,

    base64.exe -d cert.pfx -> cert_decoded.pfx

4. Convert the decoded PFX file to a PEM file

#### On Linux/Mac(Homebrew)

    openssl pkcs12 -in cert_decoded.pfx -out managementCertificate.pem -nodes

#### On Windows
 Use powershell & run following command. If openssl.exe is not already installed it can be downloaded from http://www.openssl.org/related/binaries.html (Note: openssl depends on Microsoft Visual C++ Redistributable package (x86) which must be installed for openssl to function properly).

    openssl base64 -d -A -in cert_decoded.pfx -out cert_decode.der

    openssl pkcs12 -in cert_decoded.der -out managementCertificate.pem -nodes

You might be asked to enter a password which is usually blank.
You might be also asked to enter a passphrase. Please enter the phrase of your choice.

It is possible to generate your own certificates and upload them. More Detailed Documentation about the Management Certificates is available : https://www.windowsazure.com/en-us/manage/linux/common-tasks/manage-certificates/

