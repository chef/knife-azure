<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

# knife-azure 1.6.0 doc changes

## Changes to `server create` subcommand

Updates to the `knife azure server create` subcommand include
`cloud-api` bootstrap protocol improvements for SSL and other
configuration options during node bootstrap.

### SSL configuration during `cloud-api` bootstrap
The following options specified on the knife-azure command-line or
from your local workstation's `knife` configuration (e.g.`knife.rb`) will be used to
configure the remote node

* `--node-ssl-verify-mode`: If this option is configured on the
`knife-azure` CLI or in `knife` configuration, its value will be
configured in the `client.rb` of the created remote node.
* **SSL Certificates for `cloud-api` boostrap**: When `knife-azure`
 bootstraps a newly created node, it will transfer the certificates
 from your local knife configuration (e.g. `knife.rb`) to the new node
 so that it can verify the same systems that knife on your
 workstations verifies such as your Chef Server. For more information on
 SSL certificate management, see the documentation for the [`knife ssl
 fetch`](https://docs.chef.io/knife_ssl_fetch.html) subcommand.

### `--bootstrap-version` support for `cloud-api` bootstrap
The `--bootstrap-version` option is now honored for `cloud-api`
bootstrap, so when `cloud-api` is specified for the
`--bootstrap-protocol` option, `--bootstrap-version` may be specified
to configure a specific version of the chef-client to install during bootstrap.

### `--azure-extension-client-config` option for `cloud-api` bootstrap
When using the Azure Chef extension to bootstrap a node by specifying
`--bootstrap-protocol` with the `cloud-api` option, the following
option may now be specified:

* `--azure-extension-client-config`: Optional. Path to a client.rb
  file for use by chef-client on the bootstrapped node. Only honored
  when the `--bootstrap-protocol` option is set to `cloud-api`'.

When this option is specified, configuration in the specified client.rb will be used by the
node, though `knife-azure` will configure a somewhat different `client.rb`
file that includes the one specified to
`--azure-extension-client-config`.

Note that settings managed by `knife-azure` such as the Chef Server,
run list, validation client name, etc., will override any settings
specified in the client.rb configured by
`--azure-extension-client-config`.

This option is useful for including any other additional custom
configuration for your environment on new nodes that is not otherwise configurable
from `knife-azure` commands.
