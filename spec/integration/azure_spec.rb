# -*- coding: utf-8 -*-
# Author:: Chirag Jog (<chirag@clogeny.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# require 'knife_cloud_tests'

require 'factory_girl'
require File.expand_path(File.dirname(__FILE__) + '/azure_factories')

require 'knife_cloud_tests'
require 'knife_cloud_tests/knifeutils'
require 'knife_cloud_tests/matchers'
require 'knife_cloud_tests/helper'
require "securerandom"

RSpec.configure do |config|
  FactoryGirl.find_definitions
end

# Method to prepare Azure create server commands

def prepare_create_srv_cmd_azure_cspec(server_create_factory)
  cmd = "#{cmds_azure.cmd_create_server} " +
  prepare_knife_command(server_create_factory)
  return cmd
end

# Common method to run create server test cases

def run_azure_cspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised, run_list_cmd = true, run_del_cmd = true)
  context "" do
    instance_name = "instance_name"
    cmd_out = ""
    context "#{test_context}" do
      let(:server_create_factory){ FactoryGirl.build(factory_to_be_exercised) }
      # let(:instance_name){ strip_out_command_key("#{server_create_factory.role_name_l}") }
      let(:timeout) { 1200 }
      let(:command) { prepare_create_srv_cmd_azure_cspec(server_create_factory) }
      after(:each){instance_name = strip_out_command_key("#{server_create_factory.node_name}")}
      context "#{test_case_scene}" do
        it "#{test_run_expect[:status]}" do
          match_status(test_run_expect)
        end
      end
    end

    if run_list_cmd
      context "list server after #{test_context} " do
        let(:grep_cmd) { "| grep -e #{instance_name}" }
        let(:command) { prepare_srv_list_cmd_azure_lspec(srv_list_base_fact_azure)}
        after(:each){cmd_out = "#{cmd_stdout}"}
        it "should succeed" do
          match_status({:status => "should succeed",
            :stdout => nil,
            :stderr => nil})
        end
      end
    end

    if run_del_cmd
      context "delete-purge server after #{test_context} #{test_case_scene}" do
        let(:command) { "#{cmds_azure.cmd_delete_server}" + " " +
                        "#{instance_name}" +
                        " " +
                        prepare_knife_command(srv_del_base_fact_azure) +
                        " -y" + " -N #{instance_name} -P"}
        it "should succeed" do
          match_status({:status => "should succeed",
            :stdout => nil,
            :stderr => nil})
        end
      end
    end

  end
end


# Method to prepare azure create server command

def prepare_srv_list_cmd_azure_lspec(factory)
  cmd = "#{cmds_azure.cmd_list_server} " +
  prepare_knife_command(factory)
  return cmd
end

# Common method to run create server test cases

def run_azure_lspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
  context "#{test_context}" do
    let(:server_list_factory){ FactoryGirl.build(factory_to_be_exercised) }
    let(:command) { prepare_srv_list_cmd_azure_lspec(server_list_factory) }
    after(:each) {puts "Test case completed!"}
    context "#{test_case_scene}" do
      it "#{test_run_expect[:status]}" do
        match_status(test_run_expect)
      end
    end
  end
end

def create_srv_azure_dspec(server_create_factory)
  cmd = "#{cmds_azure.cmd_create_server} " +
  prepare_knife_command(server_create_factory)
  shell_out_command(cmd, "creating instance...")
end

def create_srvs_azure_dspec(count)
  for server_count in 0..count
    name_of_the_node    = "az#{SecureRandom.hex(4)}"
    node_name_local     = "#{srv_create_params_fact_azure.node_name} "        + name_of_the_node
    role_name_local     = "#{srv_create_params_fact_azure.role_name_l} "      + name_of_the_node
    host_name_l_local   = "#{srv_create_params_fact_azure.host_name_l} "      + name_of_the_node
    fact =  FactoryGirl.build(:azureServerCreateWithDefaults,
        node_name: node_name_local,
        role_name_l: role_name_local,
        host_name_l:host_name_l_local)

    instances.push fact
    create_srv_azure_dspec(fact)
  end
  return instances
end

