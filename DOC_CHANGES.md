<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

# knife-azure 1.4.0 doc changes

### `azure_subnet_name` option to create new subnets
This option allows users to specify the name of a new subnet to create via the
`knife azure vnet create` subcommand. Despite the subcommand name, this command would
only update existing vnets, not create them. This option allows the vnet name
to be specified and will also correctly create vnets as the name of the
subcommand suggests.

### `cloud-api` value for `bootstrap_protocol_option` in server create
This option can be specified as an alternative to the 'winrm'
(default for Windows) or ssh (default for Linux) protocols as the way to
bootstrap a server. It uses Azure's VM Resource Extension feature to allow the
[Azure Guest Agent](http://blogs.msdn.com/b/mast/archive/2014/02/17/bginfo-guest-agent-extension-for-azure-vms.aspx)
to bootstrap (i.e. install, configure, and execute Chef-Client with a given
runlist) the node. It also installs Chef Client to run as a service / daemon
on the system.

This method of bootstrap offers several advantages including

* No Internet access is required on the guest
* There is no connectivity requirement between the knife workstation and the
guest. Connectivity is only needed to Azure, and then only to execute the
initial set of method calls to create the VM. Therefore, if the knife
workstation were to lose network connectivity or crash after requesting Azure
to bootstrap the node, bootstrapping with Chef Client would still succeed. In
the where WinRM or SSH is used, the knife workstation must stay connected
during almost the entire provisioining and bootstrap process.
* Latency and connection reliability are not an issue, since the execution of
provisioning and bootstrap have no network dependency.

Azure is able to do this because it maintains images of Chef Client within the
Azure datacenters, and provides an API for Chef to securely provide configuration
information (specifically a Chef Server URL, validation client name, and
validator key) to Azure. This information, along with Azure's image of Chef
Client, is then used by Azure's guest agent to install the Chef Client image
on the guest, create the correct Chef Client configuration for communicating
with the Chef Server, and then execute Chef Client.

### `auto_update_client` option for server create
This option only applies if the `cloud-api` value for the `bootstrap_protocol`
option is specified. In this case, the VM will be set to automatically update
to the latest version of the Chef extension, which upgrades the Chef Client to
the latest version. By default, Chef Client is only updated on the guest for
patch revision changes.




