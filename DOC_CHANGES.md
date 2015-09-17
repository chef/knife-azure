<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

# knife-azure 1.5.0 doc changes

## Azure China Support via `--azure-api-host-name` configuration
All `knife-azure` commands can use Azure's China cloud by specifying the
management API endpoint for that cloud,
`management.core.chinacloudapi.cn` using the `--azure-api-host-name`
option. As an example:

    knife azure server list --azure-api-host-name management.core.chinacloudapi.cn

Note that the Azure subscription in your `knife` configuration must
support using the API endpoint you specify.


## `server create` subcommand changes

Updates to the `knife azure server create` subcommand center primarily
around improved security and additional VM configuration.

### --winrm-ssl-verify-mode

`knife-azure`'s `server create` subcommand  supports bootstrap using
the `WinRM` protocol. If the `--winrm-transport` option for the
command is set to `ssl`, the new Azure VM will be confifgured with a
`WinRM` endpoint that uses SSL to secure communication, and the
subcommand will also utilize SSL to communicate with that endpoint (or, alternatively, a
different listener configured out-of-band from the `knife` subcommand), and validate the identity of the server using a
public certificate. If you do not have such a public certificate, the
`server create` subcommand won't be able to guarantee the identity of the server, but can
still communicate privately with it during the bootstrap process.

