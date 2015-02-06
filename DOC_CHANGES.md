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
This option can be specified as an alternative to the `winrm`
(default for Windows) or `ssh` (default for Linux) protocols as the way to
bootstrap a server. It uses Azure's VM Resource Extension feature to allow the
[Azure Guest Agent](http://blogs.msdn.com/b/mast/archive/2014/02/17/bginfo-guest-agent-extension-for-azure-vms.aspx) to bootstrap (i.e. install, configure, and execute Chef-Client with a given
runlist) the node. It also installs Chef Client to run as a service / daemon
on the system.

This is equivalent to using the Azure portal to create a Chef-enabled VM as
described in the [Chef documentation](https://docs.chef.io/azure_portal.html).

### `azure_vm_startup_timeout` option in server create
The number of minutes that knife-azure will wait for the virtual machine to reach the 'provisioning' state. Default is 10.

### `azure_vm_ready_timeout` option in server create
The number of minutes that knife-azure will wait for the virtual machine state to transition from 'provisioning' to 'ready'. Default is 15.

### `auth_timeout` option in server create
When boostrapping Windows nodes, this is the maximum time in minutes to wait
for authentication over the WinRM transport
to the node to succeed. The default value is 25 minutes. This wait starts
after the guest has reached the "ready" state (or waited unsuccessfully for
the "ready" the amount of time specified by the `azure_vm_ready_timeout` option.

#### Chef Client log output and troubleshooting
When `cloud-api` bootstrap is used, you `knife` does not capture the output of
the Chef Client run as it does when the WinRM or SSH protocols are used. The
knife tool will simply report on the status of the bootstrap process (e.g.
'provisioning', 'installing,' 'ready,' etc.) and any errors it encounters.

To obtain the output from the Chef Client run, the Chef log may be obtained from
the guest VM. See the [Chef documentation](https://docs.chef.io/azure_portal.html#log-files) for
creating Chef-enabled VM's from the Azure portal. Other status about the
provisioning of the VM with Chef may also be found on the VM's dashboard on
the Azure portal.

#### Advantages of the `cloud-api` bootstrap method
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
Azure datacenters, and provides an API for knife to securely provide configuration
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
