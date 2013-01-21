# Contributing to Knife Azure

We are glad you want to contribute to knife-azure project! The first step is the desire to improve the project.

The [Chef CONTRIBUTING.md](https://github.com/opscode/chef/blob/master/CONTRIBUTING.md) contains important information regarding all the open source projects under Chef.
You can find the answers to additional frequently asked questions [on the wiki](http://wiki.opscode.com/display/chef/How+to+Contribute).


## Integration and Unit Tests

There are rspec unit tests in the 'spec/unit' directory. If you don't have rspec already installed, you can use the 'bundler'
gem to help you get the necessary prerequisites by running `sudo gem install bundler` and then `bundle install` from
the chef respository. You can run the chef client spec tests by running `rspec spec/*` or `rake spec` from the chef
directory of the chef repository.

These tests should pass successfully on Ruby 1.8 and 1.9 on all of the platforms that Chef runs on. It is good to run the tests
once on your system before you get started to ensure they all pass so you have a valid baseline. After you write your patch,
run the tests again to see if they all pass.

If any don't pass, investigate them before submitting your patch.

These tests don't modify your system, and sometimes tests fail because a command that would be run has changed because of your
patch. This should be a simple fix. Other times the failure can show you that an important feature no longer works because of
your change.

Additionally there are integration tests, that require working Azure credentials as they perform APIs that create services in Azure. They can be simply run using rake:
    `bundle exec rake integration`

Setting up the Azure Credentials:
    `mkdir -p spec/integration/properties`

    `cp <AZURE_SETTING_DIRECTORY>/publishSettings.xml spec/integration/properties #Copy over your azure settings xml`

### Developing Integration Tests:
The integration tests are built using the [knife_cloud_tests](http://github.com/chirag_jog/knife_cloud_tests) framework.
Additional information about how to setup the knife_cloud_tests can be found here [README](https://github.com/chirag-jog/knife_cloud_tests/blob/master/README.md)
Refer the existing testcases to develop new ones.

#### NOTE
Azure images by default expect a password to be supplied for each sudo command which knife bootstrap does not support. Refer [CHEF-2821](http://tickets.opscode.com/browse/CHEF-2821). To work around this issue temporarily, a custom-image with sudo password disabled should be provided.

Any new feature should have unit tests included with the patch with good code coverage to help protect it from future changes.
Similarly, patches that fix a bug or regression should have a _regression test_. Simply put, this is a test that would fail
without your patch but passes with it. The goal is to ensure this bug doesn't regress in the future. Consider a regular
expression that doesn't match a certain pattern that it should, so you provide a patch and a test to ensure that the part
of the code that uses this regular expression works as expected. Later another contributor may modify this regular expression
in a way that breaks your use cases. The test you wrote will fail, signalling to them to research your ticket and use case
and accounting for it.

## Code Review

Opscode regularly reviews code contributions and provides suggestions for improvement in the code itself or the implementation.

We find contributions by searching the ticket tracker for _resolved_ tickets with a status of _fixed_. If we have feedback we will
reopen the ticket and you should resolve it again when you've made the changes or have a response to our feedback. When we believe
the patch is ready to be merged, we will tag the _Code Reviewed_ field with _Reviewed_.

Depending on the project, these tickets are then merged within a week or two, depending on the current release cycle.

notes are available on the [Opscode blog](http://www.opscode.com/blog).
