#
# Copyright:: Copyright 2010-2019, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module QueryAzureMock
  include AzureUtility
  def create_service
    @service = Azure::ServiceManagement::ASMInterface.new(TEST_PARAMS)
  end

  def create_instance(object)
    @server_instance = object.new
    {
      azure_subscription_id: "azure_subscription_id",
      azure_mgmt_cert: @cert_file,
      azure_api_host_name: "preview.core.windows-int.net",
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    @server_instance
  end

  def create_arm_instance(object)
    @server_instance = object.new
    {
      azure_subscription_id: "azure_subscription_id",
      azure_tenant_id: "azure_tenant_id",
      azure_client_id: "azure_client_id",
      azure_client_secret: "azure_client_secret",
      azure_resource_group_name: "test-rgrp",
      azure_vm_name: "test-vm",
      azure_service_location: "West Europe",
      connection_user: "test-user",
      validation_key: "/tmp/validation_key",
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    stub_resource_groups
    @server_instance
  end

  def stub_resource_group_create_response
    resource_group = OpenStruct.new
    resource_group.name = "test-rgrp"
    resource_group.id = "myrgrp"
    resource_group.location = "West Europe"
    resource_group
  end

  def stub_resource_management_client
    resource_management_client = double("ResourceManagementClient",
      resource_groups: double, deployments: double)
    allow(resource_management_client.resource_groups).to receive(
      :create_or_update
    ).and_return(stub_resource_group_create_response)
    allow(resource_management_client.deployments).to receive_message_chain(
      create_or_update: "create_or_update",
      value!: nil,
      body: nil
    ).and_return(stub_deployments_response)
    resource_management_client
  end

  def stub_deployments_response
    deployments = OpenStruct.new
    deployments.name = "test-deployment"
    deployments.id = "xxx-xxxx-xxxx"
    deployments
  end

  def stub_compute_management_client(user_supplied_value)
    compute_management_client = double("ComputeManagementClient",
      virtual_machines: double,
      virtual_machine_extensions: double,
      virtual_machine_extension_images: double)
    allow(compute_management_client.virtual_machine_extensions).to receive_message_chain(
      create_or_update: "create_or_update"
    ).and_return(stub_vm_extension_create_response(user_supplied_value))
    allow(compute_management_client.virtual_machine_extension_images).to receive_message_chain(
      :list_versions,
      :last,
      :name
    ).and_return("1210.12.10.100")

    allow(compute_management_client.virtual_machine_extensions).to receive_message_chain(
      :get,
      :instance_view,
      :substatuses
    ).and_return(stub_substatuses(user_supplied_value))

    compute_management_client
  end

  def stub_substatuses(user_supplied_value)
    if user_supplied_value == "substatuses_found_with_no_chef_client_run_logs"
      [
       OpenStruct.new(
         code: "code1",
         level: "Info",
         display_status: "my_code1",
         message: "my_message1",
         time: "my_time1"
       ),
       OpenStruct.new(
         code: "code2",
         level: "Warning",
         display_status: "my_code2",
         message: "my_message2",
         time: "my_time2"
       ),
      ]
    elsif user_supplied_value == "substatuses_found_with_chef_client_run_logs"
      [
       OpenStruct.new(
         code: "code1",
         level: "Info",
         display_status: "my_code1",
         message: "my_message1",
         time: "my_time1"
       ),
       OpenStruct.new(
         code: "ComponentStatus/Chef Client run logs/succeeded",
         level: "Info",
         display_status: "Provisioning succeeded",
         message: "chef_client_run_logs",
         time: "chef_client_run_logs_write_time"
       ),
       OpenStruct.new(
         code: "code2",
         level: "Warning",
         display_status: "my_code2",
         message: "my_message2",
         time: "my_time2"
       ),
      ]
    elsif user_supplied_value == "substatuses_not_found"
      nil
    end
  end

  def stub_network_resource_client(platform = nil, resource_group_name = nil, vnet_name = nil, security_group_name = nil)
    network_resource_client = double("NetworkResourceClient",
      public_ipaddresses: double,
      network_security_groups: double,
      virtual_networks: double,
      subnets: double,
      network_interfaces: double,
      security_rules: double)
    allow(network_resource_client.public_ipaddresses).to receive_message_chain(
      get: "get",
      value!: nil,
      body: nil,
      properties: nil,
      ip_address: nil
    ).and_return(stub_vm_public_ip_get_response)
    allow(network_resource_client.network_security_groups).to receive(
      :get
    ).and_return("security_group")
    allow(network_resource_client.network_security_groups).to receive_message_chain(
      :get,
      :value!,
      :body,
      :properties,
      :security_rules
    ).and_return(["default_security_rule"])
    if resource_group_name.nil? && vnet_name.nil?
      allow(network_resource_client.virtual_networks).to receive(
        :get
      ).and_return(nil)
    else
      allow(network_resource_client.virtual_networks).to receive(
        :get
      ).and_return(stub_vnet_get_response(resource_group_name, vnet_name))
    end
    if platform == "Windows"
      allow(network_resource_client.network_security_groups.get.value!.body.properties.security_rules[0]).to receive_message_chain(
        :properties,
        :destination_port_range
      ).and_return("3389")
    else
      allow(network_resource_client.network_security_groups.get.value!.body.properties.security_rules[0]).to receive_message_chain(
        :properties,
        :destination_port_range
      ).and_return("22")
    end
    allow(network_resource_client.network_security_groups).to receive_message_chain(
      create_or_update: "create_or_update",
      value!: nil,
      body: nil
    ).and_return(stub_network_security_group_create_response)
    allow(network_resource_client.security_rules).to receive_message_chain(
      create_or_update: "create_or_update",
      value!: nil,
      body: nil
    ).and_return(stub_default_security_rule_add_response(platform))
    if resource_group_name.nil? && vnet_name.nil?
      allow(network_resource_client.subnets).to receive_message_chain(
        :list,
        :value
      ).and_return(nil)
    else
      allow(network_resource_client.subnets).to receive_message_chain(
        :list
      ).and_return(stub_subnets_list_response(resource_group_name, vnet_name))
    end

    network_resource_client
  end

  def locate_resource_group_and_vnet(resource_group_name, vnet_name)
    rgrp_index = nil
    vnet_index = nil
    @resource_groups.each_with_index do |resource_group, rindex|
      if resource_group.key? resource_group_name
        rgrp_index = rindex
        resource_group[resource_group_name]["vnets"].each_with_index do |vnet, vindex|
          if vnet.key? vnet_name
            vnet_index = vindex
            break
          end
        end
        break
      end
    end

    [rgrp_index, vnet_index]
  end

  def stub_subnets_list_response(resource_group_name, vnet_name)
    rgrp_index, vnet_index = locate_resource_group_and_vnet(resource_group_name, vnet_name)

    @resource_groups[rgrp_index][resource_group_name]["vnets"][vnet_index][vnet_name]["subnets"]
  end

  def stub_vnet_get_response(resource_group_name, vnet_name)
    rgrp_index, vnet_index = locate_resource_group_and_vnet(resource_group_name, vnet_name)

    @resource_groups[rgrp_index][resource_group_name]["vnets"][vnet_index][vnet_name]
  end

  def stub_deployments_create_response
    deploy = double("deploy1", resource_type: "Microsoft.Compute/virtualMachines", resource_name: "MyVM",
                               id: "/subscriptions/e00d2b3f-3b94-4dfc-ae8e-ca34c8ba1a99/resourceGroups/vjgroup/providers/Microsoft.Compute/virtualMachines/MyVM0")
    deployment = double("Deployment",
      name: "test-deployment",
      id: "id",
      properties: double)
    allow(deployment.properties).to receive_message_chain(
      :dependencies
    ).and_return([deploy])
    allow(deployment.properties).to receive(
      :provisioning_state
    ).and_return("Succeeded")
    deployment
  end

  def stub_vm_details
    vm_details = OpenStruct.new
    vm_details.id = "test-vm-id"
    vm_details.name = "test-vm"
    vm_details.locationname = "test-vm-loc"
    vm_details.ostype = "test-vm-os"
    vm_details.publicipaddress = "1.2.3.4"
    vm_details.rdpport = "3389"
    vm_details.sshport = "22"
    vm_details.provisioningstate = "Succeeded"
    vm_details
  end

  def stub_vm_extension_create_response(user_supplied_value)
    vm_extension = double("VMExtension",
      name: "test-vm-ext",
      id: "myvmextid",
      type: "Microsoft.Compute/virtualMachines/extensions",
      properties: double,
      location: "West Europe")
    allow(vm_extension.properties).to receive(
      :publisher
    ).and_return("Ext_Publisher")
    allow(vm_extension.properties).to receive(
      :type
    ).and_return("Ext_Type")
    if user_supplied_value == "yes"
      allow(vm_extension.properties).to receive(
        :type_handler_version
      ).and_return("11.10.1")
    elsif user_supplied_value == "no"
      allow(vm_extension.properties).to receive(
        :type_handler_version
      ).and_return("1210.12")
    else
      allow(vm_extension.properties).to receive(
        :type_handler_version
      ).and_return("")
    end
    allow(vm_extension.properties).to receive(
      :provisioning_state
    ).and_return("Succeeded")
    vm_extension
  end

  def stub_storage_profile_response
    storage_profile = OpenStruct.new
    storage_profile.image_reference = "image_reference"
    storage_profile.os_disk = "osdisk"
    storage_profile
  end

  def stub_vm_public_ip_get_response
    "1.2.3.4"
  end

  def stub_network_security_group_create_response
    network_security_group = OpenStruct.new
    network_security_group.name = "network_security_group_name"
    network_security_group.id = "network_security_group_id"
    network_security_group.location = "network_security_group_location"
    network_security_group.properties = OpenStruct.new
    network_security_group.properties.default_security_rules = ["nsg_default_security_rules"]
    network_security_group
  end

  def stub_default_security_rule_add_response(platform)
    security_rule = OpenStruct.new
    security_rule.name = "security_rule_name"
    security_rule.id = "security_rule_id"
    security_rule.location = "security_rule_location"
    security_rule.properties = "security_rule_properties"
    security_rule.properties = OpenStruct.new
    if platform == "Windows"
      security_rule.properties.description = "Windows port."
      security_rule.properties.destination_port_range = "3389"
    else
      security_rule.properties.description = "Linux port."
      security_rule.properties.destination_port_range = "22"
    end
    security_rule.properties.protocol = "Tcp"
    security_rule.properties.source_port_range = "*"
    security_rule.properties.source_address_prefix = "*"
    security_rule.properties.destination_address_prefix = "*"
    security_rule.properties.access = "Allow"
    security_rule.properties.priority = 1000
    security_rule.properties.direction = "Inbound"
    security_rule
  end

  def lookup_resource_in_test_xml(lookup_name, lookup_pty, tag, in_file)
    dataXML = Nokogiri::XML readFile(in_file)
    itemsXML = dataXML.css(tag)
    not_found = true
    retval = ""
    itemsXML.each do |itemXML|
      if xml_content(itemXML, lookup_pty) == lookup_name
        not_found = false
        retval = itemXML
        break
      end
    end
    retval = Nokogiri::XML readFile("error_404.xml") if not_found
    retval
  end

  def stub_query_azure(connection)
    @getname = ""
    @getverb = ""
    @getbody = ""

    @postname = ""
    @postverb = ""
    @postbody = ""

    @deletename = ""
    @deleteverb = ""
    @deletebody = ""
    @deleteparams = ""
    @deletecount = 0

    @receivedXML = Nokogiri::XML ""
    allow(connection).to receive(:query_azure) do |name, verb, body, params, wait, services|
      Chef::Log.info "calling web service:" + name
      if verb == "get" || verb.nil?
        retval = ""
        if name == "affinitygroups" && services == false
          retval = Nokogiri::XML readFile("list_affinitygroups.xml")
        elsif name == "networking/virtualnetwork"
          retval = Nokogiri::XML readFile("list_vnets.xml")
        elsif name == "networking/media"
          retval = Nokogiri::XML readFile("get_network.xml")
        elsif name == "images"
          retval = Nokogiri::XML readFile("list_images.xml")
        elsif name == "disks"
          retval = Nokogiri::XML readFile("list_disks.xml")
        elsif name == "disks/deployment001-role002-0-201241722728"
          retval = Nokogiri::XML readFile("list_disks_for_role002.xml")
        elsif name == "hostedservices"
          retval = Nokogiri::XML readFile("list_hosts.xml")
        elsif name =~ %r{hostedservices/([-\w]*)$} && params == "embed-detail=true"
          retval = Nokogiri::XML readFile("list_deployments_for_service001.xml")
        elsif name =~ %r{hostedservices/([-\w]*)$}
          service_name = %r{hostedservices/([-\w]*)}.match(name)[1]
          retval = lookup_resource_in_test_xml(service_name, "ServiceName", "HostedServices HostedService", "list_hosts.xml")
        elsif name == "hostedservices/service001/deploymentslots/Production"
          retval = Nokogiri::XML readFile("list_deployments_for_service001.xml")
        elsif name == "hostedservices/service001/deployments/deployment001/roles/role001"
          retval = Nokogiri::XML readFile("list_deployments_for_service001.xml")
        elsif name =~ %r{hostedservices/[-\w]*/deployments/[-\w]*/roles/[-\w]*}
          retval = Nokogiri::XML readFile("list_deployments_for_service005.xml")
        elsif name == "hostedservices/service002/deploymentslots/Production"
          retval = Nokogiri::XML readFile("list_deployments_for_service002.xml")
        elsif name == "hostedservices/service002/deployments/testrequest"
          retval = Nokogiri::XML readFile("list_deployments_for_service002.xml")
        elsif name == "hostedservices/service003/deploymentslots/Production"
          retval = Nokogiri::XML readFile("list_deployments_for_service003.xml")
        elsif name == "hostedservices/vmname/deploymentslots/Production"
          retval = Nokogiri::XML readFile("list_deployments_for_vmname.xml")
        elsif name == "hostedservices/service004/deploymentslots/Production"
          retval = Nokogiri::XML readFile("list_deployments_for_service004.xml")
        elsif name == "storageservices"
          retval = Nokogiri::XML readFile("list_storageaccounts.xml")
        elsif name =~ %r{storageservices/[-\w]*$}
          service_name = %r{storageservices/([-\w]*)}.match(name)[1]
          retval = lookup_resource_in_test_xml(service_name, "ServiceName", "StorageServices StorageService", "list_storageaccounts.xml")
        elsif name == "hostedservices/unknown_yet/certificates/sha1-9dbcac68f670a27cf5d9a4e6c4a8d097bff645e2"
          retval = Nokogiri::XML readFile("get_service_certificate_error.xml")
        elsif /\b([a-f0-9]{40})\b/.match(name)
          retval = Nokogiri::XML readFile("get_service_certificate.xml")
        else
          Chef::Log.warn "unknown get value:" + name
        end
        @getname = name
        @getverb = verb
        @getbody = body
      elsif verb == "post"
        if name == "affinitygroups" && services == false
          retval = Nokogiri::XML readFile("post_success.xml")
          @receivedXML = body
        elsif name == "hostedservices"
          retval = Nokogiri::XML readFile("post_success.xml")
          @receivedXML = body
        elsif name == "hostedservices/unknown_yet/deployments"
          retval = Nokogiri::XML readFile("post_success.xml")
          @receivedXML = body
        elsif name == "hostedservices/service001/deployments/deployment001/roles"
          retval = Nokogiri::XML readFile("post_success.xml")
          @receivedXML = body
        elsif name == "hostedservices/service004/deployments/deployment004/roles"
          retval = Nokogiri::XML readFile("post_success.xml")
          @receivedXML = body
        elsif name =~ %r{hostedservices/vm01.*/deployments}
          retval = Nokogiri::XML readFile("post_success.xml")
          @receivedXML = body
        elsif name =~ %r{hostedservices/vmname/deployments}
          # Case when vm name and service name are same.
          retval = Nokogiri::XML readFile("post_success.xml")
          @receivedXML = body
        else
          Chef::Log.warn "unknown post value:" + name
        end
        @postname = name
        @postverb = verb
        @postbody = body
      elsif verb == "delete"
        @deletename = name
        @deleteverb = verb
        @deletebody = body
        @deleteparams = params
        @deletecount += 1
      elsif verb == "put"
        if name == "networking/media"
          retval = Nokogiri::XML readFile("post_success.xml")
          @receivedXML = body
        end
        @postname = name
        @postverb = verb
        @postbody = body
      else
        Chef::Log.warn "unknown verb:" + verb
      end
      retval
    end
  end

  def stub_resource_groups
    @resource_groups = [{ "rgrp-1" => {
      "vnets" => [{ "vnet-1" => OpenStruct.new({
        "location" => "westus",
        "address_space" => OpenStruct.new({
          "address_prefixes" => [ "10.1.0.0/16" ],
        }),
        "subnets" => [OpenStruct.new({ "name" => "sbn1",

                                       "address_prefix" => "10.1.0.0/24",
        }),
        OpenStruct.new({ "name" => "sbn2",
                         "address_prefix" => "10.1.48.0/20",
        })],
      }) }],
    } },
    { "rgrp-2" => {
      "vnets" => [{ "vnet-2" => OpenStruct.new({
        "location" => "westus",
        "address_space" => OpenStruct.new({
          "address_prefixes" => [ "10.2.0.0/16", "192.168.172.0/24", "16.2.0.0/24" ],
        }),
        "subnets" => [OpenStruct.new({ "name" => "sbn3",
                                       "address_prefix" => "10.2.0.0/20",
        }),
        OpenStruct.new({ "name" => "sbn4",
                         "address_prefix" => "192.168.172.0/25",
        }),
        OpenStruct.new({ "name" => "sbn5",
                         "address_prefix" => "10.2.16.0/28",
        })],
      }) },
      { "vnet-3" => OpenStruct.new({
        "location" => "westus",
        "address_space" => OpenStruct.new({
          "address_prefixes" => [ "25.3.16.0/20", "141.154.163.0/26"],
        }),
        "subnets" => [OpenStruct.new({ "name" => "sbn6",
                                       "address_prefix" => "25.3.29.0/25",
        }),
        OpenStruct.new({ "name" => "sbn7",
                         "address_prefix" => "25.3.29.128/25",
          })],
      }) }],
    } },
    { "rgrp-3" => {
      "vnets" => [{ "vnet-4" => OpenStruct.new({
        "location" => "westus",
        "address_space" => OpenStruct.new({
            "address_prefixes" => [ "10.15.0.0/20", "40.23.19.0/29" ],
          }),
        "subnets" => [OpenStruct.new({ "name" => "sbn8",
                                       "address_prefix" => "40.23.19.0/29",
          })],
      }) },
      { "vnet-5" => OpenStruct.new({
        "location" => "westus",
        "address_space" => OpenStruct.new({
            "address_prefixes" => [ "69.182.8.0/21", "12.3.19.0/24" ],
          }),
        "subnets" => [OpenStruct.new({ "name" => "sbn9",
                                       "address_prefix" => "69.182.9.0/24",
          }),
          OpenStruct.new({ "name" => "sbn10",
                           "address_prefix" => "69.182.11.0/24",
          }),
          OpenStruct.new({ "name" => "sbn11",
                           "address_prefix" => "12.3.19.0/25",
          }),
          OpenStruct.new({ "name" => "sbn12",
                           "address_prefix" => "69.182.14.0/24",
          }),
          OpenStruct.new({ "name" => "sbn13",
                           "address_prefix" => "12.3.19.128/25",
          })],
      }) }],
    } },
    { "rgrp-4" => {
      "vnets" => [{ "vnet-6" => OpenStruct.new({
        "location" => "westus",
        "address_space" => OpenStruct.new({
            "address_prefixes" => [ "130.88.9.0/24", "112.90.2.0/24" ],
          }),
        "subnets" => [OpenStruct.new({ "name" => "sbn14",
                                       "address_prefix" => "112.90.2.128/25",
          }),
          OpenStruct.new({ "name" => "sbn15",
                           "address_prefix" => "130.88.9.0/24",
          }),
          OpenStruct.new({ "name" => "sbn16",
                           "address_prefix" => "112.90.2.0/25",
          })],
      }) },
      { "vnet-7" => OpenStruct.new({
        "location" => "westus",
        "address_space" => OpenStruct.new({
            "address_prefixes" => [ "10.3.0.0/16", "160.10.2.0/24" ],
          }),
        "subnets" => [OpenStruct.new({ "name" => "sbn15",
                                       "address_prefix" => "160.10.2.192/26",
          }),
          OpenStruct.new({ "name" => "GatewaySubnet",
                           "address_prefix" => "10.3.1.0/24",
          }),
          OpenStruct.new({ "name" => "sbn16",
                           "address_prefix" => "160.10.2.0/25",
          })],
      }) }],
    } }]
  end
end
