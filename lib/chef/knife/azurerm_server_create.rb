#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
#
# Copyright:: Copyright (c) 2016 Opscode, Inc.
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

require 'chef/knife/azurerm_base'
require 'securerandom'
require 'chef/knife/bootstrap/azurerm_bootstrap_options'
require 'chef/knife/bootstrap/bootstrapper'

class Chef
  class Knife
    class AzurermServerCreate < Knife

      include Knife::AzurermBase
      include Knife::Bootstrap::AzurermBootstrapOptions
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
        :default => 'Standard_GRS'

      option :azure_vm_name,
        :long => "--azure-vm-name NAME",
        :description => "Required. Specifies the name for the virtual machine.
                        The name must be unique within the ResourceGroup.
                        The azure vm name cannot be more than 15 characters long"

      option :azure_service_location,
        :short => "-m LOCATION",
        :long => "--azure-service-location LOCATION",
        :description => "Required if not using an Affinity Group. Specifies the geographic location - the name of the data center location that is valid for your subscription.
                                      Eg: West US, East US, East Asia, Southeast Asia, North Europe, West Europe",
        :proc        => Proc.new { |lo| Chef::Config[:knife][:azure_service_location] = lo }

      option :azure_os_disk_name,
        :short => "-o DISKNAME",
        :long => "--azure-os-disk-name DISKNAME",
        :description => "Optional. Specifies the friendly name of the disk containing the guest OS image in the image repository."

      option :azure_os_disk_caching,
        :long => "--azure-os-disk-caching CACHING_TYPE",
        :description => "Optional. Specifies the caching requirements. options: 'None' or 'ReadOnly' or 'ReadWrite'.",
        :default => 'None'

      option :azure_os_disk_create_option,
        :long => "--azure-os-disk-create-option CREATE_OPTION",
        :description => "Optional. Specifies how the virtual machine should be created. options: 'fromImage' or 'attach' or 'empty'.",
        :default => 'fromImage'

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
        :default => 'latest'

      option :azure_image_os_type,
        :long => "--azure-image-os-type OSTYPE",
        :description => "Optional. Specifies the image OS Type for which server needs to be created. Accepted values ubuntu|centos|windows"

      option :azure_vm_size,
        :short => "-z SIZE",
        :long => "--azure-vm-size SIZE",
        :description => "Optional. Size of virtual machine (ExtraSmall, Small, Medium, Large, ExtraLarge)",
        :default => 'Small',
        :proc => Proc.new { |si| Chef::Config[:knife][:azure_vm_size] = si }

      option :azure_network_name,
        :long => "--azure-network-name NETWORK_NAME",
        :description => "Optional. Specifies the network of virtual machine"

      option :azure_subnet_name,
        :long => "--azure-subnet-name SUBNET_NAME",
        :description => "Optional. Specifies the subnet of virtual machine"

      option :identity_file,
        :long => "--identity-file FILENAME",
        :description => "SSH identity file for authentication, optional. It is the RSA private key path. Specify either ssh-password or identity-file"

      option :identity_file_passphrase,
        :long => "--identity-file-passphrase PASSWORD",
        :description => "SSH key passphrase. Optional, specify if passphrase for identity-file exists"

      option :thumbprint,
        :long => "--thumbprint THUMBPRINT",
        :description => "The thumprint of the ssl certificate"

      option :cert_passphrase,
        :long => "--cert-passphrase PASSWORD",
        :description => "SSL Certificate Password"

      option :cert_path,
        :long => "--cert-path PATH",
        :description => "SSL Certificate Path"


      def run
        $stdout.sync = true

        validate_arm_keys!(
          :azure_resource_group_name,
          :azure_vm_name,
          :azure_service_location
        )

        set_default_image_reference

        ssh_override_winrm if !is_image_windows?

        Chef::Log.info("creating...")
        begin
          vm_details = service.create_server(create_server_def)
        rescue => error
          if error.class == MsRestAzure::AzureOperationError && error.body
            if error.body['error']['code']
              ui.error("#{error.body['error']['message']}")
            else
              ui.error(error.body)
            end
          else
            ui.error("#{error.message}")
            ui.error("#{error.backtrace.join("\n")}")
          end
          exit
        end

        msg_server_summary(vm_details)
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
          :azure_network_name => locate_config_value(:azure_network_name),
          :azure_subnet_name => locate_config_value(:azure_subnet_name),
          :ssl_cert_fingerprint => locate_config_value(:thumbprint),
          :cert_path => locate_config_value(:cert_path),
          :cert_password => locate_config_value(:cert_passphrase)
        }

        server_def[:azure_storage_account] = locate_config_value(:azure_vm_name) if server_def[:azure_storage_account].nil?
        server_def[:azure_storage_account] = server_def[:azure_storage_account].gsub(/[!@#$%^&*()_-]/,'')

        server_def[:azure_os_disk_name] = locate_config_value(:azure_vm_name) if server_def[:azure_os_disk_name].nil?
        server_def[:azure_os_disk_name] = server_def[:azure_os_disk_name].gsub(/[!@#$%^&*()_-]/,'')

        server_def[:azure_network_name] = locate_config_value(:azure_vm_name) if server_def[:azure_network_name].nil?
        server_def[:azure_subnet_name] = locate_config_value(:azure_vm_name) if server_def[:azure_subnet_name].nil?

        server_def[:chef_extension] = get_chef_extension_name
        server_def[:chef_extension_publisher] = get_chef_extension_publisher
        server_def[:chef_extension_version] = locate_config_value(:azure_chef_extension_version)
        server_def[:chef_extension_public_param] = get_chef_extension_public_params
        server_def[:chef_extension_private_param] = get_chef_extension_private_params

        if is_image_windows?
          server_def[:admin_password] = locate_config_value(:winrm_password)
        else
          server_def[:ssh_user] = locate_config_value(:ssh_user)
          server_def[:ssh_password] = locate_config_value(:ssh_password)
          server_def[:identity_file] = locate_config_value(:identity_file)
          server_def[:identity_file_passphrase] = locate_config_value(:identity_file_passphrase)
        end

        server_def
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

      def set_default_image_reference
        if locate_config_value(:azure_image_os_type)
          if (locate_config_value(:azure_image_reference_publisher) || locate_config_value(:azure_image_reference_offer) || locate_config_value(:azure_image_reference_sku))
            # if azure_image_os_type is given and other image reference parameters are also given,
            # raise error
            ui.error("Please specify either --azure-image-os-type OR other image reference parameters i.e.
              --azure-image-reference-publisher, --azure-image-reference-offer, --azure-image-reference-sku, --azure-image-reference-version.")
            exit 1
          else
            # if azure_image_os_type is given and other image reference parameters are not given,
            # set default image reference parameters
            case locate_config_value(:azure_image_os_type)
            when "ubuntu"
              config[:azure_image_reference_publisher] = "Canonical"
              config[:azure_image_reference_offer] = "UbuntuServer"
              config[:azure_image_reference_sku] = "14.04.2-LTS"
            when "centos"
              config[:azure_image_reference_publisher] = "OpenLogic"
              config[:azure_image_reference_offer] = "CentOS"
              config[:azure_image_reference_sku] = "7.1"
            when "windows"
              config[:azure_image_reference_publisher] = "MicrosoftWindowsServer"
              config[:azure_image_reference_offer] = "WindowsServer"
              config[:azure_image_reference_sku] = "2012-R2-Datacenter"
            else
              ui.error("Invalid value of --azure-image-os-type. Accepted values ubuntu|centos|windows")
              exit 1
            end
          end
        else
          if (locate_config_value(:azure_image_reference_publisher) && locate_config_value(:azure_image_reference_offer) && locate_config_value(:azure_image_reference_sku) && locate_config_value(:azure_image_reference_version))
            # if azure_image_os_type is not given and other image reference parameters are given,
            # do nothing
          else
            # if azure_image_os_type is not given and other image reference parameters are also not given,
            # throw error for azure_image_os_type
            validate_arm_keys!(:azure_image_os_type)
          end
        end

        # final verification for image reference parameters
        validate_arm_keys!(:azure_image_reference_publisher,
            :azure_image_reference_offer,
            :azure_image_reference_sku,
            :azure_image_reference_version)
      end
    end
  end
end