def find_srv_ids_azure_dspec(instances)
  instance_ids = []
  instances.each do |instance|
    instance_ids.push strip_out_command_key("#{instance.node_name}")
  end
  return instance_ids
end

# Method to prepare azure create server command

def prepare_del_srv_cmds_azure_dspec(factory, instances)
  cmd ="#{cmds_azure.cmd_delete_server}" + " " +
  "#{prepare_list_srv_ids_azure_dspec(instances)}" + " " + prepare_knife_command(factory) + " -y"
  return cmd
end

def prepare_del_srv_cmd_purge_azure_dspec(factory, instances)
  node_names = "-N"
  instances.each do |instance|
    node_names = node_names + " " + strip_out_command_key("#{instance.node_name}")
  end

  cmd ="#{cmds_azure.cmd_delete_server}" + " " +
  "#{prepare_list_srv_ids_azure_dspec(instances)}" + " " +  node_names + " -P " + prepare_knife_command(factory) + " -y"
  return cmd
end

def prepare_del_srv_cmd_non_exist_azure_dspec(factory)
  cmd ="#{cmds_azure.cmd_delete_server}" + " " +
  "1234567890" + " " + prepare_knife_command(factory) + " -y"
  return cmd
end

def prepare_list_srv_ids_azure_dspec(instances)
  instances_to_be_deleted = ""
  instance_ids = find_srv_ids_azure_dspec(instances)
  instance_ids.each do |instance|
    instances_to_be_deleted = instances_to_be_deleted + " " + "#{instance}"
  end
  return instances_to_be_deleted
end

# Common method to run create server test cases

def run_azure_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised, test_case_type="")
  case test_case_type
      when "delete"
        srv_del_test_azure_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
      when "delete_multiple"
        srv_del_test_mult_azure_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
      when "delete_non_existent"
        srv_del_test_non_exist_azure_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
      when "delete_with_os_disk"
        srv_del_test_os_disk_azure_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
      else
  end
end

def srv_del_test_azure_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
  context "#{test_context}" do
    let(:instances) { [] }
    before(:each) {create_srvs_azure_dspec(0)}
    let(:server_delete_factory){ FactoryGirl.build(factory_to_be_exercised) }
    let(:command) { prepare_del_srv_cmd_purge_azure_dspec(server_delete_factory, instances) }
    after(:each) {puts "Test case completed!"}
    context "#{test_case_scene}" do
      it "#{test_run_expect[:status]}" do
        match_status(test_run_expect)
      end
    end
  end
end

def srv_del_test_purge_azure_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
  context "#{test_context}" do
    let(:instances) { [] }
    before(:each) {create_srvs_azure_dspec(0)}
    let(:server_delete_factory){ FactoryGirl.build(factory_to_be_exercised) }
    let(:command) { prepare_del_srv_cmd_purge_azure_dspec(server_delete_factory, instances) }
    after(:each) {puts "Test case completed!"}
    context "#{test_case_scene}" do
      it "#{test_run_expect[:status]}" do
        match_status(test_run_expect)
      end
    end
  end
end

def srv_del_test_mult_azure_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
  context "#{test_context}" do
    let(:instances) { [] }
    before(:each) {create_srvs_azure_dspec(1)}
    let(:server_delete_factory){ FactoryGirl.build(factory_to_be_exercised) }
    let(:command) { prepare_del_srv_cmd_purge_azure_dspec(server_delete_factory, instances) }
    after(:each) {puts "Test case completed!"}
    context "#{test_case_scene}" do
      it "#{test_run_expect[:status]}" do
        match_status(test_run_expect)
      end
    end
  end
end

def srv_del_test_non_exist_azure_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
  context "#{test_context}" do
    let(:server_delete_factory){ FactoryGirl.build(factory_to_be_exercised) }
    let(:command) { prepare_del_srv_cmd_non_exist_azure_dspec(server_delete_factory) }
    after(:each) {puts "Test case completed!"}
    context "#{test_case_scene}" do
      it "#{test_run_expect[:status]}" do
        match_status(test_run_expect)
      end
    end
  end
end

