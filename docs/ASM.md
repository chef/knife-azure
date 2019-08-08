## Basic Examples for ASM

The following examples assume that you've configured the publishsettings file
location in your config.rb:

      # List images for use in creating new VM's:
      $ knife azure image list

      # List all VM's (including those not be managed by Chef)
      $ knife azure server list

      # Create and bootstrap a Windows VM over winrm (winrm is the default for Windows)
      $ knife azure server create --azure-dns-name MyNewServerName --azure-vm-size Standard_A2 -I a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-20150825-en.us-127GB.vhd --azure-service-location 'West US' --connection-user myuser --connection-password 'mypassword'

      # Create and bootstrap a Windows VM over winrm using SSL (winrm is the default for Windows)
      $ knife azure server create --azure-dns-name MyNewServerName --azure-vm-size Standard_A2 -I a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-20150825-en.us-127GB.vhd --azure-service-location 'West US' --connection-user myuser --connection-password 'mypassword' --winrm-ssl --winrm-no-verify-cert

      # Create and bootstrap an Ubuntu VM over ssh
      $ knife azure server create -N MyNewNode --azure-vm-size Standard_A2 -I b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_1-LTS-amd64-server-20140927-en-us-30GB -m 'West US' --connection-user myuser --ssh-identity-file ~/.ssh/myprivatekey_rsa

      # Create and bootstrap an Windows VM through the Azure API --
      # No winrm or ssh transport or Internet access required
      $ knife azure server create --azure-dns-name MyNewServerName --azure-vm-size Standard_A2 -I a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-20150825-en.us-127GB.vhd --azure-service-location 'West US' --connection-user myuser --connection-password 'mypassword' --connection-protocol cloud-api

      # Delete a server and purge it from the Chef server
      $ knife azure server delete MyNewNode --purge -y

Use the --help option to read more about each subcommand. Eg:

    knife azure server create --help


## Detailed Usage for ASM mode

### Common Configuration
Most configuration options can be specified either in your config.rb file or as command line parameters. The CLI parameters override the config.rb parameters.

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
Windows source images should have the WinRM service enabled and the
authentication should be set accordingly (Basic, NTLM and Kerberos). Firewall rules should be added accordingly to the source images. Refer to the link to configure this:
https://github.com/chef/knife-windows#nodes

#### Azure-specific Options
      --azure-dns-name                   Required. The DNS prefix name that can be used to access the cloud
                                         service which is unique within Microsoft Azure. If you want to add
                                         new VM to an existing service/deployment, specify an exiting
                                         dns-name, along with --azure-connect-to-existing-dns option. Otherwise
                                         a new deployment is created.
      --azure-service-location           Required. Specifies the geographic location of the resource as the
                                         name of a datacenter location that is valid for your subscription. Eg:
                                         West US, East US, East Asia, Southeast Asia, North Europe, West Europe.
      --azure-source-image               Required. Specifies the name of the disk image to use to create
                                         the virtual machine. Do a "knife azure image list" to see a
                                         list of available images.
      --azure-storage-account            A name for the storage account that is unique within Microsoft Azure.
                                         Storage account names must be between 3 and 24 characters in
                                         length and use numbers and lower-case letters only. This name is
                                         the DNS prefix name and can be used to access blobs, queues, and
                                         tables in the storage account.
      --azure-vm-name                    Specifies the name for the virtual machine. The name must
                                         be unique within the deployment.
      --azure-os-disk-name               Optional. Specifies the friendly name of the disk containing
                                         the guest OS image in the image repository.
      --azure-vm-size                    Size of virtual machine. Default is Standard_A1_v2.
                                         Eg: Standard_A2, Standard_F2, Standard_G1, Standard_F2 etc.
      --azure-connect-to-existing-dns    Set this flag to add the new VM to an existing
                                         deployment/service. Must give the name of the existing
                                         DNS correctly in the --azure-dns-name option
      --azure-availability-set           Optional. Name of availability set to add virtual machine into.

Note: For all valid --azure-vm-size values you can refer to this [docs](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes).

#### Azure VM Quick Create
You can create a server with minimal configuration. On the Azure Management Portal, this corresponds to a "Quick Create - VM". Sample command for quick create (for an Ubuntu instance):

    knife azure server create
                --azure-publish-settings-file '/path/to/your/cert.publishsettingsfile'
                --azure-dns-name 'myservice'
                --azure-service-location 'West US'
                --azure-source-image 'source-image-name'
                --connection-user 'jetstream'
                --ssh-identity-file '~/.ssh/myazure_rsa'

Note that the --ssh-identity-file option, which enables specification of a private
key authorized to communicate securely with the created server during the
bootstrap process, will also configure the user specified by --connection-user with
the public key that corresponds to the private key specified by
--ssh-identity-file. This configuration persists even after the create subcommand
has completed successfully, so that the key specified with --ssh-identity-file can
be used with ssh clients for subsequent access to the server as the user
specified by --connection-user.

You can set these options from config.rb. A typical config.rb is
shown below:

    knife[:azure_publish_settings_file] = '/path/to/your/cert.publishsettingsfile'
    knife[:azure_dns_name] = 'myservice'
    knife[:azure_service_location] = 'West US'
    knife[:azure_source_image] = 'source-image-name'
    knife[:connection_user] = 'jetstream'
    knife[:ssh_identity_file] = '~/.ssh/myazure_rsa'

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
                --connection-user 'jetstream'
                --connection-password 'jetstream@123'

