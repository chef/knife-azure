# Knife Azure

## Description
A [knife] (http://docs.opscode.com/knife.html) plugin to create,
delete, and enumerate
[Windows Azure] (https://www.windowsazure.com)
resources to be managed by Chef.

## Installation
Be sure you are running the latest version of Chef, which can be installed
via:

    gem install chef

This plugin is distributed as a Ruby Gem. To install it, run:

    gem install knife-azure
    
Depending on your system's configuration, you may need to run this command
with root/administrator privileges.

## Configuration
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

## Basic Examples
The following examples assume that you've configured the publishsettings file
location in your knife.rb:

      # List images for use in creating new VM's:
      $ knife azure image list
        
      # List all VM's (including those not be managed by Chef)
      $ knife azure server list
  
      # Create and bootstrap an Ubuntu VM over ssh
      $ knife azure server create -N MyNewNode --azure-vm-size Medium --I 8fcc3d_Ubuntu-12_04-amd64-30GB -m 'West US' --ssh-user myuser --identity-file ~/.ssh/myprivatekey_rsa
  
      # Create and bootstrap a Windows VM over winrm
      $ knife azure server create --azure-dns-name MyNewServerName --azure-vm-size Medium --I 8fcc3d_Win2012-amd64-30GB -m 'West US' --winrm-user myuser --winrm-password 'mypassword' --bootstrap-protocol winrm --distro 'windows-chef-client-msi'
  
      # Delete a server and purge it from the Chef server
      $ knife azure server delete MyNewNode --purge -y

Use the --help option to read more about each subcommand. Eg:

    knife azure server create --help

## Detailed Usage

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
knife-azure depends on knife-windows: https://github.com/opscode/knife-windows
to bootstrap Windows machines via winrm (Basic, NTLM and Kerberos authentication) or ssh.

The distro/template to be used for bootstrapping is: https://github.com/opscode/knife-windows/blob/master/lib/chef/knife/bootstrap/windows-chef-client-msi.erb

Windows source images should have the WinRM service enabled and the
authentication should be set accordingly (Basic, NTLM and Kerberos). Firewall rules should be added accordingly to the source images. Refer to the link to configure this:
https://github.com/opscode/knife-windows#nodes

#### Azure-specific Options
      :azure_dns_name                   Required. The DNS prefix name that can be used to access the cloud
                                        service which is unique within Windows Azure. If you want to add
                                        new VM to an existing service/deployment, specify an exiting
                                        dns-name, along with --azure-connect-to-existing-dns option. Otherwise
                                        a new deployment is created.
      :azure_service_location           Required. Specifies the geographic location of the resource as the
                                        name of a datacenter location that is valid for your subscription. Eg:
                                        West US, East US, East Asia, Southeast Asia, North Europe, West Europe.
      :azure_source_image               Required. Specifies the name of the disk image to use to create
                                        the virtual machine. Do a "knife azure image list" to see a
                                        list of available images.
      :azure_storage_account            A name for the storage account that is unique within Windows Azure.
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
    knife[:tcp_endpoints]='66'
    knife[:udp_endpoints]='77,88,99'

#### Options for Bootstrapping a Windows Node in Azure

    :bootstrap_protocol           Default is winrm for a windows image
    :winrm_password               The WinRM password
    :winrm_port                   The WinRM port, by default this is 5985
    :winrm_transport              The WinRM transport type.  valid choices are [ssl, plaintext]
    :kerberos_keytab_file         The Kerberos keytab file used for authentication
    :kerberos_realm               The Kerberos realm used for authentication
    :kerberos_service             The Kerberos service used for authentication
    :ca_trust_file                The Certificate Authority (CA) trust file used for SSL transport

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

