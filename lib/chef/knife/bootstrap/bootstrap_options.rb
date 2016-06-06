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

require 'chef/knife/winrm_base'
require 'chef/knife/bootstrap_windows_base'
class Chef
  class Knife
    class Bootstrap
      module BootstrapOptions

        def self.included(includer)
          includer.class_eval do

            include Knife::WinrmBase
            include Knife::BootstrapWindowsBase
            deps do
              require 'chef/knife/bootstrap'
              Chef::Knife::Bootstrap.load_deps
            end

            option :forward_agent,
              :short => "-A",
              :long => "--forward-agent",
              :description =>  "Enable SSH agent forwarding",
              :boolean => true

            option :json_attributes,
              :short => "-j JSON",
              :long => "--json-attributes JSON",
              :description => "A JSON string to be added to the first run of chef-client",
              :proc => lambda { |o| JSON.parse(o) }

            option :host_key_verify,
              :long => "--[no-]host-key-verify",
              :description => "Verify host key, enabled by default.",
              :boolean => true,
              :default => true

            option :bootstrap_url,
              :long        => "--bootstrap-url URL",
              :description => "URL to a custom installation script",
              :proc        => Proc.new { |u| Chef::Config[:knife][:bootstrap_url] = u }

            option :bootstrap_wget_options,
              :long        => "--bootstrap-wget-options OPTIONS",
              :description => "Add options to wget when installing chef-client",
              :proc        => Proc.new { |wo| Chef::Config[:knife][:bootstrap_wget_options] = wo }

            option :bootstrap_curl_options,
              :long        => "--bootstrap-curl-options OPTIONS",
              :description => "Add options to curl when install chef-client",
              :proc        => Proc.new { |co| Chef::Config[:knife][:bootstrap_curl_options] = co }

            option :use_sudo_password,
              :long => "--use-sudo-password",
              :description => "Execute the bootstrap via sudo with password",
              :boolean => false

            option :auto_update_client,
              :long => "--auto-update-client",
              :boolean => true,
              :default => false,
              :description => "Set this flag to enable auto chef client update in azure chef extension. This flag should be used with cloud-api bootstrap protocol only"

            option :delete_chef_extension_config,
              :long => "--delete-chef-extension-config",
              :boolean => true,
              :default => false,
              :description => "Determines whether Chef configuration files removed when Azure removes the Chef resource extension from the VM. This option is only valid for the 'cloud-api' bootstrap protocol. The default is false."

            option :uninstall_chef_client,
              :long => "--uninstall-chef-client",
              :boolean => true,
              :default => false,
              :description => "Determines whether Chef Client will be un-installed from the VM or not. This option is only valid for the 'cloud-api' bootstrap protocol. The default value is false."

            option :extended_logs,
              :long => "--extended-logs",
              :boolean => true,
              :default => false,
              :description => "Optional. Provide this option when --bootstrap-protocol is set to 'cloud-api'. It shows chef converge logs in detail."

            option :environment_variables,
              :long => "--environment-variables VARIABLES_LIST",
              :description => "Optional. Comma separated list of key-value pairs to be available as environment_variables to the Chef Extension scripts on the target node. e.g. 'var1:value1,var2:value2,var3:value3'"

  	  	  end
  	  	end
  	  end
  	end
  end
end

