<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-azure 1.4.0.rc.2 release notes:
This release of knife-azure updates gem dependencies and adds bug fix and
feature improvements.

Special thanks go to contributor **Edmund Dipple** for addressing
[knife-azure 146](https://github.com/chef/knife-azure/pull/146) an issue
affecting the reliability of Windows VM creation.

Please file bugs or feature requests against the KNIFE_WINDOWS project at https://github.com/chef/knife-azure/issues.
More information on the contribution process for Chef projects can be found in the [Chef Contributions document](https://docs.chef.io/community_contributions.html).

## Release highlights

### `knife-azure #189`: Fix for failed bootstraps on some sysprepped images
For some sysprepped images, Azure would continue to report that the guest was
in the `provisioning` state and never report `ready`. As a result, `knife-azure`
would eventually timeout waiting for the "ready" state and fail the bootstrap.
A change has been made in this release so that failure to reach "ready" is no longer fatal and
results in a warning; `knife-azure` will move on to testing for WinRM
availability and will bootstrap if it can authenticate. See the issue [knife-azure #189](https://github.com/chef/knife-azure/issues/189).

### New `cloud-api` bootstrap feature
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


