<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-azure 1.4.0.rc.1 release notes:
This release of knife-azure updates gem dependencies and adds bug fix and
feature improvements.

Special thanks go to contributor **Edmund Dipple** for addressing
[knife-azure 146](https://github.com/chef/knife-azure/pull/146) an issue
affecting the reliability of Windows VM creation.

Please file bugs or feature requests against the KNIFE_WINDOWS project at https://github.com/chef/knife-azure/issues.
More information on the contribution process for Chef projects can be found in the [Chef Contributions document](https://docs.chef.io/community_contributions.html).

## New `cloud-api` bootstrap feature
By specifying the value `cloud-api` for the `bootstrap_protocol` option of
`knife azure server create` instead of `winrm` or `ssh`, Microsoft Azure will install
Chef Client using its own internal mirror of Chef Client (it does not download
it from Chef's Internet facing URL's as in the conventional winrm / ssh
bootstrap). The process as a whole is asynchronous, so once the `knife azure
server create` command has create the VM, full provisioning and Chef
bootstrap will continue to occur even if the `knife` command is terminated
before it completes.

In general, systems bootstrapped via `cloud-api` do not require incoming or
outgoing Internet access.

## knife-azure on RubyGems and Github
https://rubygems.org/gems/knife-azure
https://github.com/chef/knife-azure

## Issues fixed in knife-azure 1.4.0.rc.1

See the
[CHANGELOG]([knife-azure 146](https://github.com/chef/knife-azure/blob/1.4.0.rc.1/CHANGELOG.md)
for the complete list of issues fixed in this release.


