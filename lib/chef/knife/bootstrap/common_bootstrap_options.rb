#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
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

class Chef
  class Knife
    class Bootstrap
      module CommonBootstrapOptions

        def self.included(includer)
          includer.class_eval do

            deps do
              require "chef/knife/bootstrap"
              Chef::Knife::Bootstrap.load_deps
            end

            option :azure_availability_set,
              long: "--azure-availability-set NAME",
              description: "Optional. Name of availability set to add virtual machine into."

            option :azure_extension_client_config,
              long: "--azure-extension-client-config CLIENT_PATH",
              description: "Optional. Path to a client.rb file for use by the bootstrapped node."

            option :azure_os_disk_name,
              short: "-o DISKNAME",
              long: "--azure-os-disk-name DISKNAME",
              description: "Optional. Specifies the friendly name of the disk containing the guest OS image in the image repository."

            option :azure_service_location,
              short: "-m LOCATION",
              long: "--azure-service-location LOCATION",
              description: "Required if not using an Affinity Group. Specifies the geographic location - the name of the data center location that is valid for your subscription.
                            Eg: West US, East US, East Asia, Southeast Asia, North Europe, West Europe",
              proc: Proc.new { |lo| Chef::Config[:knife][:azure_service_location] = lo }

            option :azure_storage_account,
              short: "-a NAME",
              long: "--azure-storage-account NAME",
              description: "Required for advanced server-create option.
                            A name for the storage account that is unique within Windows Azure. Storage account names must be
                            between 3 and 24 characters in length and use numbers and lower-case letters only.
                            This name is the DNS prefix name and can be used to access blobs, queues, and tables in the storage account.
                            For example: http://ServiceName.blob.core.windows.net/mycontainer/"

            option :azure_vm_name,
              long: "--azure-vm-name NAME",
              description: "Required. Specifies the name for the virtual machine.
                            The name must be unique within the ResourceGroup.
                            The azure vm name cannot be more than 15 characters long"

            option :azure_vm_size,
              short: "-z SIZE",
              long: "--azure-vm-size SIZE",
              description: "Optional. Size of virtual machine. Default is Standard_A1_v2.
                            Eg: Standard_A1_v2, Standard_F2, Standard_G1 etc.",
              default: "Standard_A1_v2",
              proc: Proc.new { |si| Chef::Config[:knife][:azure_vm_size] = si }

            deprecated_option :bootstrap_protocol,
              replacement: :connection_protocol,
              long: "--bootstrap-protocol PROTOCOL"

            option :cert_passphrase,
              long: "--cert-passphrase PASSWORD",
              description: "SSL Certificate Password"

            option :cert_path,
              long: "--cert-path PATH",
              description: "SSL Certificate Path"

            option :chef_daemon_interval,
              long: "--chef-daemon-interval INTERVAL",
              description: "Optional. Provide this option when --connection-protocol is set to 'cloud-api'.
                            It specifies the frequency (in minutes) at which the chef-service runs.
                            Pass 0 if you don't want the chef-service to be installed on the target machine."

            option :daemon,
              long: "--daemon DAEMON",
              description: "Optional. Configures the chef-client service for unattended execution. Requires --connection-protocol to be 'cloud-api' and the node platform to be Windows.
                            Options: 'none' or 'service' or 'task'.
                            none - Currently prevents the chef-client service from being configured as a service.
                            service - Configures the chef-client to run automatically in the background as a service.
                            task - Configures the chef-client to run automatically in the background as a scheduled task."

            option :extended_logs,
              long: "--extended-logs",
              boolean: true,
              default: false,
              description: "Optional. Provide this option when --connection-protocol is set to 'cloud-api'. It shows chef converge logs in detail."

            option :tcp_endpoints,
              short: "-t PORT_LIST",
              long: "--tcp-endpoints PORT_LIST",
              description: "Comma-separated list of TCP local and public ports to open e.g. '80:80,433:5000'"

            option :thumbprint,
              long: "--thumbprint THUMBPRINT",
              description: "The thumprint of the ssl certificate"
          end
        end
      end
    end
  end
end
