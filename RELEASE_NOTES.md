<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-azure 1.7.0 release notes:
In this release, few options have been removed since their support has been removed from the azure-chef-extension. The options are: `--auto-update-client`, `--uninstall-chef-client` and `--delete-chef-extension-config`. They were earlier supported with `cloud-api` bootstrap protocol which uses azure-chef-extension for installing chef-client.

New options introduced:
`--chef-service-interval`, which lets the user specify the frequency at which chef-client service should run. This option is available for both ASM and ARM commands. For ASM, it's supported with `cloud-api` bootstrap protocol.

`--extended-logs` shows chef convergence logs in detail. This option is available for both ASM and ARM commands. For ASM, it's supported with `cloud-api` bootstrap protocol.

Please file bugs or feature requests against the [KNIFE_AZURE](https://github.com/chef/knife-azure/issues) repository.
More information on the contribution process for Chef projects can be found in the [Chef Contributions document](https://docs.chef.io/community_contributions.html).

## knife-azure on RubyGems and Github
https://rubygems.org/gems/knife-azure
https://github.com/chef/knife-azure

## Features added in this release:

See the [1.7.0 CHANGELOG](https://github.com/chef/knife-azure/blob/1.7.0/CHANGELOG.md)
for the complete list of features added in this release.

Here is a partial list:

* Added chef_service_interval option and moved encrypted_data_bag_secret option from public_config to private_config for chef_extension: [\#408](https://github.com/chef/knife-azure/pull/408) ([Aliasgar16](https://github.com/Aliasgar16))
* Added support to show extended logs in ASM bootstrap command: [\#400](https://github.com/chef/knife-azure/pull/400) ([Aliasgar16](https://github.com/Aliasgar16))
* Added support for extended logs to knife arm bootstrap command: [\#398](https://github.com/chef/knife-azure/pull/398) ([Aliasgar16](https://github.com/Aliasgar16))
* Add support passing of tcp port option in ARM: [\#394](https://github.com/chef/knife-azure/pull/394) ([dheerajd-msys](https://github.com/dheerajd-msys))
* Added support for running Xplat command in case of token expiry: [\#378](https://github.com/chef/knife-azure/pull/378) ([dheerajd-msys](https://github.com/dheerajd-msys))
* Added support for extended_logs to show chef-client run logs to user in ARM server_create command: [\#372](https://github.com/chef/knife-azure/pull/372) ([Aliasgar16](https://github.com/Aliasgar16))

## Issues fixed in this release:

See the [1.7.0 CHANGELOG](https://github.com/chef/knife-azure/blob/1.7.0/CHANGELOG.md)
for the complete list of issues fixed in this release.

Here is a partial list:

* Fix for handing certificate with thumbprint no found error: [\#413](https://github.com/chef/knife-azure/pull/413) ([Vasu1105](https://github.com/Vasu1105))
* Handling `credential without -0--` pattern: [\#412](https://github.com/chef/knife-azure/pull/412) ([NimishaS](https://github.com/NimishaS))
* Allow using relative path for config files: [\#392](https://github.com/chef/knife-azure/pull/392) ([Vasu1105](https://github.com/Vasu1105))
* Added support to handle existing vnet and subnet resources in resource group while server creation: [\#383](https://github.com/chef/knife-azure/pull/383) ([Aliasgar16](https://github.com/Aliasgar16))
* azurerm bootstrap fails if the version of chef extension is not given in knife.rb file: [\#379](https://github.com/chef/knife-azure/pull/379) ([Aliasgar16](https://github.com/Aliasgar16))
* Showing text error message instead of json: [\#376](https://github.com/chef/knife-azure/pull/376) ([NimishaS](https://github.com/NimishaS))
* Fixed eval failure on some ruby versions and specs failure: [\#375](https://github.com/chef/knife-azure/pull/375) ([dheerajd-msys](https://github.com/dheerajd-msys))





