# -*- coding: utf-8 -*-
# Author:: Chirag Jog (<chirag@clogeny.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.

require File.expand_path(File.dirname(__FILE__) + '/azure')
require "securerandom"

FactoryGirl.define do

  factory :azureServerCommands, class: AzureKnifeServerCommands do
    cmd_list_image                    "knife azure image list"                      # Knife command for image list
    cmd_create_server                 "knife azure server create"                   # Knife command for creating a server
    cmd_delete_server                 "knife azure server delete"                   # Knife command for deleting a server
    cmd_describe_server               "knife azure server describe"                 # Knife command for describing a server
    cmd_list_server                   "knife azure server list"                     # Knife command for listing servers
  end

  factory :azureServerCreateParameters, class: AzureKnifeServerCreateParameters do
    azure_server_url                  "-H"                                          # Your Azure Server URL
    azure_server_url_l                " --azure_host_name"                          # Your Azure Server URL
    azure_mgmt_cert                   "--azure-mgmt-cert"                           # Your Azure PEM file name
    azure_subcription_id              "--azure-subscription-id"                     # Your Azure subscription ID
    bootstrap_protocol                "--bootstrap-protocol"                        # Protocol to bootstrap windows servers. options: winrm/ssh
    bootstrap_version                 "--bootstrap-version"                         # The version of Chef to install
    trust_file                        "-f"                                          # The Certificate Authority (CA) trust file used for SSL transport
    trust_file_l                      "--ca-trust-file"                             # The Certificate Authority (CA) trust file used for SSL transport
    node_name                         "-N"                                          # The Chef node name for your new node
    node_name_l                       "--node-name"                                 # The Chef node name for your new node
    server_url                        "--server-url"                                # Chef Server URL
    api_client_key                    "-k"                                          # API Client Key
    api_client_key_l                  "--key"                                       # API Client Key
    colored_optput                    "--[no-]color"                                # Use colored output, defaults to enabled
    config_file                       "-c"                                          # The configuration file to use
    config_file_l                     "--config"                                    # The configuration file to use
    defaults                          "--defaults"                                  # Accept default values for all questions
    disable_editing                   "--disable-editing"                           # Do not open EDITOR, just accept the data as is
    distro                            "-d"                                          # Bootstrap a distro using a template; default is 'chef-full'
    distro_l                          "--distro"                                    # Bootstrap a distro using a template; default is 'chef-full'
    editor                            "-e"                                          # Set the editor to use for interactive commands
    editor_l                          "--editor"                                    # Set the editor to use for interactive commands
    environment                       "-E"                                          # Set the Chef environment
    environment_l                     "--environment"                               # Set the Chef environment
    format                            "-F"                                          # Which format to use for output
    format_l                          "--format"                                    # Which format to use for output
    host_key                          "--[no-]host-key-verify"                      # Verify host key, enabled by default.
    host_name_l                       "--host-name"                                 # specifies the host name for the virtual machine
    hosted_service_desc               "-D"                                          # Description for the hosted service
    hosted_service_desc_l             "--hosted_service_description"                # Description for the hosted service
    hosted_service_name               "-s"                                          # specifies the name for the hosted service
    hosted_service_name_l             "--hosted-service-name"                       # specifies the name for the hosted service
    identity_file                     "--identity-file"                             # The SSH identity file used for authentication
    keytab_file                       "-i"                                          # The Kerberos keytab file used for authentication
    keytab_file_l                     "--keytab-file"                               # The Kerberos keytab file used for authentication
    kerberos_realm                    "--kerberos-realm"                            # The Kerberos realm used for authentication
    kerberos_service                  "-S"                                          # The Kerberos service used for authentication
    kerberos_service_l                "--kerberos-service"                          # The Kerberos service used for authentication
    user                              "--user"                                      # API Client Username
    os_disk_name                      "-o"                                          # unique name for specifying os disk (optional)
    os_disk_name_l                    "--os-disk-name"                              # unique name for specifying os disk (optional)
    pre_release                       "--prerelease"                                # Install the pre-release chef gems
    print_after                       "--print-after"                               # Show the data after a destructive operation
    role_name_l                       "--role-name"                                 # specifies the name for the virtual machine
    role_size                         "-z"                                          # size of virtual machine (ExtraSmall, Small, Medium, Large, ExtraLarge)
    role_size_l                       "--role-size"                                 # size of virtual machine (ExtraSmall, Small, Medium, Large, ExtraLarge)
    run_list                          "-r"                                          # Comma separated list of roles/recipes to apply
    run_list_l                        "--run-list"                                  # Comma separated list of roles/recipes to apply
    service_location                  "-m"                                          # specify the Geographic location for the virtual machine and services
    service_location_l                "--service-location"                          # specify the Geographic location for the virtual machine and services
    source_image                      "-I"                                          # disk image name to use to create virtual machine
    source_image_l                    "--source-image"                              # disk image name to use to create virtual machine
    ssh_password                      "--ssh-password"                              # The ssh password
    ssh_username                      "--ssh-user"                                  # The ssh username
    storage_account                   "-a"                                          # specifies the name for the hosted service
    storage_account_l                 "--storage-account"                           # specifies the name for the hosted service
    tcp_endpoints                     "--tcp-endpoints"                             # Comma separated list of TCP local and public ports to open i.e. '80:80,433:5000'
    template_file                     "--template-file"                             # Full path to location of template to use
    udp_endpoints                     "-u"                                          # Comma separated list of UDP local and public ports to open i.e. '80:80,433:5000'
    udp_endpoints_l                   "--udp-endpoints"                             # Comma separated list of UDP local and public ports to open i.e. '80:80,433:5000'
    verbose                           "-V"                                          # More verbose output. Use twice for max verbosity
    verbose_l                         "--verbose"                                   # More verbose output. Use twice for max verbosity
    verify_ssl_cert                   "--verify-ssl-cert"                           # Verify SSL Certificates for communication over HTTPS
    version_chef                      "-v"                                          # Show chef version
    version_chef_l                    "--version"                                   # Show chef version
    winrm_password                    "-P"                                          # The WinRM password
    winrm_password_l                  "--winrm-password"                            # The WinRM password
    winrm_port                        "-p"                                          # The WinRM port, by default this is 5985
    winrm_port_l                      "--winrm-port"                                # The WinRM port, by default this is 5985
    winrm_transport                   "-t"                                          # The WinRM transport type.  valid choices are [ssl, plaintext]
    winrm_transport_l                 "--winrm-transport"                           # The WinRM transport type.  valid choices are [ssl, plaintext]
    winrm_user                        "-x"                                          # The WinRM username
    winrm_user_l                      "--winrm-user"                                # The WinRM username
    say_yes_to_all_prompts            "-y"                                          # Say yes to all prompts for confirmation
    say_yes_to_all_prompts_l          "--yes"                                       # Say yes to all prompts for confirmation
    help                              "-h"                                          # Show help
    help_l                            "--help"                                      # Show help
  end

  factory :azureServerDeleteParameters, class:  AzureKnifeServerDeleteParameters do
    azure_server_url                  "-H"                                          # Your Azure host name
    azure_server_url_l                "--azure-server-url"                           # Your Azure host name
    azure_mgmt_cert                   "-p"                                          # Your Azure PEM file name
    azure_mgmt_cert_l                 "--azure-mgmt-cert"                           # Your Azure PEM file name
    azure_subcription_id              "-S"                                          # Your Azure subscription ID
    azure_subcription_id_l            "--azure-subscription-id"                     # Your Azure subscription ID
    node_name                         "-N"                                          # The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option.
    node_name_l                       "--node-name"                                 # The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option.
    server_url                        "-s"                                          # Chef Server URL
    server_url_l                      "--server-url"                                # Chef Server URL
    api_client_key                    "-k"                                          # API Client Key
    api_client_key_l                  "--key"                                       # API Client Key
    colored_optput                    "--[no-]color"                                # Use colored output, defaults to enabled
    config_file                       "-c"                                          # The configuration file to use
    config_file_l                     "--config"                                    # The configuration file to use
    defaults                          "--defaults"                                  # Accept default values for all questions
    disable_editing                   "-d"                                          # Do not open EDITOR, just accept the data as is
    disable_editing_l                 "--disable-editing"                           # Do not open EDITOR, just accept the data as is
    editor                            "-e"                                          # Set the editor to use for interactive commands
    editor_l                          "--editor"                                    # Set the editor to use for interactive commands
    environment                       "-E"                                          # Set the Chef environment
    environment_l                     "--environment"                               # Set the Chef environment
    format                            "-F"                                          # Which format to use for output
    format_l                          "--format"                                    # Which format to use for output
    user                              "-u"                                          # API Client Username
    user_l                            "--user"                                      # API Client Username
    print_after                       "--print-after"                               # Show the data after a destructive operation
    purge                             "-P"                                          # Destroy corresponding node and client on the Chef Server, in addition to destroying the azure node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option).
    purge_l                           "--purge"                                     # Destroy corresponding node and client on the Chef Server, in addition to destroying the azure node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option).
    purge_os_disk                     "--purge-os-disk"                             # Destroy corresponding OS Disk
    verbose                           "-V"                                          # More verbose output. Use twice for max verbosity
    verbose_l                         "--verbose"                                   # More verbose output. Use twice for max verbosity
    verify_ssl_cert                   "--verify-ssl-cert"                           # Verify SSL Certificates for communication over HTTPS
    version_chef                      "-v"                                          # Show chef version
    version_chef_l                    "--version"                                   # Show chef version
    say_yes_to_all_prompts            "-y"                                          # Say yes to all prompts for confirmation
    say_yes_to_all_prompts_l          "--yes"                                       # Say yes to all prompts for confirmation
    help                              "-h"                                          # Show help
    help_l                            "--help"                                      # Show help
  end

  factory :azureServerListParameters, class:  AzureKnifeServerListParameters do
    azure_server_url                 "-H"                                          # Your Azure host name
    azure_server_url_l               "--azure-server-url"                           # Your Azure host name
    azure_mgmt_cert                  "-p"                                          # Your Azure PEM file name
    azure_mgmt_cert_l                "--azure-mgmt-cert"                           # Your Azure PEM file name
    azure_subcription_id             "-S"                                          # Your Azure subscription ID
    azure_subcription_id_l           "--azure-subscription-id"                     # Your Azure subscription ID
    server_url                       "-s"                                          # Chef Server URL
    server_url_l                     "--server-url"                                # Chef Server URL
    api_client_key                   "-k"                                          # API Client Key
    api_client_key_l                 "--key"                                       # API Client Key
    colored_optput                   "--[no-]color"                                # Use colored output, defaults to enabled
    config_file                      "-c"                                          # The configuration file to use
    config_file_l                    "--config"                                    # The configuration file to use
    defaults                         "--defaults"                                  # Accept default values for all questions
    disable_editing                  "--disable-editing"                           # Do not open EDITOR, just accept the data as is
    editor                           "-e"                                          # Set the editor to use for interactive commands
    editor_l                         "--editor"                                    # Set the editor to use for interactive commands
    environment                      "-E"                                          # Set the Chef environment
    environment_l                    "--environment"                               # Set the Chef environment
    format                           "-F"                                          # Which format to use for output
    format_l                         "--format"                                    # Which format to use for output
    user                             "-u"                                          # API Client Username
    user_l                           "--user"                                      # API Client Username
    print_after                      "--print-after"                               # Show the data after a destructive operation
    tags                             "-t"                                          # List of tags to output
    tags_l                           "--tags"                                      # List of tags to output
    verbose                          "-V"                                          # More verbose output. Use twice for max verbosity
    verbose_l                        "--verbose"                                   # More verbose output. Use twice for max verbosity
    version_chef                     "-v"                                          # Show chef version
    version_chef_l                   "--version"                                   # Show chef version
    say_yes_to_all_prompts           "-y"                                          # Say yes to all prompts for confirmation
    say_yes_to_all_prompts_l         "--yes"                                       # Say yes to all prompts for confirmation
    help                             "-h"                                          # Show help
    help_l                           "--help"                                      # Show help
  end

  azure_server_create_params_factory  = FactoryGirl.build(:azureServerCreateParameters)
  azure_server_delete_params_factory  = FactoryGirl.build(:azureServerDeleteParameters)
  azure_server_list_params_factory    = FactoryGirl.build(:azureServerListParameters)
  model_obj_server_create = AzureKnifeServerCreateParameters.new
  cert_data, valid_host_name, valid_subscription_id = model_obj_server_create.parse_settings
  mgmt_cert_path = model_obj_server_create.create_user_ssh_key_path(cert_data)
  invalid_mgmt_cert_path = model_obj_server_create.create_user_ssh_key_path(cert_data, mgmt_cert_path + ".invalid",SecureRandom.hex(4))
  valid_template_file_path  = "knife-windows/lib/chef/knife/bootstrap/windows-chef-client-msi.erb"

  # Base Factory for create server
  factory :azureServerCreateBase, class: AzureKnifeServerCreateParameters do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    azure_subcription_id  "#{azure_server_create_params_factory.azure_subcription_id} " + "#{valid_subscription_id}"
    azure_mgmt_cert       "#{azure_server_create_params_factory.azure_mgmt_cert} "      + "#{mgmt_cert_path}"
    azure_server_url      "#{azure_server_create_params_factory.azure_server_url} "     + valid_host_name
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    role_size_l           "#{azure_server_create_params_factory.role_size_l} "          + "Small"
    service_location      "#{azure_server_create_params_factory.service_location} "     + "'East US'"
    # FIXME: Replace the self-created image with Azure-provided image. Pending on CHEF-2821 [http://tickets.opscode.com/browse/CHEF-2821]
    # source_image          "#{azure_server_create_params_factory.source_image} "         + "5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS63DEC20121220"
    # storage_account_l      "#{azure_server_create_params_factory.storage_account_l} "   + "portalvhdspkd86pp67m296"
    source_image          "#{azure_server_create_params_factory.source_image} "         + "ubuntu_passwordless_sudo"
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
  end

  factory :azureServerCreateWithCustomImage, class: :AzureKnifeServerCreateParameters do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    azure_subcription_id  "#{azure_server_create_params_factory.azure_subcription_id} " + "#{valid_subscription_id}"
    azure_mgmt_cert       "#{azure_server_create_params_factory.azure_mgmt_cert} "      + "#{mgmt_cert_path}"
    azure_server_url      "#{azure_server_create_params_factory.azure_server_url} "     + valid_host_name
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    role_size_l           "#{azure_server_create_params_factory.role_size_l} "          + "Medium"
    service_location      "#{azure_server_create_params_factory.service_location} "     + "'East US'"
    source_image          "#{azure_server_create_params_factory.source_image} "         + "ubuntu_passwordless_sudo"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
  end

  factory :azureServerCreateWithCustomImageDiffStorageAcct, parent: :azureServerCreateWithCustomImage do
    storage_account_l      "#{azure_server_create_params_factory.storage_account_l} "   + "portalvhddiffaccount"
  end
  # Base Factory for delete server
  factory :azureServerDeleteBase, class: AzureKnifeServerDeleteParameters do
    azure_subcription_id  "#{azure_server_create_params_factory.azure_subcription_id} " + "#{valid_subscription_id}"
    azure_mgmt_cert       "#{azure_server_create_params_factory.azure_mgmt_cert} "      + "#{mgmt_cert_path}"
    azure_server_url      "#{azure_server_create_params_factory.azure_server_url} "     + valid_host_name
  end

  # Base Factory for list server
  factory :azureServerListBase, class: AzureKnifeServerListParameters do
    azure_subcription_id  "#{azure_server_create_params_factory.azure_subcription_id} " + "#{valid_subscription_id}"
    azure_mgmt_cert       "#{azure_server_create_params_factory.azure_mgmt_cert} "      + "#{mgmt_cert_path}"
    azure_server_url      "#{azure_server_create_params_factory.azure_server_url} "     + valid_host_name
  end

  # Test Case: OP_KAP_1, CreateServerWithDefaults
  factory :azureServerCreateWithDefaults, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + '\'Fr3sca21!\''
    # Please see https://github.com/opscode/knife-azure
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_2, CreateServerWithOnlyServiceRegion
  factory :azureServerCreateWithOnlyServiceRegion, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    service_location      "#{azure_server_create_params_factory.service_location} "     + "'East US'"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
    # Please see https://github.com/opscode/knife-azure
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  factory :azureServerCreateWithInvalidServiceRegion, parent: :azureServerCreateWithOnlyServiceRegion do
     service_location      "#{azure_server_create_params_factory.service_location} "     + "'US East Invalid'"
  end

  # Test Case: OP_KAP_3, CreateServerOfDifferentRoleSize
  factory :azureServerCreateOfDifferentRoleSize, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    role_size             "#{azure_server_create_params_factory.role_size} "            + "Medium"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
    # Please see https://github.com/opscode/knife-azure
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end


  # Test Case: OP_KAP_4, CreateServerWithTCPPortList
  factory :azureServerCreateWithTCPPortList, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    tcp_endpoints         "#{azure_server_create_params_factory.tcp_endpoints} "        + "80:80, 443:8433"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_5, CreateServerWithUDPPortList
  factory :azureServerCreateWithUDPPortList, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    udp_endpoints         "#{azure_server_create_params_factory.udp_endpoints} "        + "161:161, 111:111"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_6, CreateServerWithRegionAndExistentHostedService
  factory :azureServerCreateWithRegionAndExistentHostedService, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    service_location      "#{azure_server_create_params_factory.service_location} "     + "'East US'"
    # FIXME here we assuming the hosted service is already available
    hosted_service_desc   "#{azure_server_create_params_factory.hosted_service_desc} "  + "existhostedsrvc"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_7, CreateServerWithRegionAndNonExistentHostedService
  factory :azureServerCreateWithRegionAndNonExistentHostedService, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    service_location      "#{azure_server_create_params_factory.service_location} "     + "'East US'"
    hosted_service_desc   "#{azure_server_create_params_factory.hosted_service_desc} "  + "nonexisthostedsrvc"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_8, CreateServerWithRegionAndExistentStorageService
  factory :azureServerCreateWithRegionAndExistentStorageService, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    # Here we assume storage service is available at region East US
    service_location      "#{azure_server_create_params_factory.service_location} "     + "'East US'"
    storage_account       "#{azure_server_create_params_factory.storage_account} "      + " usstosrvc"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_9, CreateServerWithRegionAndNonExistentStorageService
  factory :azureServerCreateWithRegionAndNonExistentStorageService, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    service_location      "#{azure_server_create_params_factory.service_location} "     + "'East US'"
    storage_account       "#{azure_server_create_params_factory.storage_account} "      + "nonexiststosrvc"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_10, CreateServerWithHostedAndStorageService
  factory :azureServerCreateWithHostedAndStorageService, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    # Here we assume storage and hosted services is available at region - East US
    service_location      "#{azure_server_create_params_factory.service_location} "     + "'East US'"
    storage_account       "#{azure_server_create_params_factory.storage_account} "      + "dbiopscode"
    hosted_service_desc   "#{azure_server_create_params_factory.hosted_service_desc} "  + "existhostedsrvc"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

