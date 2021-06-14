# Knife Azure

[![Gem Version](https://badge.fury.io/rb/knife-azure.svg)](https://rubygems.org/gems/knife-azure)
[![Build status](https://badge.buildkite.com/7796bf2bd728a4a0ca714273e12ab2df436d6afccb862ea5bb.svg)](https://buildkite.com/chef-oss/chef-knife-azure-master-verify)

**Umbrella Project**: [Knife](https://github.com/chef/chef-oss-practices/blob/master/projects/knife.md)

**Project State**: [Active](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md#active)

**Issues [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md)**: 14 days

**Pull Request [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md)**: 14 days

## Description

A [knife](http://docs.chef.io/knife.html) plugin to create, delete, and enumerate [Microsoft Azure](https://azure.microsoft.com) resources to be managed by Chef Infra.

NOTE: You may also want to consider using the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli), this application is written by the Azure team and has many other integrations with Azure. If click [here](https://github.com/chef-partners/azure-chef-extension/blob/master/examples/azure-xplat-cli-examples.md) you'll see deeper examples of using the Chef extension and Azure.

## Installation

knife-azure comes bundled with Chef Workstation, which can be installed via:

```
https://downloads.chef.io/chef-workstation/
```

## Modes

`knife-azure 4.0` onwards removes the legacy `knife azure` commands that utilized the Azure Service Management API. This API was deprecated in March 2018.

## Configuration

1. [ARM Configuration](docs/configuration.md#arm-mode)

## Detailed Usage

1. [ARM Mode](docs/ARM.md)

## Bootstrap existing VM to install the Chef Infra Client using chef-extension

We have added a utility to bootstrap existing VM. This will install the Chef Infra Client using chef extension on your VM.

1. [Bootstrap Doc for ARM Mode](docs/bootstrap.md#arm-mode)

## Contributing

For information on contributing to this project see <https://github.com/chef/chef/blob/master/CONTRIBUTING.md>

## License

Copyright:: Copyright 2010-2020, Chef Software, Inc.

License:: Apache License, Version 2.0

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
