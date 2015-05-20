<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-azure 1.5.0 release notes:
This release of knife-azure updates gem dependencies and adds bug fix and
feature improvements.

Special thanks go to contributor **Seth Chisamore** for addressing
[knife-azure #204](https://github.com/chef/knife-azure/pull/204). This change ensures WinRM is configured to allow the initial chef-client run to succeed

Please file bugs or feature requests against the [KNIFE_AZURE](https://github.com/chef/knife-azure/issues) repository.
More information on the contribution process for Chef projects can be found in the [Chef Contributions document](https://docs.chef.io/community_contributions.html).

## Release highlights

### delete-chef-config option in knife azure server create command
This option works with --bootstrap-protocol cloud-api. It is used to set the value of deleteChefConfig for chef extension. It allows to delete chef configuration files during chef extension uninstall or update process. By default it's set to false and will not delete the configuration files.

### [knife-azure #204](https://github.com/chef/knife-azure/pull/204) Properly configure WinRM for bootstrapping; Fixes [#203](https://github.com/chef/knife-azure/pull/203)
This change adds two more options `winrm_max_timeout` and `winrm_max_memoryPerShell`. Theses options are useful if you have long-running run-lists and if the chef run might use a lot of memory. In most cases people don't need to set these, but if they see certain timeout or memory related errors during bootstrap, particularly on Win2k8r2, it may make sense to move these beyond the default.

### [knife-azure #195](https://github.com/chef/knife-azure/pull/195) Showing thumbprint with Server show command

## knife-azure on RubyGems and Github
https://rubygems.org/gems/knife-azure
https://github.com/chef/knife-azure

## Issues fixed in knife-azure 1.5.0
* [knife-azure #213](https://github.com/chef/knife-azure/pull/213) Typo in fetch_thumbprint method
* [knife-azure #188](https://github.com/chef/knife-azure/pull/188) Winrm port should not be configured if --bootstrap-protocol=cloud-api

See the
[CHANGELOG](https://github.com/chef/knife-azure/blob/1.5.0/CHANGELOG.md)
for the complete list of issues fixed in this release.


