#
# Author:: Nimisha Sharad (<nimisha.sharad@clogeny.com>)
# Copyright:: Copyright (c) 2016 Opscode, Inc.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::BootstrapAzurerm do
  include AzureSpecHelper
  include QueryAzureMock
  include AzureUtility

  before do
    @bootstrap_azurerm_instance = create_arm_instance(Chef::Knife::BootstrapAzurerm)
    @service = @bootstrap_azurerm_instance.service
    @bootstrap_azurerm_instance.name_args = ['test-vm-01']
    Chef::Config[:knife][:azure_resource_group_name] = 'test-rgp-01'
    Chef::Config[:knife][:azure_service_location] = 'West US'
  end

  describe "parameters validation" do
    it "raises error when server name is not given in the args" do
      allow(@bootstrap_azurerm_instance.name_args).to receive(:length).and_return(0)
      expect(@bootstrap_azurerm_instance.ui).to receive(:log).with('Validating...')
      expect(@bootstrap_azurerm_instance).to receive(:validate_arm_keys!)
      expect(@service).to_not receive(:create_vm_extension)
      expect(@bootstrap_azurerm_instance.ui).to receive(
        :error).with('Please specify the SERVER name which needs to be bootstrapped via the Chef Extension.')
      expect(Chef::Log).to receive(:debug)
      expect{ @bootstrap_azurerm_instance.run }.to raise_error(SystemExit)
    end

    it "raises error when azure_resource_group_name is not specified" do
      Chef::Config[:knife].delete(:azure_resource_group_name)
      expect(@bootstrap_azurerm_instance.ui).to receive(:log).with('Validating...')
      expect(@bootstrap_azurerm_instance.ui).to receive(:error)
      expect {@bootstrap_azurerm_instance.run}.to raise_error(SystemExit)
    end

    it "raises error when azure_service_location is not specified" do
      Chef::Config[:knife].delete(:azure_service_location)
      expect(@bootstrap_azurerm_instance.ui).to receive(:log).with('Validating...')
      expect(@bootstrap_azurerm_instance.ui).to receive(:error)
      expect {@bootstrap_azurerm_instance.run}.to raise_error(SystemExit)
    end

    it "raises error when more than one server name is specified" do
      @bootstrap_azurerm_instance.name_args = ['test-vm-01', 'test-vm-02', 'test-vm-03']
      expect(@bootstrap_azurerm_instance.name_args.length).to be == 3
      expect(@service).to_not receive(:create_vm_extension)
      expect(@bootstrap_azurerm_instance.ui).to receive(
        :error).with('Please specify only one SERVER name which needs to be bootstrapped via the Chef Extension.')
      expect(Chef::Log).to receive(:debug)
      expect {@bootstrap_azurerm_instance.run}.to raise_error(SystemExit)
    end

    it "raises error when server name specified does not exist under the given hosted service" do
      expect(@bootstrap_azurerm_instance.name_args.length).to be == 1
      expect(@service).to_not receive(:create_vm_extension)
      expect(@service).to receive(:find_server).and_return(nil)
      expect(@bootstrap_azurerm_instance.ui).to receive(
        :error).with("The given server 'test-vm-01' does not exist under resource group 'test-rgp-01'")
      expect(Chef::Log).to receive(:debug)
      expect {@bootstrap_azurerm_instance.run}.to raise_error(SystemExit)
    end
  end
end