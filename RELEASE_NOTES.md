<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-azure 1.3.0 release notes:
This release of knife-azure updates gem dependencies and adds missing
bootstrap json functionality.

Our thanks to contributor  **Tugdual Saunier** for addressing a confusing
documentation issue in the README.

Issues with `knife-azure` should be reported in the ticketing system at
https://tickets.opscode.com/browse/KNIFE, though we will soon transition to
use of GitHub issues for tracking. To learn more about how you can
contribute features and bug fixes to `knife-azure`, visit https://wiki.opscode.com/display/chef/How+to+Contribute.

## Features added in knife-azure 1.3.0

### `-j` option for bootstrap json
Allows you to specify a string of JSON for first boot attributes during bootstrap.

-j JSON_ATTRIBS, --json-attributes JSON_ATTRIBS
A JSON string that is added to the first run of a chef-client.

## knife-azure on RubyGems and Github
https://rubygems.org/gems/knife-azure
https://github.com/opscode/knife-azure

## Issues fixed in knife-azure 1.3.0
* Update specs to rspec 3
* [KNIFE-472](https://tickets.opscode.com/browse/KNIFE-472) - clean up knife-azure gemspec dependencies
* Fixed wrong command in README
* server create should not delete storage account in cleanup - unless created storage account

## New features added in knife-azure 1.3.0
* knife-azure server create is missing -j switch for json at first chef-client run.