def srv_del_test_os_disk_azure_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
  context "#{test_context}" do
    let(:instances) { [] }
    before(:each) {create_srvs_azure_dspec(0)}
    let(:server_delete_factory){ FactoryGirl.build(factory_to_be_exercised) }
    let(:command) { prepare_del_srv_cmd_purge_azure_dspec(server_delete_factory, instances) }
    after(:each) {puts "Test case completed!"}
    context "#{test_case_scene}" do
      it "#{test_run_expect[:status]}" do
        match_status(test_run_expect)
      end
    end
  end
end

describe 'knife azure' do
  include RSpec::KnifeUtils
  # before(:all) { load_factory_girl }
  before(:all) { load_knife_config }
  let(:cmds_azure){ FactoryGirl.build(:azureServerCommands) }
  let(:srv_del_base_fact_azure){FactoryGirl.build(:azureServerDeleteBase)}
  let(:srv_list_base_fact_azure){FactoryGirl.build(:azureServerListBase)}
  let(:srv_create_params_fact_azure){FactoryGirl.build(:azureServerCreateParameters)}

  expected_params = {
                     :status => "should succeed",
                     :stdout => "Chef Run complete",
                     :stderr => nil,
                     # :statuscode => 0
                   }
  # Test Case: OP_KAP_1, CreateServerWithDefaults
  run_azure_cspec("server create", "with all default parameters", expected_params, :azureServerCreateWithDefaults, true)

  # Test Case: OP_KAP_2, CreateServerWithOnlyServiceRegion
  run_azure_cspec("server create", "with only service region", expected_params, :azureServerCreateWithOnlyServiceRegion, false)

  # Test Case: OP_KAP_3, CreateServerOfDifferentRoleSize
  run_azure_cspec("server create", "of different role size", expected_params, :azureServerCreateOfDifferentRoleSize, false)

  # Test Case: OP_KAP_4, CreateServerWithTCPPortList
  run_azure_cspec("server create", "with TCP port list", expected_params, :azureServerCreateWithTCPPortList, false)

  # Test Case: OP_KAP_5, CreateServerWithUDPPortList
  run_azure_cspec("server create", "with UDP port list", expected_params, :azureServerCreateWithUDPPortList, false)

  # Test Case: OP_KAP_6, CreateServerWithRegionAndExistentHostedService
  run_azure_cspec("server create", "with region and existent hosted service", expected_params, :azureServerCreateWithRegionAndExistentHostedService, false)

  # Test Case: OP_KAP_7, CreateServerWithRegionAndNonExistentHostedService
  run_azure_cspec("server create", "with region and non existent hosted service", expected_params, :azureServerCreateWithRegionAndNonExistentHostedService, false)

  # Test Case: OP_KAP_8, CreateServerWithRegionAndExistentStorageService
  run_azure_cspec("server create", "with region and existent storage service", expected_params, :azureServerCreateWithRegionAndExistentStorageService, false)

  # Test Case: OP_KAP_9, CreateServerWithRegionAndNonExistentHostedService
  run_azure_cspec("server create", "with region and non existent hosted service", expected_params, :azureServerCreateWithRegionAndNonExistentStorageService, false)

  # Test Case: OP_KAP_10, CreateServerWithHostedAndStorageService
  run_azure_cspec("server create", "with hosted and storage service", expected_params, :azureServerCreateWithHostedAndStorageService, true)

  # Test Case: OP_KAP_11, CreateServerWithRegionWithoutSpecifyingStorageService
  run_azure_cspec("server create", "without specifying storage service", expected_params, :azureServerCreateWithRegionWithoutStorageService, false)

  # Test Case: OP_KAP_12, CreateServerWithRegionWithoutSpecifyingStorageService
  run_azure_cspec("server create", "without specifying storage service", expected_params, :azureServerCreateWithRegionWithoutStorageService2, false)

  # Test Case: OP_KAP_15, CreateServerWithSpecificOSDisk
  run_azure_cspec("server create", "with specific os disk", expected_params, :azureServerCreateWithSpecificOSDisk, false)

  # Test Case: OP_KAP_24, CreateServerWithRoleAndRecipe
  run_azure_cspec("server create", "with role and recipe", expected_params, :azureServerCreateWithRoleAndRecipe, true)

  # Test Case: OP_KAP_27, CreateWindowsServerWithWinRMBasicAuth
  run_azure_cspec("windows server create", "with wimRM Basic auth", expected_params, :azureWindowsServerCreateWithWinRMBasicAuth, true)

  # Test Case: OP_KAP_28, CreateWindowsServerWithSSHAuth
  run_azure_cspec("windows server create", "with SSH auth", expected_params, :azureWindowsServerCreateWithSSHAuth, true)


  expected_params = {
                     :status => "should succeed",
                     :stdout => nil,
                     :stderr => nil,
                     # :statuscode => 0
                   }
  # Test Case: OP_KAP_17, DeleteServerWithoutOSDisk
  #run_azure_dspec("server delete", "without OS disk", expected_params, :azureServerDeleteWithoutOSDisk, "delete")

  # Test Case: OP_KAP_18, DeleteServerWithOSDisk
  # run_azure_dspec("server delete", "with OS disk", expected_params, :azureServerDeleteWithOSDisk, "delete_with_os_disk")

  # Test Case: OP_KAP_19, DeleteMutipleServers

  run_azure_dspec("server delete", "command for multiple servers", expected_params, :azureServerDeleteMultiple, "delete_multiple")

  # Test Case: OP_KAP_23, DeleteServerDontPurge
  run_azure_dspec("server delete", "with no purge option", expected_params, :azureServerDeleteDontPurge, "delete")

  run_azure_cspec("server create", "with user-created image", expected_params,:azureServerCreateWithCustomImage, false)

  expected_params = {
    :status => "should fail",
    :stdout => nil,
    :stderr => nil
  }

  # Test Case: OP_KAP_13, CreateServerWithRootSSHUser

  run_azure_cspec("server create", "with root as ssh user", expected_params, :azureServerCreateWithRootSSHUser, false)

  # Test Case: OP_KAP_14, CreateServerWithInvalidSSHPassword
  run_azure_cspec("server create", "with invalid ssh password", expected_params, :azureServerCreateWithInvalidSSHPassword, false, false)

  # Test Case: OP_KAP_25, CreateServerWithInvalidRole
  # FIXME need to write a custom matcher to validate invalid role

  run_azure_lspec("server list", "for invalid azure cert", expected_params, :azureServerListInvalidCert)

  # Test Case: OP_KAP_16, DeleteServerThatDoesNotExist
  run_azure_dspec("server delete", "with non existent server", expected_params, :azureServerDeleteNonExistent, "delete_non_existent")

   expected_params = {
    :status => "should fail",
    :stdout => "The disk's VHD must be in the same account as the VHD of the source image",
    :stderr => nil
  }

  run_azure_cspec("server create", "with user-created image and in different region", expected_params, :azureServerCreateWithCustomImageDiffStorageAcct, false, false)

  expected_params = {
    :status => "should fail",
    :stdout => "Error expanding the run_list",
    :stderr => nil
  }
  run_azure_cspec("server create", "with invalid role", expected_params, :azureServerCreateWithInvalidRole, false)

  # Test Case: OP_KAP_26, CreateServerWithInvalidRecipe
  expected_params = {
    :status => "should fail",
    :stdout => "Error Resolving Cookbooks for Run List",
    :stderr => nil
  }
  run_azure_cspec("server create", "with invalid recipe", expected_params, :azureServerCreateWithInvalidRecipe, false)

# Test Case: OP_KAP_29, CreateLinuxServerWithWinRM
  run_azure_cspec("linux server create", "with WinRM", expected_params, :azureLinuxServerCreateWithWinRM, false, false)


  run_azure_lspec("server list", "for invalid azure host", expected_params, :azureServerListInvalidHost)

  run_azure_lspec("server list", "for invalid azure subscription ID", expected_params, :azureServerListInvalidSubscription)

  expected_params = {
    :status => "should fail",
    :stdout => nil,
    :stderr => nil
  }
  run_azure_cspec("server create", "for invalid service region", expected_params, :azureServerCreateWithInvalidServiceRegion, run_list_cmd = false, run_del_cmd = false)

  expected_params = {
    :status => "should return empty list",
    :stdout => nil,
    :stderr => nil
  }
  # Test Case: OP_KAP_20, ListServerEmpty
  run_azure_lspec("server list", "for no instances", expected_params, :azureServerListEmpty)


end
