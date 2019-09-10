# knife-azure Change Log

<!-- latest_release -->
<!-- latest_release -->

<!-- release_rollup -->
<!-- release_rollup -->

<!-- latest_stable_release -->
## [v2.0.2](https://github.com/chef/knife-azure/tree/v2.0.2) (2019-09-10)

#### Merged Pull Requests
- Minor Fixes while displaying Error Messages [#503](https://github.com/chef/knife-azure/pull/503) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
<!-- latest_stable_release -->

## [v2.0.1](https://github.com/chef/knife-azure/tree/v2.0.1) (2019-08-22)

#### Merged Pull Requests
- DOC updates for OSS Best Practices [#502](https://github.com/chef/knife-azure/pull/502) ([Nimesh-Msys](https://github.com/Nimesh-Msys))

## [v2.0.0](https://github.com/chef/knife-azure/tree/v2.0.0) (2019-08-08)

#### Merged Pull Requests
- Support for Chef-15 [#500](https://github.com/chef/knife-azure/pull/500) ([Nimesh-Msys](https://github.com/Nimesh-Msys))

## [v1.9.0](https://github.com/chef/knife-azure/tree/v1.9.0) (2019-02-21)

#### Merged Pull Requests
- Fix for unable to create VM with Standard_F2 or any valid sizes [#489](https://github.com/chef/knife-azure/pull/489) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Clarify character limit for azure-storage-account [#463](https://github.com/chef/knife-azure/pull/463) ([OBrienCommaJosh](https://github.com/OBrienCommaJosh))
- Require Ruby 2.3+ and fix Chefstyle offenses [#494](https://github.com/chef/knife-azure/pull/494) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Fix for undefined method get_vm_size error and fixing the missing code which not reflected after resolving conflict in previous merge [#495](https://github.com/chef/knife-azure/pull/495) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Upgraded version of knife-azure azure-sdk libraries.  [#491](https://github.com/chef/knife-azure/pull/491) ([Vasu1105](https://github.com/Vasu1105))
- Tidy up bootstrap.md  [#493](https://github.com/chef/knife-azure/pull/493) ([stuartpreston](https://github.com/stuartpreston))
- Fix for wrong number of arguments error while using extended logs option. [#497](https://github.com/chef/knife-azure/pull/497) ([Vasu1105](https://github.com/Vasu1105))

## [v1.8.7](https://github.com/chef/knife-azure/tree/v1.8.7) (2018-12-04)

#### Merged Pull Requests
- Don&#39;t ship the readme in the gem artifact [#492](https://github.com/chef/knife-azure/pull/492) ([tas50](https://github.com/tas50))

## [v1.8.6](https://github.com/chef/knife-azure/tree/v1.8.6) (2018-11-20)

#### Merged Pull Requests
- Remove github changelog generator dep [#479](https://github.com/chef/knife-azure/pull/479) ([tas50](https://github.com/tas50))
- Test on modern Ruby releases in Travis [#480](https://github.com/chef/knife-azure/pull/480) ([tas50](https://github.com/tas50))
- Remove require on highline as knife does this [#482](https://github.com/chef/knife-azure/pull/482) ([tas50](https://github.com/tas50))
- Add github issue/PR templates and a codeowners file [#484](https://github.com/chef/knife-azure/pull/484) ([tas50](https://github.com/tas50))
- Fix for validatorless bootstrap. [#487](https://github.com/chef/knife-azure/pull/487) ([Vasu1105](https://github.com/Vasu1105))



## [v1.8.0](https://github.com/chef/knife-azure/tree/v1.8.0) (2017-09-28)

[Full Changelog](https://github.com/chef/knife-azure/compare/v1.7.0...v1.8.0)

**Closed issues:**
- `--delete-resource-group` works, but exits as failed [\#458](https://github.com/chef/knife-azure/issues/458)
- Master is broken for any azurerm server create operations that involve virtual networks [\#455](https://github.com/chef/knife-azure/issues/455)
- Running `azurerm server create` with Chef Environment argument does not correctly assign environment to the created node [\#454](https://github.com/chef/knife-azure/issues/454)
- Can not create vms in required availability set (ARM) [\#446](https://github.com/chef/knife-azure/issues/446)
- Bootstrapping in Azurerm is not happenning fully. [\#449](https://github.com/chef/knife-azure/issues/449)
- knife-azure does not work with latest Chefdk [\#440](https://github.com/chef/knife-azure/issues/440)
- Auto-Generated Storage Account Name can produce an Exception [\#434](https://github.com/chef/knife-azure/issues/434)
- node_name in client.rb always has a '0' appended resulting in auth error [\#439](https://github.com/chef/knife-azure/issues/439)
- Knife Azure does not work with berkshelf [\#423](https://github.com/chef/knife-azure/issues/423)
- --node-ssl-verify-mode none' does not write appropriate value to resulting client.rb [\#435](https://github.com/chef/knife-azure/issues/435)
- knife azure server delete doesn't delete servers joined to a domain [\#258](https://github.com/chef/knife-azure/issues/258)

**Merged pull requests:**

- Update missing function for V0.9.0 [\#460](https://github.com/chef/knife-azure/pull/460)
- Updated code to delete server with resource group [\#459](https://github.com/chef/knife-azure/pull/459)
- Switches ARM > ASM language in documentation. Removes warning from ARM mode [\#457](https://github.com/chef/knife-azure/pull/457)
- Updated code to set chef environment [\#456](https://github.com/chef/knife-azure/pull/456)
- Added Feature availability_set for knife azure ARM [\#453](https://github.com/chef/knife-azure/pull/453)
- Remove copy Index if server count is 1 [\#447](https://github.com/chef/knife-azure/pull/447)
- Removed listen gem conflict [\#445](https://github.com/chef/knife-azure/pull/445)
- Test on the latest rubies and allow for Chef > 12 [\#444](https://github.com/chef/knife-azure/pull/444)
- Fixed '--node-ssl-verify-mode' value in client.rb [\#437](https://github.com/chef/knife-azure/pull/437)
- Fixed Auto-Generated Storage Account Name issue. [\#436](https://github.com/chef/knife-azure/pull/436)
- Updated code for azurerm bootstrap for new sdk gem. [\#430](https://github.com/chef/knife-azure/pull/430)
- Renamed chef-service-interval option name to chef-daemon-interval [\#429](https://github.com/chef/knife-azure/pull/429)
- Updated arm server delete command to use the latest azure-sdk gems. [\#428](https://github.com/chef/knife-azure/pull/428)
- Updated ARM Server Create and Show method for new sdk gem. [\#427](https://github.com/chef/knife-azure/pull/427)
- Updated code for arm commands to use the latest azure-sdk gems [\#425](https://github.com/chef/knife-azure/pull/425)
- Added support for daemon as task [\#420](https://github.com/chef/knife-azure/pull/420)
- Added warning for --purge [\#418](https://github.com/chef/knife-azure/pull/418)
- Added --daemon option for chef extension. [\#417](https://github.com/chef/knife-azure/pull/417)
- Modified Windows behavior to fetch token details in ARM model as per the changes done in the 0.10.5 version of azure-xplat-cli [\#416](https://github.com/chef/knife-azure/pull/416)


## [v1.7.0](https://github.com/chef/knife-azure/tree/v1.7.0) (2016-11-25)

[Full Changelog](https://github.com/chef/knife-azure/compare/v1.6.0...v1.7.0)

**Closed issues:**

- Knife azurerm server create (subnet in use)  [\#411](https://github.com/chef/knife-azure/issues/411)
- Multiple Azure AADs cause incorrect token to be chosen for authorization [\#405](https://github.com/chef/knife-azure/issues/405)
- Error when creating VM in ARM mode and specifying vnet [\#361](https://github.com/chef/knife-azure/issues/361)
- Knife-Azure Unable to Create a new VM using my custom vm image [\#342](https://github.com/chef/knife-azure/issues/342)
- create server does not install azure vm agent [\#316](https://github.com/chef/knife-azure/issues/316)
- knife-azure create server fails with WinRM::WinRMAuthorizationError [\#315](https://github.com/chef/knife-azure/issues/315)
- knife azure server create does not respect --secret-file argument for non-Windows hosts [\#313](https://github.com/chef/knife-azure/issues/313)
- FATAL: The x-ms-version header value '2014-05-01' is not one of the supported version headers [\#286](https://github.com/chef/knife-azure/issues/286)
- knife azure server create using ARM templates [\#285](https://github.com/chef/knife-azure/issues/285)
- knife azure server create - intermittent authorized_keys CERT thumbprint error - v.1.4.0-1.6.0.rc.0 [\#273](https://github.com/chef/knife-azure/issues/273)
- Allow using relative path for config file [\#267](https://github.com/chef/knife-azure/issues/267)
- (pending validation) Knife server delete is limited to ~5 servers in a list [\#259](https://github.com/chef/knife-azure/issues/259)
- Wrong xml format and value of Get-Deployment by using knife-azure to create a VM [\#236](https://github.com/chef/knife-azure/issues/236)
- server create issue: ProvisioningConfigurationSet must be specified [\#235](https://github.com/chef/knife-azure/issues/235)
- Compatible with Windows Azure Pack? [\#212](https://github.com/chef/knife-azure/issues/212)

**Merged pull requests:**

- Fix for handing certificate with thumbprint no found error: [\#413](https://github.com/chef/knife-azure/pull/413) ([Vasu1105](https://github.com/Vasu1105))
- Handling `credential without -0--` pattern: [\#412](https://github.com/chef/knife-azure/pull/412) ([NimishaS](https://github.com/NimishaS))
- Added chef_service_interval option and moved encrypted_data_bag_secret option from public_config to private_config for chef_extension: [\#408](https://github.com/chef/knife-azure/pull/408) ([Aliasgar16](https://github.com/Aliasgar16))
- Move contributing doc to unified location: [\#407](https://github.com/chef/knife-azure/pull/407) ([tas50](https://github.com/tas50))
- Require Ruby 2.2.2 and test on 2.2.5/2.3.1: [\#406](https://github.com/chef/knife-azure/pull/406) ([tas50](https://github.com/tas50))
- Passing the secret key correctly: [\#401](https://github.com/chef/knife-azure/pull/401) ([NimishaS](https://github.com/NimishaS))
- Added support to show extended logs in ASM bootstrap command: [\#400](https://github.com/chef/knife-azure/pull/400) ([Aliasgar16](https://github.com/Aliasgar16))
- Update ARM README to add missing options: [\#399](https://github.com/chef/knife-azure/pull/399) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Added support for extended logs to knife arm bootstrap command: [\#398](https://github.com/chef/knife-azure/pull/398) ([Aliasgar16](https://github.com/Aliasgar16))
- Added validation if the token in going to expire in 10min: [\#397](https://github.com/chef/knife-azure/pull/397) ([NimishaS](https://github.com/NimishaS))
- Fixed Issue: All specs are not running: [\#396](https://github.com/chef/knife-azure/pull/396) ([NimishaS](https://github.com/NimishaS))
- Lock activesupport gem version to fix Travis failure: [\#395](https://github.com/chef/knife-azure/pull/395) ([NimishaS](https://github.com/NimishaS))
- Add support passing of tcp port option in ARM: [\#394](https://github.com/chef/knife-azure/pull/394) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Updated code for the latest version of azure-sdk-for-ruby: [\#393](https://github.com/chef/knife-azure/pull/393)
- Allow using relative path for config files: [\#392](https://github.com/chef/knife-azure/pull/392) ([Vasu1105](https://github.com/Vasu1105))
- Removed options --auto-update-client --uninstall-chef-client --delete-chef-extension-config: [\#391](https://github.com/chef/knife-azure/pull/391) ([Vasu1105](https://github.com/Vasu1105))
- Not parsing `error.message` as json because it's sometimes string: [\#387](https://github.com/chef/knife-azure/pull/387) ([NimishaS](https://github.com/NimishaS))
- Added "RDP Port" column for ASM server list: [\#385](https://github.com/chef/knife-azure/pull/385) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Removing unused methods: [\#384](https://github.com/chef/knife-azure/pull/384) ([NimishaS](https://github.com/NimishaS))
- Added support to handle existing vnet and subnet resources in resource group while server creation: [\#383](https://github.com/chef/knife-azure/pull/383) ([Aliasgar16](https://github.com/Aliasgar16))
- Fixed autoUpgradeMinorVersion misplaced in template: [\#382](https://github.com/chef/knife-azure/pull/382) ([Vasu1105](https://github.com/Vasu1105))
- Renamed --identity-file to --ssh-public-key: [\#381](https://github.com/chef/knife-azure/pull/381) ([NimishaS](https://github.com/NimishaS))
- Updated the code to find credentials using --0- string instead of --0-2: [\#380](https://github.com/chef/knife-azure/pull/380) ([Vasu1105](https://github.com/Vasu1105))
- azurerm bootstrap fails if the version of chef extension is not given in knife.rb file: [\#379](https://github.com/chef/knife-azure/pull/379) ([Aliasgar16](https://github.com/Aliasgar16))
- Added support for running Xplat command in case of token expiry: [\#378](https://github.com/chef/knife-azure/pull/378) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Showing text error message instead of json: [\#376](https://github.com/chef/knife-azure/pull/376) ([NimishaS](https://github.com/NimishaS))
- Fixed eval failure on some ruby versions and specs failure: [\#375](https://github.com/chef/knife-azure/pull/375) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Rectified help for identity_file option: [\#374](https://github.com/chef/knife-azure/pull/374) ([Aliasgar16](https://github.com/Aliasgar16))
- Updated FFI datatypes to improve readability: [\#373](https://github.com/chef/knife-azure/pull/373) ([NimishaS](https://github.com/NimishaS))
- Added support for extended_logs to show chef-client run logs to user in ARM server_create command: [\#372](https://github.com/chef/knife-azure/pull/372) ([Aliasgar16](https://github.com/Aliasgar16))

## [v1.6.0](https://github.com/chef/knife-azure/tree/v1.6.0) (2016-06-10)

[Full Changelog](https://github.com/chef/knife-azure/compare/1.6.0.rc.0...v1.6.0)

**Closed issues:**

- Bootstrap process fails with following error after provisioning [\#350](https://github.com/chef/knife-azure/issues/350)
- Knife Azure Creating a new server [\#343](https://github.com/chef/knife-azure/issues/343)
- Creation of AD application and service principal is not automated for ARM commands [\#341](https://github.com/chef/knife-azure/issues/341)
- Error provisioning VM in existing Cloud service [\#309](https://github.com/chef/knife-azure/issues/309)
- private key file? [\#304](https://github.com/chef/knife-azure/issues/304)
- knife azure should support ssl cert bootstrap with cloud-api bootstrap [\#260](https://github.com/chef/knife-azure/issues/260)
- Provisioning issues with 1.5.2 [\#257](https://github.com/chef/knife-azure/issues/257)
- knife azure does not honor --node-ssl-verify-mode flag [\#250](https://github.com/chef/knife-azure/issues/250)
- Does 'knife azure server create' support asynchronous request？ [\#140](https://github.com/chef/knife-azure/issues/140)

**Merged pull requests:**

- Added the actual names of the sites otherwise: [\#367](https://github.com/chef/knife-azure/pull/367) ([jjasghar](https://github.com/jjasghar))
- Fixed chef extension version issue if not passed through options it should pick up latest [\#360](https://github.com/chef/knife-azure/pull/360) ([Vasu1105](https://github.com/Vasu1105))
- Add support for authentication using token for ARM [\#359](https://github.com/chef/knife-azure/pull/359) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Added support for ohai\_hints for cloud-api protocol in ARM. [\#354](https://github.com/chef/knife-azure/pull/354) ([Aliasgar16](https://github.com/Aliasgar16))
- added support for single vm provisioning through template [\#353](https://github.com/chef/knife-azure/pull/353) ([Vasu1105](https://github.com/Vasu1105))
- Showing multiple vm details [\#352](https://github.com/chef/knife-azure/pull/352) ([Vasu1105](https://github.com/Vasu1105))
- Added code to fetch chef-client run logs after extension is deployed on the server. [\#351](https://github.com/chef/knife-azure/pull/351) ([Aliasgar16](https://github.com/Aliasgar16))
- Fixed issue when bootstrap protocol is not specified during vm creation [\#349](https://github.com/chef/knife-azure/pull/349) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Added readline gem dependency in Gemfile as knife-azure commands started failing because of this gem after updating chefdk from 0.12.0 to 0.13.21 version. [\#348](https://github.com/chef/knife-azure/pull/348) ([Aliasgar16](https://github.com/Aliasgar16))
- Provided vm creation details to user in non-verbose mode [\#347](https://github.com/chef/knife-azure/pull/347) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Pinned the version on `listen` gem to 3.0.6 [\#346](https://github.com/chef/knife-azure/pull/346) ([NimishaS](https://github.com/NimishaS))
- Added support for redhat and debian OS vm provisioning [\#345](https://github.com/chef/knife-azure/pull/345) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Template deployment for multiple VMs [\#344](https://github.com/chef/knife-azure/pull/344) ([NimishaS](https://github.com/NimishaS))
- Add extension to existing VM in ARM [\#340](https://github.com/chef/knife-azure/pull/340) ([NimishaS](https://github.com/NimishaS))
- Public ip value empty for list and show operations [\#338](https://github.com/chef/knife-azure/pull/338) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Added code for validation of vm name [\#337](https://github.com/chef/knife-azure/pull/337) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Common bootstrap with cloud-api fix for ASM [\#336](https://github.com/chef/knife-azure/pull/336) ([NimishaS](https://github.com/NimishaS))
- Revert "Used common bootstrap for ASM" [\#335](https://github.com/chef/knife-azure/pull/335) ([NimishaS](https://github.com/NimishaS))
- Updated README for --azure-vnet-name and --azure-vnet-subnet-name options [\#334](https://github.com/chef/knife-azure/pull/334) ([Vasu1105](https://github.com/Vasu1105))
- Chef extension support for existing Azure ASM deployment. [\#333](https://github.com/chef/knife-azure/pull/333) ([Aliasgar16](https://github.com/Aliasgar16))
- Locked down versions of azure\_sdk\_for\_ruby gems. [\#332](https://github.com/chef/knife-azure/pull/332) ([Aliasgar16](https://github.com/Aliasgar16))
- Used common bootstrap for ASM [\#331](https://github.com/chef/knife-azure/pull/331) ([dheerajd-msys](https://github.com/dheerajd-msys))
- ARM add --secret and --secret-file options to server create [\#330](https://github.com/chef/knife-azure/pull/330) ([Vasu1105](https://github.com/Vasu1105))
- Modified ARM server\_create code along with corresponding RSpecs to override image sku. [\#329](https://github.com/chef/knife-azure/pull/329) ([Aliasgar16](https://github.com/Aliasgar16))
- Add vnet name and subnet name options to use existing vnet for vm creation [\#328](https://github.com/chef/knife-azure/pull/328) ([Vasu1105](https://github.com/Vasu1105))
- Fixed secret and secret file not getting copied issue for non-windows host [\#327](https://github.com/chef/knife-azure/pull/327) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Exception handling for ARM commands [\#326](https://github.com/chef/knife-azure/pull/326) ([NimishaS](https://github.com/NimishaS))
- Refactoring azurerm server create code [\#325](https://github.com/chef/knife-azure/pull/325) ([Vasu1105](https://github.com/Vasu1105))
- Added code to display resource\_group\_name and also added option to accept resource\_group\_name from user. [\#324](https://github.com/chef/knife-azure/pull/324) ([Aliasgar16](https://github.com/Aliasgar16))
- Added --azure-image-os-type option with specs [\#323](https://github.com/chef/knife-azure/pull/323) ([NimishaS](https://github.com/NimishaS))
- Modified ARM server\_create command as per the changes introduced in new version 0.2.1 of azure-sdk-for-ruby gems. [\#322](https://github.com/chef/knife-azure/pull/322) ([Aliasgar16](https://github.com/Aliasgar16))
- \[knife azurerm\] options issue [\#321](https://github.com/chef/knife-azure/pull/321) ([NimishaS](https://github.com/NimishaS))
- Modified Error Handling to show proper server show error output to the user [\#320](https://github.com/chef/knife-azure/pull/320) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Fixed error handling for server create [\#319](https://github.com/chef/knife-azure/pull/319) ([Vasu1105](https://github.com/Vasu1105))
- Added public ipaddress and fqdn to azurerm server show command output [\#318](https://github.com/chef/knife-azure/pull/318) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Adding --delete-resource-group option [\#314](https://github.com/chef/knife-azure/pull/314) ([Vasu1105](https://github.com/Vasu1105))
- Added code to support bootstrap protocol cloud-api and removed unwanted ARM related code from ASM server\_create command. [\#312](https://github.com/chef/knife-azure/pull/312) ([Aliasgar16](https://github.com/Aliasgar16))
- Fixed typo [\#311](https://github.com/chef/knife-azure/pull/311) ([Vasu1105](https://github.com/Vasu1105))
- Adding winrm port for azurerm server create [\#310](https://github.com/chef/knife-azure/pull/310) ([NimishaS](https://github.com/NimishaS))
- Updated specs for azurerm server delete command [\#308](https://github.com/chef/knife-azure/pull/308) ([NimishaS](https://github.com/NimishaS))
- Added specs with mock server object for azurerm server list [\#306](https://github.com/chef/knife-azure/pull/306) ([NimishaS](https://github.com/NimishaS))
- Updated Readme for ARM supported commands [\#305](https://github.com/chef/knife-azure/pull/305) ([NimishaS](https://github.com/NimishaS))
- Modified method names according to ruby convention [\#303](https://github.com/chef/knife-azure/pull/303) ([NimishaS](https://github.com/NimishaS))
- ARM server delete [\#302](https://github.com/chef/knife-azure/pull/302) ([Vasu1105](https://github.com/Vasu1105))
- ARM server show command [\#301](https://github.com/chef/knife-azure/pull/301) ([meeranavale](https://github.com/meeranavale))
- ARM basic server create command. [\#300](https://github.com/chef/knife-azure/pull/300) ([Aliasgar16](https://github.com/Aliasgar16))
- Implemented 'knife azurerm server list' command and it's specs [\#299](https://github.com/chef/knife-azure/pull/299) ([NimishaS](https://github.com/NimishaS))
- Fixed azureProfile.json validation issues [\#292](https://github.com/chef/knife-azure/pull/292) ([Vasu1105](https://github.com/Vasu1105))
- Refactored code for validation method for asm and arm [\#291](https://github.com/chef/knife-azure/pull/291) ([Vasu1105](https://github.com/Vasu1105))
- Spec for server list command [\#290](https://github.com/chef/knife-azure/pull/290) ([NimishaS](https://github.com/NimishaS))
- Re-factoring code for common methods [\#289](https://github.com/chef/knife-azure/pull/289) ([Vasu1105](https://github.com/Vasu1105))
- Rectified azure module name conflict issue and other validate! method related issue which got introduced with ARM structure. [\#288](https://github.com/chef/knife-azure/pull/288) ([Aliasgar16](https://github.com/Aliasgar16))
- Basic code structure for ARM implementation [\#287](https://github.com/chef/knife-azure/pull/287) ([NimishaS](https://github.com/NimishaS))
- Refactored sever create [\#284](https://github.com/chef/knife-azure/pull/284) ([Vasu1105](https://github.com/Vasu1105))
- Refactored ag list and create code for ASM. [\#283](https://github.com/chef/knife-azure/pull/283) ([Aliasgar16](https://github.com/Aliasgar16))
- Refactored code for vnet\_list and vnet\_create. [\#282](https://github.com/chef/knife-azure/pull/282) ([Aliasgar16](https://github.com/Aliasgar16))
- Refactored for list and create internal load balancer [\#281](https://github.com/chef/knife-azure/pull/281) ([Vasu1105](https://github.com/Vasu1105))
- Refactored ASM code for server show command [\#279](https://github.com/chef/knife-azure/pull/279) ([NimishaS](https://github.com/NimishaS))
- Refactored code for ASM delete server [\#278](https://github.com/chef/knife-azure/pull/278) ([Vasu1105](https://github.com/Vasu1105))
- Refactoring existing ASM code for implementation of ARM [\#276](https://github.com/chef/knife-azure/pull/276) ([Vasu1105](https://github.com/Vasu1105))
- Cherry-picked changes for badges and Travis [\#275](https://github.com/chef/knife-azure/pull/275) ([NimishaS](https://github.com/NimishaS))
- Added uninstall\_chef\_client flag for bootstrap protocol cloud-api. [\#272](https://github.com/chef/knife-azure/pull/272) ([Aliasgar16](https://github.com/Aliasgar16))
- Updated Readme with the bootstrap options [\#270](https://github.com/chef/knife-azure/pull/270) ([NimishaS](https://github.com/NimishaS))
- Changes for handling scheme in the azure\_api\_host\_name [\#268](https://github.com/chef/knife-azure/pull/268) ([Vasu1105](https://github.com/Vasu1105))
- Added code for Windows platform to read azure creds from azureProfile if publish\_settings file not available. [\#265](https://github.com/chef/knife-azure/pull/265) ([Aliasgar16](https://github.com/Aliasgar16))
- Added RSpecs for ssl cert support for bootstrap protocol cloud-api. [\#263](https://github.com/chef/knife-azure/pull/263) ([Aliasgar16](https://github.com/Aliasgar16))

## [1.6.0.rc.0](https://github.com/chef/knife-azure/tree/1.6.0.rc.0) (2015-11-23)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.5.2...1.6.0.rc.0)

**Closed issues:**

- Unable to join servers to Active Directory [\#254](https://github.com/chef/knife-azure/issues/254)
- params\[:port\] doesn't default correctly to 22 when bootstrapping over ssh, causing an xml error [\#249](https://github.com/chef/knife-azure/issues/249)
- UX on knife azure server delete prompt is misleading [\#242](https://github.com/chef/knife-azure/issues/242)

**Merged pull requests:**

- Release 1.6.0.rc.0 version and doc updates [\#264](https://github.com/chef/knife-azure/pull/264) ([adamedx](https://github.com/adamedx))
- SSH port issue [\#262](https://github.com/chef/knife-azure/pull/262) ([Vasu1105](https://github.com/Vasu1105))
- Added SSL certificate bootstrap support for cloud-api. [\#261](https://github.com/chef/knife-azure/pull/261) ([Aliasgar16](https://github.com/Aliasgar16))
- Parsing domain username [\#256](https://github.com/chef/knife-azure/pull/256) ([NimishaS](https://github.com/NimishaS))
- Added --azure-extension-client-config option to pass client.rb file [\#255](https://github.com/chef/knife-azure/pull/255) ([NimishaS](https://github.com/NimishaS))
- Passing node\_ssl\_verify\_mode [\#253](https://github.com/chef/knife-azure/pull/253) ([NimishaS](https://github.com/NimishaS))
- updating readme to chefdk [\#247](https://github.com/chef/knife-azure/pull/247) ([vinyar](https://github.com/vinyar))
- Added bootstrap\_version option in Chef Extension public\_config parameters and added corresponding Rspecs. [\#246](https://github.com/chef/knife-azure/pull/246) ([Aliasgar16](https://github.com/Aliasgar16))
- Updated README for cloud-api centos support [\#245](https://github.com/chef/knife-azure/pull/245) ([Vasu1105](https://github.com/Vasu1105))
- Modified VNet code to add subnet into the VNet and did corresponding changes in RSpecs. [\#244](https://github.com/chef/knife-azure/pull/244) ([Aliasgar16](https://github.com/Aliasgar16))

## [1.5.2](https://github.com/chef/knife-azure/tree/1.5.2) (2015-10-02)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.5.1.rc.3...1.5.2)

**Merged pull requests:**

- Release 1.5.2 version and docs update [\#243](https://github.com/chef/knife-azure/pull/243) ([adamedx](https://github.com/adamedx))
- Fixed ssh tcp endpoint issue for cloud-api [\#238](https://github.com/chef/knife-azure/pull/238) ([Vasu1105](https://github.com/Vasu1105))

## [1.5.1.rc.3](https://github.com/chef/knife-azure/tree/1.5.1.rc.3) (2015-09-19)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.5.1.rc.2...1.5.1.rc.3)

**Merged pull requests:**

- Release 1.5.1.rc.3, knife-windows 1.0.0.rc.2 dep update [\#241](https://github.com/chef/knife-azure/pull/241) ([adamedx](https://github.com/adamedx))

## [1.5.1.rc.2](https://github.com/chef/knife-azure/tree/1.5.1.rc.2) (2015-09-17)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.5.1.rc.1...1.5.1.rc.2)

**Closed issues:**

- Add --\[no-\]node-verify-api-cert [\#219](https://github.com/chef/knife-azure/issues/219)
- server create -\> --environment and --json-attributes not working? [\#207](https://github.com/chef/knife-azure/issues/207)
- Unable to provision a VM into a load balanced set [\#205](https://github.com/chef/knife-azure/issues/205)
- Azure China support [\#199](https://github.com/chef/knife-azure/issues/199)
- Knife-Azure's Ruby Gem install means Windows 8 'chef server' is allowed?  [\#177](https://github.com/chef/knife-azure/issues/177)
- what version of chef is supported? [\#165](https://github.com/chef/knife-azure/issues/165)
- Does not play nicely with chefdk [\#148](https://github.com/chef/knife-azure/issues/148)
- dpkg status database is locked by another process, chef client install fails [\#147](https://github.com/chef/knife-azure/issues/147)
- 401 when provisioning windows VMs [\#49](https://github.com/chef/knife-azure/issues/49)

**Merged pull requests:**

- Release 1.5.1.rc.2 updates [\#240](https://github.com/chef/knife-azure/pull/240) ([adamedx](https://github.com/adamedx))
- Added new knife-windows flags to knife-azure [\#237](https://github.com/chef/knife-azure/pull/237) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Added meaningful names  for TCP endpoint [\#234](https://github.com/chef/knife-azure/pull/234) ([Vasu1105](https://github.com/Vasu1105))
- Implemented changes to set winrm\_ssl\_verify\_mode to none for server create [\#233](https://github.com/chef/knife-azure/pull/233) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Issue 205: External/Public Load Balancer support \#210 [\#231](https://github.com/chef/knife-azure/pull/231) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Added support for validator-less bootstrap [\#230](https://github.com/chef/knife-azure/pull/230) ([Vasu1105](https://github.com/Vasu1105))
- VM not getting created for linux unless --bootstrap-protocol=ssh [\#229](https://github.com/chef/knife-azure/pull/229) ([NimishaS](https://github.com/NimishaS))
- Changes to add bootstrap options introduced in chef 12 [\#228](https://github.com/chef/knife-azure/pull/228) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Implemented  node verify cert for cloud-api [\#227](https://github.com/chef/knife-azure/pull/227) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Add Azure China support  [\#226](https://github.com/chef/knife-azure/pull/226) ([siddheshwar-more](https://github.com/siddheshwar-more))
- OC-11120 - Domain join support for knife azure [\#225](https://github.com/chef/knife-azure/pull/225) ([siddheshwar-more](https://github.com/siddheshwar-more))

## [1.5.1.rc.1](https://github.com/chef/knife-azure/tree/1.5.1.rc.1) (2015-06-02)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.5.1.rc.0...1.5.1.rc.1)

**Closed issues:**

- server create fails chef-client bootstrap using stock 2008r2 image and cloud-api protocol [\#206](https://github.com/chef/knife-azure/issues/206)

**Merged pull requests:**

- updated version.rb [\#224](https://github.com/chef/knife-azure/pull/224) ([NimishaS](https://github.com/NimishaS))
- Added em-winrm dependency back [\#222](https://github.com/chef/knife-azure/pull/222) ([NimishaS](https://github.com/NimishaS))

## [1.5.1.rc.0](https://github.com/chef/knife-azure/tree/1.5.1.rc.0) (2015-05-29)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.5.1...1.5.1.rc.0)

**Closed issues:**

- Provisioning Azure VM with SSH identity file - why failing on password? [\#145](https://github.com/chef/knife-azure/issues/145)

**Merged pull requests:**

- Version, RELNOTE updates for 1.5.0.rc.0 release [\#221](https://github.com/chef/knife-azure/pull/221) ([adamedx](https://github.com/adamedx))

## [1.5.1](https://github.com/chef/knife-azure/tree/1.5.1) (2015-05-25)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.5.0...1.5.1)

**Merged pull requests:**

- Updated changelog and release\_notes for 1.5.1 release [\#220](https://github.com/chef/knife-azure/pull/220) ([NimishaS](https://github.com/NimishaS))
- Fixed azure\_availability\_set related issue [\#218](https://github.com/chef/knife-azure/pull/218) ([siddheshwar-more](https://github.com/siddheshwar-more))

## [1.5.0](https://github.com/chef/knife-azure/tree/1.5.0) (2015-05-20)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.4.0...1.5.0)

**Closed issues:**

- knife-azure should allow script extension to be used when doing winrm bootstrap to set winrm timeouts [\#203](https://github.com/chef/knife-azure/issues/203)
- Duplicate short-name option in server create command [\#201](https://github.com/chef/knife-azure/issues/201)
- Server Create failing for some custom sysprepped images [\#189](https://github.com/chef/knife-azure/issues/189)
- Error creating a VNET [\#178](https://github.com/chef/knife-azure/issues/178)
- knife azure server create failing [\#166](https://github.com/chef/knife-azure/issues/166)
- can't execute run list after create azure virtual machines [\#161](https://github.com/chef/knife-azure/issues/161)
- Typo in RAEDME.md [\#141](https://github.com/chef/knife-azure/issues/141)

**Merged pull requests:**

- Updates for release 1.5.0 [\#217](https://github.com/chef/knife-azure/pull/217) ([NimishaS](https://github.com/NimishaS))
- Added --delete-chef-config option in knife azure server create [\#215](https://github.com/chef/knife-azure/pull/215) ([Vasu1105](https://github.com/Vasu1105))
- typo in fetch\_thumbprint method [\#213](https://github.com/chef/knife-azure/pull/213) ([smurawski](https://github.com/smurawski))
- Allow user to specify chef extension version by using knife\_rb  [\#211](https://github.com/chef/knife-azure/pull/211) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Issue 205: External/Public Load Balancer support [\#210](https://github.com/chef/knife-azure/pull/210) ([aiman-alsari](https://github.com/aiman-alsari))
- Properly configure WinRM for bootstrapping; Fixes \#203 [\#204](https://github.com/chef/knife-azure/pull/204) ([schisamo](https://github.com/schisamo))
- knife-windows 1.0.0+ compat fixes [\#202](https://github.com/chef/knife-azure/pull/202) ([schisamo](https://github.com/schisamo))
- Adding winrm\_ssl\_verify\_mode to bootstrap config [\#198](https://github.com/chef/knife-azure/pull/198) ([kaustubh-d](https://github.com/kaustubh-d))
- Add custom json attributes to chef extension [\#197](https://github.com/chef/knife-azure/pull/197) ([NimishaS](https://github.com/NimishaS))
- Update Rubies; remove Chef-unsupported versions from matrix [\#196](https://github.com/chef/knife-azure/pull/196) ([juliandunn](https://github.com/juliandunn))
- Showing thumbprint with Server show command [\#195](https://github.com/chef/knife-azure/pull/195) ([NimishaS](https://github.com/NimishaS))
- Winrm port should not be configured if --bootstrap-protocol=cloud-api [\#188](https://github.com/chef/knife-azure/pull/188) ([NimishaS](https://github.com/NimishaS))

## [1.4.0](https://github.com/chef/knife-azure/tree/1.4.0) (2015-02-09)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.4.0.rc.2...1.4.0)

**Merged pull requests:**

- Updates for release 1.4.0 [\#192](https://github.com/chef/knife-azure/pull/192) ([adamedx](https://github.com/adamedx))

## [1.4.0.rc.2](https://github.com/chef/knife-azure/tree/1.4.0.rc.2) (2015-02-07)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.4.0.rc.1...1.4.0.rc.2)

**Merged pull requests:**

- Gem version update for 1.4.0.rc.2 release [\#191](https://github.com/chef/knife-azure/pull/191) ([adamedx](https://github.com/adamedx))
- Make ready timeout non-fatal, add winrm auth timeout option [\#190](https://github.com/chef/knife-azure/pull/190) ([adamedx](https://github.com/adamedx))
- Disabled certificate genaration code for ssl transport [\#184](https://github.com/chef/knife-azure/pull/184) ([NimishaS](https://github.com/NimishaS))

## [1.4.0.rc.1](https://github.com/chef/knife-azure/tree/1.4.0.rc.1) (2015-02-06)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.4.0.rc.0...1.4.0.rc.1)

**Closed issues:**

- knife azure image list and server create do not allow use of custom image templates I have created [\#158](https://github.com/chef/knife-azure/issues/158)

**Merged pull requests:**

- Additional documentation for troubleshooting cloud-api bootstrap [\#187](https://github.com/chef/knife-azure/pull/187) ([adamedx](https://github.com/adamedx))
- Release 1.4.0.rc.1 documentation, dependency, and test fixes [\#186](https://github.com/chef/knife-azure/pull/186) ([adamedx](https://github.com/adamedx))
- \[KNIFE-481\] Virtual machine state 'provisioning' not reached after 5 minutes [\#185](https://github.com/chef/knife-azure/pull/185) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Changed .der to .b64 [\#183](https://github.com/chef/knife-azure/pull/183) ([NimishaS](https://github.com/NimishaS))
- \[Nim/pick create ssl cert\] - knife-azure ssl bootstrap should create an ssl certificate [\#180](https://github.com/chef/knife-azure/pull/180) ([NimishaS](https://github.com/NimishaS))
- \[\#178\] Error creating a VNET [\#179](https://github.com/chef/knife-azure/pull/179) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Get latest version in the form of Major.\* [\#174](https://github.com/chef/knife-azure/pull/174) ([NimishaS](https://github.com/NimishaS))
- Add --winrm-authentication-protocol option [\#171](https://github.com/chef/knife-azure/pull/171) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Added a new boolean flag --auto-update-client [\#169](https://github.com/chef/knife-azure/pull/169) ([prabhu-das](https://github.com/prabhu-das))
- OC-9994 Knife Azure server create used with --azure-connect-to-existing-dns option assumes ssh/winrm tcp endpoints port 22/5985 already used by existing vm. [\#102](https://github.com/chef/knife-azure/pull/102) ([siddheshwar-more](https://github.com/siddheshwar-more))

## [1.4.0.rc.0](https://github.com/chef/knife-azure/tree/1.4.0.rc.0) (2014-12-02)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.3.0...1.4.0.rc.0)

**Merged pull requests:**

- Gem and version update for 1.4.0.rc.0 [\#173](https://github.com/chef/knife-azure/pull/173) ([adamedx](https://github.com/adamedx))
- Remove em-winrm dependency in knife-azure [\#170](https://github.com/chef/knife-azure/pull/170) ([prabhu-das](https://github.com/prabhu-das))
- show VM Images along with OS images in knife azure image list [\#167](https://github.com/chef/knife-azure/pull/167) ([NimishaS](https://github.com/NimishaS))
- Fixed documentation of TCP and UDP options. [\#164](https://github.com/chef/knife-azure/pull/164) ([juliandunn](https://github.com/juliandunn))
- Remove the az prefix from DNS name when VM name is specified and DNS nam... [\#163](https://github.com/chef/knife-azure/pull/163) ([adamedx](https://github.com/adamedx))
- Documentation: Remove one dash, update image [\#162](https://github.com/chef/knife-azure/pull/162) ([nikhilv](https://github.com/nikhilv))
- Support for adding winrm SSL certificate, for winrm ssl communication [\#160](https://github.com/chef/knife-azure/pull/160) ([muktaa](https://github.com/muktaa))
- Fix bugs related to cloud-api bootstrap protocol. [\#159](https://github.com/chef/knife-azure/pull/159) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Integration tests for azure [\#157](https://github.com/chef/knife-azure/pull/157) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Fix tests on Travis [\#156](https://github.com/chef/knife-azure/pull/156) ([juliandunn](https://github.com/juliandunn))
- Resource extension support through knife-azure plugin [\#153](https://github.com/chef/knife-azure/pull/153) ([muktaa](https://github.com/muktaa))

## [1.3.0](https://github.com/chef/knife-azure/tree/1.3.0) (2014-07-31)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.2.2...1.3.0)

**Closed issues:**

- how to create multiple azure VMs at the same time [\#129](https://github.com/chef/knife-azure/issues/129)

**Merged pull requests:**

- Update for 1.3.0 release [\#154](https://github.com/chef/knife-azure/pull/154) ([adamedx](https://github.com/adamedx))
- Fixed rspec tests [\#151](https://github.com/chef/knife-azure/pull/151) ([prabhu-das](https://github.com/prabhu-das))
- knife-azure server create is missing -j switch for json at first chef-client run. [\#150](https://github.com/chef/knife-azure/pull/150) ([kaustubh-d](https://github.com/kaustubh-d))
- fixing rspec-3 deprecation [\#149](https://github.com/chef/knife-azure/pull/149) ([prabhu-das](https://github.com/prabhu-das))
- KNIFE-472: clean up gemspec's dependencies [\#144](https://github.com/chef/knife-azure/pull/144) ([adamedx](https://github.com/adamedx))
- \[KNIFE-472\] Clean up unnecessary dependencies. [\#143](https://github.com/chef/knife-azure/pull/143) ([juliandunn](https://github.com/juliandunn))
- OC-11209: server create should not delete storage account in cleanup - unless created storage account [\#134](https://github.com/chef/knife-azure/pull/134) ([ameyavarade](https://github.com/ameyavarade))

## [1.2.2](https://github.com/chef/knife-azure/tree/1.2.2) (2014-02-07)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.2.0...1.2.2)

**Merged pull requests:**

- Release knife-azure 1.2.2 and fix gem description Opscode references [\#136](https://github.com/chef/knife-azure/pull/136) ([adamedx](https://github.com/adamedx))
- Fix ag list and ag create commands. [\#135](https://github.com/chef/knife-azure/pull/135) ([jeffmendoza](https://github.com/jeffmendoza))

## [1.2.0](https://github.com/chef/knife-azure/tree/1.2.0) (2014-02-04)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.1.4...1.2.0)

**Closed issues:**

- Adding ports/endpoints not working [\#118](https://github.com/chef/knife-azure/issues/118)

**Merged pull requests:**

- New server describe command should be renamed show [\#133](https://github.com/chef/knife-azure/pull/133) ([adamedx](https://github.com/adamedx))
- KNIFE-441: Knife azure fails intermittently [\#132](https://github.com/chef/knife-azure/pull/132) ([adamedx](https://github.com/adamedx))
- OC-11208: Azure fails intermittently [\#131](https://github.com/chef/knife-azure/pull/131) ([muktaa](https://github.com/muktaa))
- KNIFE-427: Add support to create virtual networks and affinity groups [\#127](https://github.com/chef/knife-azure/pull/127) ([jeffmendoza](https://github.com/jeffmendoza))
- OC-10240: Update knife-windows dependency to 0.5.14 [\#124](https://github.com/chef/knife-azure/pull/124) ([adamedx](https://github.com/adamedx))
- OC-8563: Add WinRM support \(API Level\) while creating VMs [\#122](https://github.com/chef/knife-azure/pull/122) ([adamedx](https://github.com/adamedx))
- OC-10567: knife azure server delete should be asynchronous by default [\#121](https://github.com/chef/knife-azure/pull/121) ([adamedx](https://github.com/adamedx))
- OC-10371: Knife-azure should show summary of created instance [\#120](https://github.com/chef/knife-azure/pull/120) ([adamedx](https://github.com/adamedx))

## [1.1.4](https://github.com/chef/knife-azure/tree/1.1.4) (2013-11-07)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.1.4.rc.0...1.1.4)

## [1.1.4.rc.0](https://github.com/chef/knife-azure/tree/1.1.4.rc.0) (2013-11-06)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.1.2...1.1.4.rc.0)

**Merged pull requests:**

- Add more context to server create exception output [\#115](https://github.com/chef/knife-azure/pull/115) ([adamedx](https://github.com/adamedx))
- Increase uniqueness of auto-generated names, add simple create summary [\#113](https://github.com/chef/knife-azure/pull/113) ([adamedx](https://github.com/adamedx))
- KNIFE-358: knife-azure tries to bootstrap too quickly [\#112](https://github.com/chef/knife-azure/pull/112) ([adamedx](https://github.com/adamedx))
- Revert "Merge pull request \#98 from BrianEWhipple/knife-358-bootstrap-wh... [\#111](https://github.com/chef/knife-azure/pull/111) ([adamedx](https://github.com/adamedx))
- Reset config after each test, regression probably caused by new Chef rel... [\#109](https://github.com/chef/knife-azure/pull/109) ([adamedx](https://github.com/adamedx))
- Loosen restrictive version constraint on nokogiri that caused gem conflic... [\#108](https://github.com/chef/knife-azure/pull/108) ([adamedx](https://github.com/adamedx))
- OC-10125: knife-azure should auto-generate azure dns name [\#107](https://github.com/chef/knife-azure/pull/107) ([adamedx](https://github.com/adamedx))
- KNIFE-380: Encrypted data bag file configuration not detected when bootstrapping Windows server [\#106](https://github.com/chef/knife-azure/pull/106) ([adamedx](https://github.com/adamedx))
- KNIFE-291: Adding support for affinity groups and virtual networking [\#101](https://github.com/chef/knife-azure/pull/101) ([adamedx](https://github.com/adamedx))
- KNIFE-361: Delete underlying VHD blob image from Azure Storage by default when deleting Virtual Machine [\#100](https://github.com/chef/knife-azure/pull/100) ([adamedx](https://github.com/adamedx))
- KNIFE-358: Check vm available prior to bootstrapping [\#98](https://github.com/chef/knife-azure/pull/98) ([BrianEWhipple](https://github.com/BrianEWhipple))
- OC-9951: knife azure server create fails if you specify 5985 for --tcp-endpoints [\#97](https://github.com/chef/knife-azure/pull/97) ([adamedx](https://github.com/adamedx))
- KNIFE-360: Add support for adding Virtual Machine to Availability Set during provisioning [\#92](https://github.com/chef/knife-azure/pull/92) ([adamedx](https://github.com/adamedx))
- OC-9952 Fix deprecation errors in knife azure [\#91](https://github.com/chef/knife-azure/pull/91) ([siddheshwar-more](https://github.com/siddheshwar-more))
- OC-9783: Knife-azure server create leaks cloud services on failure to create vm [\#90](https://github.com/chef/knife-azure/pull/90) ([adamedx](https://github.com/adamedx))
- OC-9784: knife azure image list should include image location in output [\#89](https://github.com/chef/knife-azure/pull/89) ([adamedx](https://github.com/adamedx))
- OC-9785: knife azure should assume windows-chef-client-msi for --distro parameter [\#87](https://github.com/chef/knife-azure/pull/87) ([adamedx](https://github.com/adamedx))

## [1.1.2](https://github.com/chef/knife-azure/tree/1.1.2) (2013-09-03)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.1.0...1.1.2)

**Merged pull requests:**

- Remove hard-coded date from gemspec [\#80](https://github.com/chef/knife-azure/pull/80) ([adamedx](https://github.com/adamedx))

## [1.1.0](https://github.com/chef/knife-azure/tree/1.1.0) (2013-08-30)
[Full Changelog](https://github.com/chef/knife-azure/compare/1.0.0...1.1.0)

**Closed issues:**

- Support LoadBalancedEndpoint, Subnet, AvailabilitySet and WinRm for server create [\#45](https://github.com/chef/knife-azure/issues/45)
- NoMethodError: undefined method `run\_list' for nil:NilClass [\#20](https://github.com/chef/knife-azure/issues/20)
- bundle install is stuck for ever [\#19](https://github.com/chef/knife-azure/issues/19)
- server create command is giving error for winrm enabled images [\#10](https://github.com/chef/knife-azure/issues/10)
- Knife azure plugin is ignoring or overwriting run\_list for knife azure server create [\#9](https://github.com/chef/knife-azure/issues/9)
- Knife ssh is not working after creating VM using knife azure [\#8](https://github.com/chef/knife-azure/issues/8)
- error creating server  [\#7](https://github.com/chef/knife-azure/issues/7)
- Unable to generate a pem that works.  [\#6](https://github.com/chef/knife-azure/issues/6)
- Cannot install knife-azure gem [\#1](https://github.com/chef/knife-azure/issues/1)

**Merged pull requests:**

- KNIFE-361: Add support to delete underlying VHD when deleting OS disk [\#94](https://github.com/chef/knife-azure/pull/94) ([BrianEWhipple](https://github.com/BrianEWhipple))
- Rake task fix [\#79](https://github.com/chef/knife-azure/pull/79) ([adamedx](https://github.com/adamedx))
- Documentation updates [\#78](https://github.com/chef/knife-azure/pull/78) ([adamedx](https://github.com/adamedx))
- OC-8723: Knife-azure disk names can result in collision [\#73](https://github.com/chef/knife-azure/pull/73) ([adamedx](https://github.com/adamedx))
- OC-8763: Knife azure server delete uses invalid nomenclature in display output [\#72](https://github.com/chef/knife-azure/pull/72) ([adamedx](https://github.com/adamedx))
- OC-8834: Knife Azure unit tests write test file to root of repository [\#69](https://github.com/chef/knife-azure/pull/69) ([adamedx](https://github.com/adamedx))
- refactoring test data files [\#64](https://github.com/chef/knife-azure/pull/64) ([ameyavarade](https://github.com/ameyavarade))
- OC-8421 Additional suppression of benign warnings [\#63](https://github.com/chef/knife-azure/pull/63) ([adamedx](https://github.com/adamedx))
- OC-8310: Remove breaking test changes [\#62](https://github.com/chef/knife-azure/pull/62) ([adamedx](https://github.com/adamedx))
- OC-8243 optimize azure server create/server delete code [\#61](https://github.com/chef/knife-azure/pull/61) ([kaustubh-d](https://github.com/kaustubh-d))
- Oc 8420 knife azure integration tests [\#60](https://github.com/chef/knife-azure/pull/60) ([siddheshwar-more](https://github.com/siddheshwar-more))
- OC-8242: Fixed issues related to port and added test cases [\#56](https://github.com/chef/knife-azure/pull/56) ([adamedx](https://github.com/adamedx))
- OC-5329: Azure public ip address unavailable for knife ssh [\#55](https://github.com/chef/knife-azure/pull/55) ([adamedx](https://github.com/adamedx))
- OC-8170: Support new publishsettings format [\#53](https://github.com/chef/knife-azure/pull/53) ([adamedx](https://github.com/adamedx))
- OC:8099 server delete issues -- orphaned disks after delete [\#52](https://github.com/chef/knife-azure/pull/52) ([adamedx](https://github.com/adamedx))
- OC-8236: Server create bug in azure when same vm name is used across hosted services [\#51](https://github.com/chef/knife-azure/pull/51) ([adamedx](https://github.com/adamedx))
- OC 8242 - azure fixes of some bugs / issues [\#48](https://github.com/chef/knife-azure/pull/48) ([muktaa](https://github.com/muktaa))
- OC-5329 - ohai azure plugin to populate azure cloud attributes [\#43](https://github.com/chef/knife-azure/pull/43) ([kaustubh-d](https://github.com/kaustubh-d))
- OC-8191 - Fixed issue while uploading the certificate [\#41](https://github.com/chef/knife-azure/pull/41) ([muktaa](https://github.com/muktaa))
- OC-7835: Readme and cli switch update [\#40](https://github.com/chef/knife-azure/pull/40) ([adamedx](https://github.com/adamedx))
- Oc 7836 server create [\#37](https://github.com/chef/knife-azure/pull/37) ([muktaa](https://github.com/muktaa))
- Oc 7866 - Windows node bootstrapping fails for Azure on a Windows platform [\#36](https://github.com/chef/knife-azure/pull/36) ([kaustubh-d](https://github.com/kaustubh-d))
- Oc 7837 - Add ability to delete individual roles from a deployment in Azure [\#35](https://github.com/chef/knife-azure/pull/35) ([kaustubh-d](https://github.com/kaustubh-d))
- OC-7831 - \[Added filter to toggle between required fields and all fields while image listing \] [\#33](https://github.com/chef/knife-azure/pull/33) ([prabhu-das](https://github.com/prabhu-das))
- OC-7832 - \[ Set the azure server list fields along with code optimization \] [\#32](https://github.com/chef/knife-azure/pull/32) ([prabhu-das](https://github.com/prabhu-das))
- OC-7767 knife azure server list does not show IP address for windows VMs [\#31](https://github.com/chef/knife-azure/pull/31) ([siddheshwar-more](https://github.com/siddheshwar-more))
- OC-7830 Fixed: azure\_host\_name option in Azure as azure-host-name [\#30](https://github.com/chef/knife-azure/pull/30) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Extract Azure host name, subscription Id and Certificate [\#29](https://github.com/chef/knife-azure/pull/29) ([ameyavarade](https://github.com/ameyavarade))
- OC-7777: --purge-os-disk parameter is always true and cannot be set to false  [\#28](https://github.com/chef/knife-azure/pull/28) ([adamedx](https://github.com/adamedx))
- OC-7484, OC-7425: Merge Sprint 80 fixes [\#27](https://github.com/chef/knife-azure/pull/27) ([adamedx](https://github.com/adamedx))
- OC 7777 - \[ changed the option to have preserve-os-disk on knife azure server delete \] [\#26](https://github.com/chef/knife-azure/pull/26) ([prabhu-das](https://github.com/prabhu-das))
- Oc 7465 - support ssh keys in Linux [\#25](https://github.com/chef/knife-azure/pull/25) ([muktaa](https://github.com/muktaa))
- Oc 7425 use sudo password - \( Knife-Azure bootstrap should enable --use-sudo-password \) [\#24](https://github.com/chef/knife-azure/pull/24) ([prabhu-das](https://github.com/prabhu-das))
- Oc 7484 - clean up hosted server after server delete [\#22](https://github.com/chef/knife-azure/pull/22) ([muktaa](https://github.com/muktaa))
- Oc 7437 [\#21](https://github.com/chef/knife-azure/pull/21) ([muktaa](https://github.com/muktaa))
- \[KNIFE-252\] Improve documentation for how to convert the management cert [\#18](https://github.com/chef/knife-azure/pull/18) ([juliandunn](https://github.com/juliandunn))
- Oc 3827 [\#11](https://github.com/chef/knife-azure/pull/11) ([chirag-jog](https://github.com/chirag-jog))
- Update master [\#2](https://github.com/chef/knife-azure/pull/2) ([jamescott](https://github.com/jamescott))

## [1.0.0](https://github.com/chef/knife-azure/tree/1.0.0) (2012-06-06)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*