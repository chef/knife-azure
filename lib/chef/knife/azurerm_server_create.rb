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
require 'chef/knife/bootstrap/bootstrap_options'
require 'chef/knife/bootstrap/bootstrapper'

class Chef
  class Knife
    class AzurermServerCreate < Knife

      include Knife::AzurermBase
      include Knife::Bootstrap::BootstrapOptions
      include Knife::Bootstrap::Bootstrapper

      banner "knife azurerm server create (options)"

      attr_accessor :initial_sleep_delay

      option :bootstrap_protocol,
        :long => "--bootstrap-protocol protocol",
        :description => "Protocol to bootstrap windows servers. options: 'winrm' or 'ssh' or 'cloud-api'.",
        :default => "winrm"

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
        :description => "The ssh port. Default is 22. If --azure-connect-to-existing-dns set then default SSH port is random"

      option :node_ssl_verify_mode,
        :long        => "--node-ssl-verify-mode [peer|none]",
        :description => "Whether or not to verify the SSL cert for all HTTPS requests.",
        :proc        => Proc.new { |v|
          valid_values = ["none", "peer"]
          unless valid_values.include?(v)
            raise "Invalid value '#{v}' for --node-ssl-verify-mode. Valid values are: #{valid_values.join(", ")}"
          end
        }

      option :node_verify_api_cert,
        :long        => "--[no-]node-verify-api-cert",
        :description => "Verify the SSL cert for HTTPS requests to the Chef server API.",
        :boolean     => true

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
        :description => "Optional. ARM option. One of the following account types (case-sensitive):
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
        :description => "Optional. ARM option. Specifies the caching requirements. options: 'None' or 'ReadOnly' or 'ReadWrite'.",
        :default => 'None'

      option :azure_os_disk_create_option,
        :long => "--azure-os-disk-create-option CREATE_OPTION",
        :description => "Optional. ARM option. Specifies how the virtual machine should be created. options: 'fromImage' or 'attach' or 'empty'.",
        :default => 'fromImage'

      option :azure_image_reference_publisher,
        :long => "--azure-image-reference-publisher PUBLISHER_NAME",
        :description => "Required. ARM option. Specifies the publisher of the image used to create the virtual machine.
                                      Do a \"knife azure image list --azure-api-mode ARM\" to see a list of available Publishers."

      option :azure_image_reference_offer,
        :long => "--azure-image-reference-offer OFFER",
        :description => "Required. ARM option. Specifies the offer of the image used to create the virtual machine.
                                      Do a \"knife azure image list --azure-api-mode ARM\" to see a list of available Offers."

      option :azure_image_reference_sku,
        :long => "--azure-image-reference-sku SKU",
        :description => "Required. ARM option. Specifies the SKU of the image used to create the virtual machine.
                                      Do a \"knife azure image list --azure-api-mode ARM\" to see a list of available SKUs."

      option :azure_image_reference_version,
        :long => "--azure-image-reference-version VERSION",
        :description => "Optional. ARM option. Specifies the version of the image used to create the virtual machine.
                                      You can use the value of 'latest' to use the latest version of an image.
                                      Do a \"knife azure image list --azure-api-mode ARM\" to see a list of available Versions.",
        :default => 'latest'

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

        Chef::Log.warn("ARM commands are still in development phase...Current implementation supports server creation with basic options.")
        validate_arm_keys!(
          :azure_resource_group_name,
          :azure_vm_name,
          :azure_service_location,
          :azure_image_reference_publisher,
          :azure_image_reference_offer,
          :azure_image_reference_sku,
          :azure_image_reference_version
        )

        ssh_override_winrm if %w(ssh cloud-api).include?(locate_config_value(:bootstrap_protocol)) and !is_image_windows?

        Chef::Log.info("creating...")

        vm_details = service.create_server(create_server_def)

        bootstrap_exec(vm_details) unless locate_config_value(:bootstrap_protocol) == 'cloud-api'
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
          :bootstrap_proto => locate_config_value(:bootstrap_protocol),
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

        if is_image_windows?
          if not locate_config_value(:winrm_password) or not locate_config_value(:bootstrap_protocol)
            ui.error("WinRM Password and Bootstrapping Protocol are compulsory parameters")
            exit 1
          end
          # We can specify the AdminUsername after API version 2013-03-01. However, in this API version,
          # the AdminUsername is a required parameter.
          # Also, the user name cannot be Administrator, Admin, Admin1 etc, for enhanced security (provided by Azure)
          if locate_config_value(:winrm_user).nil? || locate_config_value(:winrm_user).downcase =~ /admin*/
            ui.error("WinRM User is compulsory parameter and it cannot be named 'admin*'")
            exit 1
          end
          # take cares of when user name contains domain
          # azure add role api doesn't support '\\' in user name
          if locate_config_value(:winrm_user) && locate_config_value(:winrm_user).split("\\").length.eql?(2)
            server_def[:winrm_user] = locate_config_value(:winrm_user).split("\\")[1]
          end
        else
          if not locate_config_value(:ssh_user)
            ui.error("SSH User is compulsory parameter")
            exit 1
          end
          unless locate_config_value(:ssh_password) or locate_config_value(:identity_file)
            ui.error("Specify either SSH Key or SSH Password")
            exit 1
          end
        end

        if is_image_windows?
          server_def[:os_type] = 'Windows'
          server_def[:admin_password] = locate_config_value(:winrm_password)
          server_def[:bootstrap_proto] = locate_config_value(:bootstrap_protocol)
        else
          server_def[:os_type] = 'Linux'
          server_def[:bootstrap_proto] = (locate_config_value(:bootstrap_protocol) == 'winrm') ? 'ssh' : locate_config_value(:bootstrap_protocol)
          server_def[:ssh_user] = locate_config_value(:ssh_user)
          server_def[:ssh_password] = locate_config_value(:ssh_password)
          server_def[:identity_file] = locate_config_value(:identity_file)
          server_def[:identity_file_passphrase] = locate_config_value(:identity_file_passphrase)
        end

        if is_image_windows? && server_def[:bootstrap_proto] == 'winrm'
          port = locate_config_value(:winrm_port) || '5985'
        elsif server_def[:bootstrap_proto] == 'ssh'
          port = locate_config_value(:ssh_port) || '22'
        end

        server_def[:port] = port

        server_def
      end

      private

      def ssh_override_winrm
        # unchanged ssh_user and changed winrm_user, override ssh_user
        if locate_config_value(:ssh_user).eql?(options[:ssh_user][:default]) &&
            !locate_config_value(:winrm_user).eql?(options[:winrm_user][:default])
          config[:ssh_user] = locate_config_value(:winrm_user)
        end
        # unchanged ssh_port and changed winrm_port, override ssh_port
        if locate_config_value(:ssh_port).eql?(options[:ssh_port][:default]) &&
            !locate_config_value(:winrm_port).eql?(options[:winrm_port][:default])
          config[:ssh_port] = locate_config_value(:winrm_port)
        end
        # unset ssh_password and set winrm_password, override ssh_password
        if locate_config_value(:ssh_password).nil? &&
            !locate_config_value(:winrm_password).nil?
          config[:ssh_password] = locate_config_value(:winrm_password)
        end
        # unset identity_file and set _file, override identity_file
        if locate_config_value(:identity_file).nil? &&
            !locate_config_value(:kerberos_keytab_file).nil?
          config[:identity_file] = locate_config_value(:kerberos_keytab_file)
        end
      end
    end
  end
end
