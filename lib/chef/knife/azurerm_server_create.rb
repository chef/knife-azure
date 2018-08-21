#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
#
# Copyright:: Copyright 2009-2018, Chef Software Inc.
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

require "chef/knife/azurerm_base"
require "securerandom"
require "chef/knife/bootstrap/common_bootstrap_options"
require "chef/knife/bootstrap/bootstrapper"

class Chef
  class Knife
    class AzurermServerCreate < Knife

      include Knife::AzurermBase
      include Knife::Bootstrap::CommonBootstrapOptions
      include Knife::Bootstrap::Bootstrapper

      banner "knife azurerm server create (options)"

      attr_accessor :initial_sleep_delay

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_port,
        :long => "--ssh-port PORT",
        :description => "The ssh port. Default is 22."

      option :node_ssl_verify_mode,
        :long        => "--node-ssl-verify-mode [peer|none]",
        :description => "Whether or not to verify the SSL cert for all HTTPS requests."

      option :winrm_user,
        :short => "-x USERNAME",
        :long => "--winrm-user USERNAME",
        :description => "The WinRM username",
        :default => "Administrator",
        :proc => Proc.new { |key| Chef::Config[:knife][:winrm_user] = key }

      option :winrm_password,
        :short => "-P PASSWORD",
        :long => "--winrm-password PASSWORD",
        :description => "The WinRM password",
        :proc => Proc.new { |key| Chef::Config[:knife][:winrm_password] = key }

      option :azure_storage_account,
        :short => "-a NAME",
        :long => "--azure-storage-account NAME",
        :description => "Required for advanced server-create option.
                                      A name for the storage account that is unique within Windows Azure. Storage account names must be
                                      between 3 and 24 characters in length and use numbers and lower-case letters only.
                                      This name is the DNS prefix name and can be used to access blobs, queues, and tables in the storage account.
                                      For example: http://ServiceName.blob.core.windows.net/mycontainer/"

      option :azure_storage_account_type,
        :long => "--azure-storage-account-type TYPE",
        :description => "Optional. One of the following account types (case-sensitive):
                                      Standard_LRS (Standard Locally-redundant storage)
                                      Standard_ZRS (Standard Zone-redundant storage)
                                      Standard_GRS (Standard Geo-redundant storage)
                                      Standard_RAGRS (Standard Read access geo-redundant storage)
                                      Premium_LRS (Premium Locally-redundant storage)",
        :default => "Standard_GRS"

      option :azure_vm_name,
        :long => "--azure-vm-name NAME",
        :description => "Required. Specifies the name for the virtual machine.
                        The name must be unique within the ResourceGroup.
                        The azure vm name cannot be more than 15 characters long"

      option :azure_service_location,
        :short => "-m LOCATION",
        :long => "--azure-service-location LOCATION",
        :description => "Required if not using an Affinity Group. Specifies the geographic location - the name of the data center location that is valid for your subscription.
                                      Eg: westus, eastus, eastasia, southeastasia, northeurope, westeurope",
        :proc        => Proc.new { |lo| Chef::Config[:knife][:azure_service_location] = lo }

      option :azure_os_disk_name,
        :short => "-o DISKNAME",
        :long => "--azure-os-disk-name DISKNAME",
        :description => "Optional. Specifies the friendly name of the disk containing the guest OS image in the image repository."

      option :azure_image_reference_publisher,
        :long => "--azure-image-reference-publisher PUBLISHER_NAME",
        :description => "Optional. Specifies the publisher of the image used to create the virtual machine.
                          eg. OpenLogic, Canonical, MicrosoftWindowsServer"

      option :azure_image_reference_offer,
        :long => "--azure-image-reference-offer OFFER",
        :description => "Optional. Specifies the offer of the image used to create the virtual machine.
                          eg. CentOS, UbuntuServer, WindowsServer"

      option :azure_image_reference_sku,
        :long => "--azure-image-reference-sku SKU",
        :description => "Optional. Specifies the SKU of the image used to create the virtual machine."

      option :azure_image_reference_version,
        :long => "--azure-image-reference-version VERSION",
        :description => "Optional. Specifies the version of the image used to create the virtual machine.
                          Default value is 'latest'",
        :default => "latest"

      option :azure_image_os_type,
        :long => "--azure-image-os-type OSTYPE",
        :description => "Optional. Specifies the image OS Type for which server needs to be created. Accepted values ubuntu|centos|rhel|debian|windows"

      option :azure_vm_size,
        :short => "-z SIZE",
        :long => "--azure-vm-size SIZE",
        :description => "Optional. Size of virtual machine. Default is Standard_A1_v2.
                        Eg: Standard_A2, Standard_F2, Standard_G1 etc.",
        :default => "Standard_A1_v2",
        :proc => Proc.new { |si| Chef::Config[:knife][:azure_vm_size] = si }

      option :azure_availability_set,
             :long => "--azure-availability-set NAME",
             :description => "Optional. Name of availability set to add virtual machine into."

      option :azure_vnet_name,
        :long => "--azure-vnet-name VNET_NAME",
        :description => "Optional. Specifies the virtual network name.
                         This may be the name of an existing vnet present under the given resource group
                         or this may be the name of a new vnet to be added in the given resource group.
                         If not specified then azure-vm-name will be taken as the default name for vnet name as well.
                         Along with this option azure-vnet-subnet-name option can also be specified or it can also be skipped."

      option :azure_vnet_subnet_name,
        :long => "--azure-vnet-subnet-name VNET_SUBNET_NAME",
        :description => "Optional. Specifies the virtual network subnet name.
                         Must be specified only with azure-vnet-name option.
                         This may be the name of an existing subnet present under the given virtual network
                         or this may be the name of a new subnet to be added in the given virtual network.
                         If not specified then azure-vm-name will be taken as the default name for subnet name as well.
                         Value as 'GatewaySubnet' cannot be used as the name for the --azure-vnet-subnet-name option."

      option :ssh_public_key,
        :long => "--ssh-public-key FILENAME",
        :description => "It is the ssh-rsa public key path. Specify either ssh-password or ssh-public-key"

      option :thumbprint,
        :long => "--thumbprint THUMBPRINT",
        :description => "The thumprint of the ssl certificate"

      option :cert_passphrase,
        :long => "--cert-passphrase PASSWORD",
        :description => "SSL Certificate Password"

      option :cert_path,
        :long => "--cert-path PATH",
        :description => "SSL Certificate Path"

      option :tcp_endpoints,
        :short => "-t PORT_LIST",
        :long => "--tcp-endpoints PORT_LIST",
        :description => "Comma-separated list of TCP ports to open e.g. '80,433'"

      option :server_count,
        :long => "--server-count COUNT",
        :description => "Number of servers to create with same configuration.
                                    Maximum count is 5. Default value is 1.",
        :default => 1

      option :ohai_hints,
        :long => "--ohai-hints HINT_OPTIONS",
        :description => "Hint option names to be set in Ohai configuration of the target node.
                                     Supported values are: vm_name, public_fqdn and platform.
                                     User can pass any comma separated combination of these values like 'vm_name,public_fqdn'.
                                     Default value is 'default' which corresponds to the supported values list mentioned here.",
        :default => "default"

      def run
        $stdout.sync = true
        # check azure cli version due to azure changed `azure` to `az` in azure-cli2.0
        get_azure_cli_version
        validate_arm_keys!(
          :azure_resource_group_name,
          :azure_vm_name,
          :azure_service_location
        )

        begin
          validate_params!
          set_default_image_reference!
          ssh_override_winrm if !is_image_windows?
          vm_details = service.create_server(create_server_def)
        rescue => error
          service.common_arm_rescue_block(error)
          exit
        end
      end

      def create_server_def
        server_def = {
          :azure_resource_group_name => locate_config_value(:azure_resource_group_name),
          :azure_storage_account => locate_config_value(:azure_storage_account),
          :azure_storage_account_type => locate_config_value(:azure_storage_account_type),
          :azure_vm_name => locate_config_value(:azure_vm_name),
          :azure_service_location => locate_config_value(:azure_service_location),
          :azure_os_disk_name => locate_config_value(:azure_os_disk_name),
          :azure_os_disk_caching => locate_config_value(:azure_os_disk_caching),
          :azure_os_disk_create_option => locate_config_value(:azure_os_disk_create_option),
          :azure_vm_size => locate_config_value(:azure_vm_size),
          :azure_image_reference_publisher => locate_config_value(:azure_image_reference_publisher),
          :azure_image_reference_offer => locate_config_value(:azure_image_reference_offer),
          :azure_image_reference_sku => locate_config_value(:azure_image_reference_sku),
          :azure_image_reference_version => locate_config_value(:azure_image_reference_version),
          :winrm_user => locate_config_value(:winrm_user),
          :azure_availability_set => locate_config_value(:azure_availability_set),
          :azure_vnet_name => locate_config_value(:azure_vnet_name),
          :azure_vnet_subnet_name => locate_config_value(:azure_vnet_subnet_name),
          :ssl_cert_fingerprint => locate_config_value(:thumbprint),
          :cert_path => locate_config_value(:cert_path),
          :cert_password => locate_config_value(:cert_passphrase),
          :vnet_subnet_address_prefix => locate_config_value(:vnet_subnet_address_prefix),
          :server_count => locate_config_value(:server_count)
        }

        server_def[:tcp_endpoints] = locate_config_value(:tcp_endpoints) if locate_config_value(:tcp_endpoints)

        # We assign azure_vm_name to chef_node_name If node name is nill because storage account name is combination of hash value and node name.
        config[:chef_node_name] ||= locate_config_value(:azure_vm_name)

        server_def[:azure_storage_account] = locate_config_value(:azure_vm_name) if server_def[:azure_storage_account].nil?
        server_def[:azure_storage_account] = server_def[:azure_storage_account].gsub(/[!@#$%^&*()_-]/, "")

        server_def[:azure_os_disk_name] = locate_config_value(:azure_vm_name) if server_def[:azure_os_disk_name].nil?
        server_def[:azure_os_disk_name] = server_def[:azure_os_disk_name].gsub(/[!@#$%^&*()_-]/, "")

        server_def[:azure_vnet_name] = locate_config_value(:azure_vm_name) if server_def[:azure_vnet_name].nil?
        server_def[:azure_vnet_subnet_name] = locate_config_value(:azure_vm_name) if locate_config_value(:azure_vnet_subnet_name).nil?

        server_def[:chef_extension] = get_chef_extension_name
        server_def[:chef_extension_publisher] = get_chef_extension_publisher
        server_def[:chef_extension_version] = locate_config_value(:azure_chef_extension_version)
        server_def[:chef_extension_public_param] = get_chef_extension_public_params
        server_def[:chef_extension_private_param] = get_chef_extension_private_params
        server_def[:auto_upgrade_minor_version] = false

        if is_image_windows?
          server_def[:admin_password] = locate_config_value(:winrm_password)
        else
          server_def[:ssh_user] = locate_config_value(:ssh_user)
          server_def[:ssh_password] = locate_config_value(:ssh_password)
          server_def[:disablePasswordAuthentication] = "false"
          if locate_config_value(:ssh_public_key)
            server_def[:disablePasswordAuthentication] = "true"
            server_def[:ssh_key] = File.read(locate_config_value(:ssh_public_key))
          end
        end

        server_def
      end

      def supported_ohai_hints
        %w{
          vm_name
          public_fqdn
          platform
        }
      end

      def format_ohai_hints(ohai_hints)
        ohai_hints = ohai_hints.split(",").each { |hint| hint.strip! }
        ohai_hints.join(",")
      end

      def is_supported_ohai_hint?(hint)
        supported_ohai_hints.any? { |supported_ohai_hint| hint.eql? supported_ohai_hint }
      end

      def validate_ohai_hints
        hint_values = locate_config_value(:ohai_hints).split(",")
        hint_values.each do |hint|
          if ! is_supported_ohai_hint?(hint)
            raise ArgumentError, "Ohai Hint name #{hint} passed is not supported. Please run the command help to see the list of supported values."
          end
        end
      end

      private

      def ssh_override_winrm
        # unchanged ssh_user and changed winrm_user, override ssh_user
        if locate_config_value(:ssh_user).eql?(options[:ssh_user][:default]) &&
            !locate_config_value(:winrm_user).eql?(options[:winrm_user][:default])
          config[:ssh_user] = locate_config_value(:winrm_user)
        end

        if locate_config_value(:ssh_password).nil? &&
            !locate_config_value(:winrm_password).nil?
          config[:ssh_password] = locate_config_value(:winrm_password)
        end
      end

      def set_default_image_reference!
        begin
          if locate_config_value(:azure_image_os_type)
            validate_publisher_and_offer
            ## if azure_image_os_type is given (with or without azure-image-reference-sku) and other image reference parameters are not given,
            # set default image reference parameters
            case locate_config_value(:azure_image_os_type)
            when "ubuntu"
              set_os_image("Canonical", "UbuntuServer", "14.04.2-LTS")
            when "centos"
              set_os_image("OpenLogic", "CentOS", "7.1")
            when "rhel"
              set_os_image("RedHat", "RHEL", "7.2")
            when "debian"
              set_os_image("credativ", "Debian", "7")
            when "windows"
              set_os_image("MicrosoftWindowsServer", "WindowsServer", "2012-R2-Datacenter")
            else
              raise ArgumentError, "Invalid value of --azure-image-os-type. Accepted values ubuntu|centos|windows"
            end
          else
            validate_arm_keys!(:azure_image_os_type) unless is_image_os_type?
          end
        rescue => error
          ui.error("#{error.message}")
          Chef::Log.debug("#{error.backtrace.join("\n")}")
          exit
        end
        # final verification for image reference parameters
        validate_arm_keys!(:azure_image_reference_publisher,
            :azure_image_reference_offer,
            :azure_image_reference_sku,
            :azure_image_reference_version)
      end

      def set_os_image(publisher, img_offer, default_os_version)
        config[:azure_image_reference_publisher] = publisher
        config[:azure_image_reference_offer] = img_offer
        config[:azure_image_reference_sku] = locate_config_value(:azure_image_reference_sku) ? locate_config_value(:azure_image_reference_sku) : default_os_version
      end

      def is_image_os_type?
        locate_config_value(:azure_image_reference_publisher) && locate_config_value(:azure_image_reference_offer) && locate_config_value(:azure_image_reference_sku) && locate_config_value(:azure_image_reference_version)
      end

      def validate_publisher_and_offer
        if locate_config_value(:azure_image_reference_publisher) || locate_config_value(:azure_image_reference_offer)
          # if azure_image_os_type is given and any of the other image reference parameters like publisher or offer are also given,
          # raise error
          raise ArgumentError, 'Please specify either --azure-image-os-type OR --azure-image-os-type with --azure-image-reference-sku or 4 image reference parameters i.e.
            --azure-image-reference-publisher, --azure-image-reference-offer, --azure-image-reference-sku, --azure-image-reference-version."'
        end
      end
    end
  end
end
