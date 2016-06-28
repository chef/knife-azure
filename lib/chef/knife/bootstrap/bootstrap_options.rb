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

            option :extended_logs,
              :long => "--extended-logs",
              :boolean => true,
              :default => false,
              :description => "Optional. Provide this option when --bootstrap-protocol is set to 'cloud-api'. It shows chef converge logs in detail."

  	  	  end
  	  	end
  	  end
  	end
  end
end

