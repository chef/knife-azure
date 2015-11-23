# knife-azure Change Log

## 1.6.0.rc.0 (2015/11/23)

   * [knife-azure #249](https://github.com/chef/knife-azure/issues/249) params[:port] doesn't default correctly to 22 when bootstrapping over ssh, causing an xml error
   * [knife-azure #261](https://github.com/chef/knife-azure/pull/261) Added SSL certificate bootstrap support for cloud-api
   * [knife-azure #254](https://github.com/chef/knife-azure/issues/254) Unable to join servers to Active Directory due to username parsing ambiguity on command-line
   * [knife-azure #253](https://github.com/chef/knife-azure/pull/253) Configure node\_ssl\_verify\_mode during cloud-api extension bootstrap
   * [knife-azure #246](https://github.com/chef/knife-azure/pull/246) Support for chef-client version specification during cloud-api bootstrap
   * [knife-azure #255](https://github.com/chef/knife-azure/pull/255) Support for specifying a custom client.rb during cloud-api bootstrap
   * [knife-azure #247](https://github.com/chef/knife-azure/pull/247) README: recommend installing chef-dk rather than chef-client to use knife-azure
   * [knife-azure #244](https://github.com/chef/knife-azure/pull/244) Correctly configure subnet for vnet in server create
   * [knife-azure #245](https://github.com/chef/knife-azure/pull/245) README: Document CentOS support for cloud-api extension bootstrap

## Last release: 1.5.2 (2015/10/01)

* [knife-azure #218](https://github.com/chef/knife-azure/pull/218) Fixed azure\_availability\_set related issue
* [knife-azure #238](https://github.com/chef/knife-azure/pull/238) Fixed ssh tcp endpoint issue for cloud-api

## Release: 1.5.0 (2015/05/20)
* [knife-azure #228](https://github.com/chef/knife-azure/pull/228) Support for validatorless bootstrap, other Chef 12 bootstrap options
* [knife-azure #199](https://github.com/chef/knife-azure/issues/199) Azure China Support
* [knife-azure #213](https://github.com/chef/knife-azure/pull/213) Typo in fetch_thumbprint method
* [knife-azure #215](https://github.com/chef/knife-azure/pull/215) Added --delete-chef-config option in knife azure server create
* [knife-azure #204](https://github.com/chef/knife-azure/pull/204) Properly configure WinRM for bootstrapping; Fixes [#203](https://github.com/chef/knife-azure/pull/203)
* [knife-azure #197](https://github.com/chef/knife-azure/pull/197) Add custom json attributes to chef extension
* [knife-azure #211](https://github.com/chef/knife-azure/pull/211) Allow user to specify chef extension version by using knife_rb
* [knife-azure #198](https://github.com/chef/knife-azure/pull/198) Adding winrm\_ssl\_verify_mode to bootstrap config
* [knife-azure #196](https://github.com/chef/knife-azure/pull/196) Update Rubies; remove Chef-unsupported versions from matrix
* [knife-azure #195](https://github.com/chef/knife-azure/pull/195) Showing thumbprint with Server show command
* [knife-azure #188](https://github.com/chef/knife-azure/pull/188) Winrm port should not be configured if --bootstrap-protocol=cloud-api

## Release: 1.4.0 (2015/02/09)
* [knife-azure #189](https://github.com/chef/knife-azure/issues/189) Server Create failing for some custom sysprepped images
* [knife-azure #184](https://github.com/chef/knife-azure/pull/184) Disable certificate generation code for ssl transport until supported by knife-windows
* [knife-azure #102](https://github.com/chef/knife-azure/pull/102) User specified ssh/winrm port 22/5985 instead of random port with --azure-connect-to-existing-dns option for server creation
* [knife-azure #179](https://github.com/chef/knife-azure/pull/179) Enable creation of new vnets
* [knife-azure #169](https://github.com/chef/knife-azure/pull/169) Enable automatic update of the Chef extension the Azure VM Chef Extension --auto-update-client
* [knife-azure #167](https://github.com/chef/knife-azure/pull/167) Include custom VM images in knife azure image list
* [knife-azure #171](https://github.com/chef/knife-azure/pull/171) EXPERIMENTAL: Support for unreleased knife-windows 1.0.0 configuration option winrm\_authentication\_protocol
* [knife-azure #163](https://github.com/chef/knife-azure/pull/163) Remove the az prefix from DNS name when VM name is specified and DNS name is not specified
* [knife-azure #160](https://github.com/chef/knife-azure/pull/160) Support for adding winrm SSL certificate, for winrm ssl communication
* [knife-azure #157](https://github.com/chef/knife-azure/pull/157) Add integration tests
* [knife-azure #162](https://github.com/chef/knife-azure/pull/162) Documentation fix to remove extraneous dash and use real example of VM image
* [knife-azure #153](https://github.com/chef/knife-azure/pull/153) Resource extension support through knife-azure plugin --cloud-api bootstrap without network transport
* [knife-azure 146](https://github.com/chef/knife-azure/pull/146) Virtual machine state 'provisioning' not reached after 5 minutes

## Release: 1.3.0 (2014/07/31)
* Update specs to rspec 3
* [KNIFE-472] - clean up knife-azure gemspec dependencies
* Fixed wrong command in README
* server create should not delete storage account in cleanup - unless created storage account
* knife-azure server create is missing -j switch for json at first chef-client run.

## Previous  Release: 1.2.2 (2014/02/07)

**See source control commit history for earlier changes.**




