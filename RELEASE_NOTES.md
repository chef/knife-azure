<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-azure 1.8.0 release notes:
In this release, The --chef-service-interval option has been renamed to --chef-daemon-interval.

Now supports the latest azure-sdk gem, version 0.9.0.

New options introduced:

`--azure_availability_set`, which allows the user to create virtual machines in specified availability set.

`--daemon`, which allows the user to configure the chef-client to run as a daemon by specifying `none`, `service`, or `task`. This option is only supported on Windows and requires the `--bootstrap-protocol` option to be set to `cloud-api`.

Please file bugs or feature requests against the [KNIFE_AZURE](https://github.com/chef/knife-azure/issues) repository.
More information on the contribution process for Chef projects can be found in the [Chef Contributions document](https://docs.chef.io/community_contributions.html).

## knife-azure on RubyGems and Github
https://rubygems.org/gems/knife-azure

https://github.com/chef/knife-azure

## Features added in this release:

See the [1.8.0 CHANGELOG](https://github.com/chef/knife-azure/blob/1.8.0/CHANGELOG.md) for the complete list of features added in this release.

Here is a partial list:

* Added `--azure_availability_set` option which allows the user to create virtual machine in specified availability set. [\#453](https://github.com/chef/knife-azure/pull/453) ([piyushawasthi](https://github.com/piyushawasthi))

* Added `--daemon` option for chef extension. [\#417](https://github.com/chef/knife-azure/pull/417) ([Vasu1105](https://github.com/Vasu1105))

## Issues fixed in this release:

See the [1.8.0 CHANGELOG](https://github.com/chef/knife-azure/blob/1.8.0/CHANGELOG.md) for the complete list of issues fixed in this release.

Here is a partial list:

* Master is broken for any azurerm server create operations that involve virtual networks [\#460](https://github.com/chef/knife-azure/pull/460) ([harikesh-kolekar](https://github.com/harikesh-kolekar))
* Running `azurerm server create` with Chef Environment argument does not correctly assign environment to the created node [\#456](https://github.com/chef/knife-azure/pull/456) ([dheerajd-msys](https://github.com/dheerajd-msys))
* Fix for `--delete-resource-group` works, but exits as failed [\#459](https://github.com/chef/knife-azure/pull/459) ([dheerajd-msys](https://github.com/dheerajd-msys))
* Can not create vms in required availability set (ARM) [\#453](https://github.com/chef/knife-azure/pull/453) ([piyushawasthi](https://github.com/piyushawasthi))
* Fix for azurerm command bootstrap was not happening fully [\#447](https://github.com/chef/knife-azure/pull/447) ([harikesh-kolekar](https://github.com/harikesh-kolekar))
* knife-azure does not work with latest Chefdk [\#445](https://github.com/chef/knife-azure/pull/445) ([harikesh-kolekar](https://github.com/harikesh-kolekar))
* Fix for `--node-ssl-verify-mode none` does not write appropriate value to resulting client.rb [\#437](https://github.com/chef/knife-azure/pull/437) ([piyushawasthi](https://github.com/piyushawasthi))
* Updated code to work with latest azure-sdk gems. [\#425](https://github.com/chef/knife-azure/pull/425)([dheerajd-msys](https://github.com/dheerajd-msys))