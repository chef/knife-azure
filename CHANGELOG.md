# knife-azure Change Log

## Last release: 1.4.0.rc.2 (2015/02/06)
* [knife-azure #189](https://github.com/chef/knife-azure/issues/189) Server Create failing for some custom sysprepped images
* [knife-azure #184](https://github.com/chef/knife-azure/pull/184) Disable certificate generation code for ssl transport until supported by knife-windows

## Release: 1.4.0.rc.1 (2015/02/05)
* [knife-azure #102](https://github.com/chef/knife-azure/pull/102) User specified ssh/winrm port 22/5985 instead of random port with --azure-connect-to-existing-dns option for server creation
* [knife-azure #179](https://github.com/chef/knife-azure/pull/179) Enable creation of new vnets
* [knife-azure #169](https://github.com/chef/knife-azure/pull/169) Enable automatic update of the Chef extension the Azure VM Chef Extension --auto-update-client
* [knife-azure #167](https://github.com/chef/knife-azure/pull/167) Include custom VM images in knife azure image list

## Release: 1.4.0.rc.0 (2014/12/02)
* [knife-azure #171](https://github.com/chef/knife-azure/pull/171) EXPERIMENTAL: Support for unreleased knife-windows 1.0 configuration option winrm\_authentication\_protocol
* [knife-azure #163](https://github.com/chef/knife-azure/pull/163) Remove the az prefix from DNS name when VM name is specified and DNS name is not specified
* [knife-azure #160](https://github.com/chef/knife-azure/pull/160) Support for adding winrm SSL certificate, for winrm ssl communication
* [knife-azure #157](https://github.com/chef/knife-azure/pull/157) Add integration tests
* [knife-azure #162](https://github.com/chef/knife-azure/pull/162) Documentation fix to remove extraneous dash and use real example of VM image
* [knife-azure #153](https://github.com/chef/knife-azure/pull/153) Resource extension support through knife-azure plugin -- cloud-api bootstrap without network transport

## Release: 1.3.0 (2014/07/31)
* Update specs to rspec 3
* [KNIFE-472] - clean up knife-azure gemspec dependencies
* Fixed wrong command in README
* server create should not delete storage account in cleanup - unless created storage account
* knife-azure server create is missing -j switch for json at first chef-client run.

## Previous  Release: 1.2.2 (2014/02/07)

**See source control commit history for earlier changes.**