# Test Case: OP_KAP_11, CreateServerWithRegionWithoutSpecifyingStorageService
  factory :azureServerCreateWithRegionWithoutStorageService, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    service_location      "#{azure_server_create_params_factory.service_location} "     + "'East US'"
    hosted_service_desc   "#{azure_server_create_params_factory.hosted_service_desc} "  + "existhostedsrvc"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_12, CreateServerWithRegionWithoutSpecifyingStorageService
  factory :azureServerCreateWithRegionWithoutStorageService2, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    service_location      "#{azure_server_create_params_factory.service_location} "     + "'East US'"
    hosted_service_desc   "#{azure_server_create_params_factory.hosted_service_desc} "  + "existhostedsrvc"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_13, CreateServerWithRootSSHUser
  factory :azureServerCreateWithRootSSHUser, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "root"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_14, CreateServerWithInvalidSSHPassword
  factory :azureServerCreateWithInvalidSSHPassword, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "azureuser"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_15, CreateServerWithSpecificOSDisk
  factory :azureServerCreateWithSpecificOSDisk, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    os_disk_name          "#{azure_server_create_params_factory.os_disk_name} "         + "diskname"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_16, DeleteServerThatDoesNotExist
  factory :azureServerDeleteNonExistent, parent: :azureServerDeleteBase do
  end

  # Test Case: OP_KAP_17, DeleteServerWithoutOSDisk
  factory :azureServerDeleteWithoutOSDisk, parent: :azureServerDeleteBase do
  end

  # Test Case: OP_KAP_18, DeleteServerWithOSDisk
  factory :azureServerDeleteWithOSDisk, parent: :azureServerDeleteBase do
    purge_os_disk          "#{azure_server_delete_params_factory.purge_os_disk} "
  end

  # Test Case: OP_KAP_19, DeleteMutipleServers
  factory :azureServerDeleteMultiple, parent: :azureServerDeleteBase do
  end

  # Test Case: OP_KAP_20, ListServerEmpty
  factory :azureServerListEmpty, parent: :azureServerListBase do
  end

  # Test Case: OP_KAP_21, ListServerNonEmpty
  factory :azureServerListNonEmpty, parent: :azureServerListBase do
  end

  factory :azureServerListInvalidHost, parent: :azureServerListBase do
    azure_server_url      "#{azure_server_create_params_factory.azure_server_url} "     + "invalid_host_name"
  end

  factory :azureServerListInvalidSubscription, parent: :azureServerListBase do
     azure_subcription_id  "#{azure_server_create_params_factory.azure_subcription_id} " + "invalid_subscription_id"
  end

  factory :azureServerListInvalidCert, parent: :azureServerListBase do
    azure_subcription_id "#{azure_server_create_params_factory.azure_mgmt_cert} " + invalid_mgmt_cert_path
  end

  # Test Case: OP_KAP_22, DeleteServerPurge
  factory :azureServerDeletePurge, parent: :azureServerDeleteBase do
  end

  # Test Case: OP_KAP_23, DeleteServerDontPurge
  factory :azureServerDeleteDontPurge, parent: :azureServerDeleteBase do
  end

  # Test Case: OP_KAP_24, CreateServerWithRoleAndRecipe
  factory :azureServerCreateWithRoleAndRecipe, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    # FIXME here we are assuming requied roles/recipes are available with the test account.
    # Eventually this process will also be automated.
    run_list              "#{azure_server_create_params_factory.run_list} "             + "recipe[build-essential], role[webserver]"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_25, CreateServerWithInvalidRole
  factory :azureServerCreateWithInvalidRole, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    # FIXME here we are assuming requied roles/recipes are available with the test account.
    # Eventually this process will also be automated.
    run_list              "#{azure_server_create_params_factory.run_list} "             + "recipe[build-essential], role[invalid-role]"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_26, CreateServerWithInvalidRecipe
  factory :azureServerCreateWithInvalidRecipe, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    # FIXME here we are assuming requied roles/recipes are available with the test account.
    # Eventually this process will also be automated.
    run_list              "#{azure_server_create_params_factory.run_list} "             + "recipe[invalid-recipe]"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end

  # Test Case: OP_KAP_27, CreateWindowsServerWithWinRMBasicAuth
  factory :azureWindowsServerCreateWithWinRMBasicAuth, class: AzureKnifeServerCreateParameters do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    azure_subcription_id  "#{azure_server_create_params_factory.azure_subcription_id} " + "#{valid_subscription_id}"
    azure_mgmt_cert       "#{azure_server_create_params_factory.azure_mgmt_cert} "      + "#{mgmt_cert_path}"
    azure_server_url      "#{azure_server_create_params_factory.azure_server_url} "     + valid_host_name
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    role_size_l           "#{azure_server_create_params_factory.role_size_l} "          + "Small"
    service_location      "#{azure_server_create_params_factory.service_location} "     + "'East US'"
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    source_image          "#{azure_server_create_params_factory.source_image} "         + "Win2k8BasicSSH"
    winrm_password        "#{azure_server_create_params_factory.winrm_password} "       + "Fr3sca21!"
    winrm_port            "#{azure_server_create_params_factory.winrm_port} "           + "5985"
    winrm_transport       "#{azure_server_create_params_factory.winrm_transport} "      + "plaintext"
    template_file         "#{azure_server_create_params_factory.template_file} "        + "#{valid_template_file_path}"
    bootstrap_protocol    "#{azure_server_create_params_factory.bootstrap_protocol} "   + "winrm"
  end

  # Test Case: OP_KAP_28, CreateWindowsServerWithSSHAuth
  factory :azureWindowsServerCreateWithSSHAuth, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    source_image          "#{azure_server_create_params_factory.source_image} "         + "opscode08base"
    ssh_username          "#{azure_server_create_params_factory.ssh_username} "         + "azureuser"
    ssh_password          "#{azure_server_create_params_factory.ssh_password} "         + "Fr3sca21!"
    template_file         "#{azure_server_create_params_factory.template_file} "        + "#{valid_template_file_path}"
  end

  # Test Case: OP_KAP_29, CreateLinuxServerWithWinRM
  factory :azureLinuxServerCreateWithWinRM, parent: :azureServerCreateBase do
    name_of_the_node =    "az#{SecureRandom.hex(4)}"
    node_name             "#{azure_server_create_params_factory.node_name} "            + name_of_the_node
    role_name_l           "#{azure_server_create_params_factory.role_name_l} "          + name_of_the_node
    host_name_l           "#{azure_server_create_params_factory.host_name_l} "          + name_of_the_node
    winrm_password        "#{azure_server_create_params_factory.winrm_password} "       + "winRmPassw0rd"
    winrm_port            "#{azure_server_create_params_factory.winrm_port} "           + "5985"
    winrm_transport       "#{azure_server_create_params_factory.winrm_transport} "      + "plaintext"
    winrm_user            "#{azure_server_create_params_factory.winrm_user} "           + "winRmUser"
#    distro                "#{azure_server_create_params_factory.distro} "               + "centos5-gems"
  end
end