The option that controls whether the server is validated is the
`knife[:winrm_verify_ssl_mode]` option, which has the same values as Chef's
[`:ssl_verify_mode`](https://docs.chef.io/config_rb_client.html#settings) option. By default, the option is set to `:verify_peer`,
which means that SSL communication must be verified using a certificate file
specified by the `:ca_trust_file` option. To avoid the need to have this file available
during testing, you can specify the `knife[:winrm_ssl_verify_mode]` option in
`knife.rb` OR specify it directly on the `knife` command line as
`--winrm-ssl-verify-mode` and set its value to `:verify_none`, which will
override the default behavior and skip the verification of the remote system
-- there is no need to specify the `:ca_trust_file` option in this case.

Here's an example that disables peer verification:

    knife azure server create -I $MY_WIN_IMAGE -x 'myuser' -P $PASSWORDVAR -t ssl --winrm-ssl-verify-mode verify_none

This option should be used carefully since disabling the verification of the
remote system's certificate can subject knife commands to spoofing attacks.

### Additional options for `cloud-api` bootstrap (Azure Chef extension)

When creating an Azure node via the `server create` subcommand with the configuration value
  `--bootstrap-protocol` set to `cloud-api`, the following options may
  be specified to configure the remote node:

* `chef_node_name`
* `environment`
* `encrypted_data_bag_secret`
* `chef_server_url`
* `validation_client_name`
* `node_verify_api_cert`

#### `--custom-json-attr` for `cloud-api` bootstrap

The `custom-json-attr` option allows for the specification of
arbitrary JSON that can be passed to the Azure Resource Manager
extension used to bootstrap Chef on the node. For documenation on the
structure of the JSON and options that may be specified, see the
[README](https://github.com/chef-partners/azure-chef-extension) for the Azure Chef extension.

#### `--azure-chef-extension-version` flag
This option allows the user to specify a particular version of the
Azure Resource Manager Chef extension. This is useful when testing
extension versions deployed internally to a subscription or in the
case that a newer version of the extension exposes compatibility
issues with your image or other aspects of your Chef usage.

Azure command-line tools can be used to list all the versions of the
Chef extension. There is a Chef extension for Windows, `ChefClient`,
and on for Linux, `LinuxChefClient`, that supports Ubuntu and CentOS
distributions. When the `server create` subcommand is used with the
`--bootstrap-protocol` options specified as `cloud-api`, `knife-azure`
instructs Azure to use the correct extension depending on whether
operating system is Windows or Linux.

Here is an example that lists all versions of the Windows and Linux
extensions using the
[Azure cross-platform tools](https://github.com/Azure/azure-xplat-cli)
which can be executed from any operating system, including Linux, Windows, or MacOS:

    azure vm extension list -n LinuxChefClient -p Chef.Bootstrap.WindowsAzure --all-versions
    azure vm extension list -n ChefClient -p Chef.Bootstrap.WindowsAzure --all-versions

Here are the equivalent PowerShell (Windows only) commands using the [Azure PowerShell CLI](https://github.com/Azure/azure-powershell):

    Get-AzureVMAvailableExtension -allversions -ExtensionName LinuxChefClient -Publisher Chef.Bootstrap.WindowsAzure | format-table
    Get-AzureVMAvailableExtension -allversions -ExtensionName ChefClient -Publisher Chef.Bootstrap.WindowsAzure | format-table

#### `--auto-update-client` flag
Set the `--auto-update-client` flag to enable Azure's VM guest agent to automatically update
the extension on the VM, and most likely update Chef itself to a new version, every time a new Chef
extension is published (currently every Chef release). The flag is
disabled by default.

#### `--delete-chef-config` for Azure Chef extension uninstallation
By default, if the Chef extension is removed from the VM (via Azure
CLI tools or via Azure's API), the Chef configuration files remain on
the system. Setting this flag when creating the VM will ensure that
the configuration is removed if the Chef extension is removed.
Removing the extension will also uninstall Chef Client itself whether or not
this flag is set.

#### WinRM memory and timeout configuration
The `--winrm-max-memory-pershell` and `--winrm-max-timeout` configure
the `MaxMemoryPerShellMB` and `MaxTimeoutms` WinRM stack's command
execution settings on a remote Windows node being bootstrapped. These
settings for Windows VM's only instruct Azure to configure the VM's memory and timeout limits for remote
commands executed via the WinRM protocol before attempting to
bootstrap the node.

These limits affect how much memory
recipes executed during the bootstrap process's Chef client run may consume and how much time the
bootstrap takes. This can cause bootstraps to fail in unpredictable
ways, and leave nodes in a partially converged state. While most
recipes will not encounter issues if these options are not configured,
versions of Windows prior to Windows Server 2012 R2 had much lower
defaults for these limits, and configuration of the limits was
required to make Chef Client runs over WinRM succeed for resource /
time-intensive runlists.

As an example, setting `--winrm-max-memorypershell` to 4000000
megabytes and `--winrm-max-timeout` to 1200000 microseconds allows the `knife azure server create` command's remote
bootstrap commands to consume 4 gigabytes of memory and take 20
minutes. Use of these commands is

Note that these settings do not affect bootstraps conducted using the
`cloud-api` setting for `--bootstrap-protocol`, which does not use
WinRM, though the settings will still affect WinRM configuration for
that VM.

For detailed information on these limits, visit the entries for
`MaxMemoryPerShellMB` and `MaxTimeoutms` in [Microsoft's WinRM documentation](https://msdn.microsoft.com/en-us/library/aa384372(v=vs.85).aspx).

### Domain join capability for `server create` subcommand

The `server create` subcommand supports joining the Windows VM created
by the command to an Active Directory domain. The following options enable configuration of a new system's
domain membership:


* `--azure-domain-name DOMAIN_NAME`: *Optional*. Specifies the domain
  name to join.
* `--azure-domain-user`: If the domain is name is not specified using
the `--azure-domain-name` option, the user must specify this option using the user principal name (UPN) format e.g.
(user@my.fqdn.school.edu) or else use the unambiguous format
`fully-qualified-DNS-domain\username`
* `--azure-domain-ou-dn DOMAIN_OU_DN`: *Optional*. Specifies the
  (LDAP) X500-distinguished name of the organizational unit (OU) in
  which the computer account is created. This account is in Active
  Directory on a domain controller in the domain to which the computer
  is being joined. Example: `OU=operations,dc=contoso,dc=com`
* `--azure-domain-user DOMAIN_USER_NAME`: Specifies the username of a domain user with access to join the system to the domain.
* `--azure-domain-passwd DOMAIN_PASSWD`: Specifies the password for the user specified through the `--azure-domain-passwd` option.