These options may also be configured from config.rb, as in this example:

    knife[:azure_subscription_id] = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    knife[:azure_mgmt_cert] = '/path/to/your/mgmtCert.pem'
    knife[:azure_api_host_name] = 'management.core.windows.net'
    knife[:azure_service_location] = 'West US'
    knife[:azure_dns_name]='myservice'
    knife[:azure_vm_name]='myvm02'
    knife[:connection_user]='jetstream'
    knife[:ssh_identity_file]='/path/to/RSA/private/key'
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

    :connection_protocol           The protocol to use to connect to the target node. (valid options: 'ssh' or 'winrm')
    :connection_password           Authenticate to the target host with this password
    :winrm_auth_method             The WinRM authentication method to use. (valid options: 'plaintext', 'kerberos', 'ssl', or 'negotiate')
    :winrm_ssl                     Use SSL in the WinRM connection
    :connection_port               The port on the target node to connect to
    :ca_trust_file                 The CA certificate file to use to verify the server when using SSL
    :winrm_no_verify_cert          Do not verify the SSL certificate of the target node for WinRM
    :kerberos_realm                The Kerberos realm used for authentication
    :kerberos_service              The Kerberos service used for authentication


#### Options to configure WinRM for Bootstrapping a Windows Node
Theses options are useful if you have long-running run-lists and if the chef run might use a lot of memory. In most cases people don't need to set these, but if they see certain timeout or memory related errors during bootstrap, particularly on Win2k8r2, it may make sense to move these beyond the default.

    :winrm_max_timeout             Set winrm max timeout in minutes
    :winrm_max_memory_per_shell    Set winrm max memory per shell in MB

    Command:
    knife azure server create
            --azure-dns-name 'myserver'
            --azure-source-image 'windows-2012-image-id'
            --azure-service-location 'West US'
            --connection-user azure
            --connection-password 'azure@123'
            --winrm-max-timeout 30
            --winrm-max-memory-per-shell 400

#### Azure Windows Node Create
The quick create option requires the following options for a windows instance:

    knife azure server create
                --azure-publish-settings-file '/path/to/your/cert.publishsettingsfile'
                --azure-dns-name 'myserverdnsname'
                --azure-service-location 'West US'
                --azure-source-image 'windows-2012-image-id'
                --connection-user 'jetstream'
                --connection-password 'jetstream@123'

Sample config.rb for bootstrapping Windows Node with basic authentication

    knife[:connection_protocol] = 'winrm'
    knife[:connection_password] = 'mgcvTuvV2Rh'
    knife[:connection_user] = 'myuser'
    knife[:connection_port] = '5985'
    knife[:azure_source_image]='windows-2012-image-id'

#### `cloud-api` bootstrap feature
By specifying the value `cloud-api` for the `connection_protocol` option of `knife azure server create` instead of `winrm` or `ssh`, Microsoft Azure will install Chef Client using the `azure-chef-extension`. The process as a whole is asynchronous, so once the `knife azure server create` command has create the VM, full provisioning and Chef bootstrap will continue to occur even if the `knife` command is terminated before it completes.

We have added option `daemon` for Windows OS which configures the chef-client as a service or as a scheduled task for unattended execution. Accepted values are `none`, `service` and `task`.
    none - Currently prevents the chef-client service or scheduled task to be configured.
    service - Configures the chef-client to run automatically in the background as a service.
    task - Configures the chef-client to run automatically in the background as a scheduled task. So chef-client runs in a defined interval which is 30 mins by default.

Option `chef_daemon_interval` can be used for running the chef-client as a service or as a scheduled task in defined interval automatically in the background. Its value is 30 mins by default.


    knife azure server create
                --azure-publish-settings-file '/path/to/your/cert.publishsettingsfile'
                --azure-dns-name 'myserverdnsname'
                --azure-service-location 'West US'
                --azure-source-image 'windows-2012-image-id'
                --connection-user 'jetstream'
                --connection-password 'jetstream@123'
                --connection-protocol 'cloud-api'
                --daemon 'task'
                --chef-daemon-interval '18'


It's possible to pass bootstrap options to the extension which get specified in `client.rb` file on the VM. Following options can be passed:

    --environment
    --node-name
    --secret-file
    --server-url
    --validation-client-name
    --[no-]node-verify-api-cert
    --bootstrap-version
    --node-ssl-verify-mode
    --bootstrap-proxy
    --chef-daemon-interval
    --extended-logs


#### Azure Server Create with Domain Join
Following options are used for creating server with domain join

    :azure_domain_name      Specifies the domain name to join. If the domains name is not specified, --azure-domain-user must specify the user principal name (UPN) format (user@fully-qualified-DNS-domain) or the fully-qualified-DNS-domain\\username format
    :azure_domain_user      Specifies the username who has access to join the domain.Supported format: username(if domain is already specified in --azure-domain-name option),fully-qualified-DNS-domain\username, user@fully-qualified-DNS-domain
    :azure_domain_passwd    Specifies the password for domain user who has access to join the domain

    Command:
    knife azure server create -I a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-Datacenter-20151022-en.us-127GB.vhd --azure-vm-size Standard_A2 -U 'azure' -P 'admin@123' --azure-domain-passwd 'admin@123' --azure-domain-user 'some.domain.com\user' --azure-domain-name 'some.domain.com' -c '~\chef-repo\.chef\config.rb' --azure-network-name 'mynetwork' --azure-subnet-name 'subnet1' --azure-service-location 'West US'


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
