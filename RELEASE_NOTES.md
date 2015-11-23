<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-azure 1.6.0.rc.0 release notes:
This release of knife-azure improves node bootstrap configuration
support for the `cloud-api` bootstrap protocol option. Improvements include configuration of SSL
communication options and SSL certificates on the node. This brings
`cloud-api` bootstrap, in which chef-client installation is performed
without a network connection between the `knife-azure` workstation and
the node, closer to functional parity with the older
network-based bootstrap techniques that use protocols like `ssh` and `WinRM`.

Please file bugs or feature requests against the [KNIFE_AZURE](https://github.com/chef/knife-azure/issues) repository.
More information on the contribution process for Chef projects can be found in the [Chef Contributions document](https://docs.chef.io/community_contributions.html).

## knife-azure on RubyGems and Github
https://rubygems.org/gems/knife-azure
https://github.com/chef/knife-azure

## Issues fixed in this release:

See the [1.6.0.rc.0 CHANGELOG](https://github.com/chef/knife-azure/blob/1.6.0.rc.0/CHANGELOG.md)
for the complete list of issues fixed in these releases.

Here is a partial list:

* [knife-azure #249](https://github.com/chef/knife-azure/issues/249) params[:port] doesn't default correctly to 22 when bootstrapping over ssh, causing an xml error
* [knife-azure #261](https://github.com/chef/knife-azure/pull/261) Added SSL certificate bootstrap support for cloud-api
* [knife-azure #254](https://github.com/chef/knife-azure/issues/254) Unable to join servers to Active Directory due to username parsing ambiguity on command-line
* [knife-azure #253](https://github.com/chef/knife-azure/pull/253) Configure node\_ssl\_verify\_mode during cloud-api extension bootstrap
* [knife-azure #246](https://github.com/chef/knife-azure/pull/246) Support for chef-client version specification during cloud-api bootstrap
* [knife-azure #255](https://github.com/chef/knife-azure/pull/246) Support for specifying a custom client.rb during cloud-api bootstrap
* [knife-azure #247](https://github.com/chef/knife-azure/pull/246) README: recommend installing chef-dk rather than chef-client to use knife-azure
* [knife-azure #244](https://github.com/chef/knife-azure/pull/244) Correctly configure subnet for vnet in server create
* [knife-azure #245](https://github.com/chef/knife-azure/pull/244) README: Document CentOS support for cloud-api extension bootstrap




