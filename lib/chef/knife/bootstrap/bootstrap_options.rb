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

class Chef
  class Knife
  	class Bootstrap
  	  module BootstrapOptions

  	  	def self.included(includer)
  	  	  includer.class_eval do

  	  	  	include Knife::WinrmBase

  	  	  	deps do
              require 'chef/knife/bootstrap'
              Chef::Knife::Bootstrap.load_deps
            end

  	  	  	option :forward_agent,
              :short => "-A",
              :long => "--forward-agent",
              :description =>  "Enable SSH agent forwarding",
              :boolean => true

            option :chef_node_name,
              :short => "-N NAME",
              :long => "--node-name NAME",
              :description => "The Chef node name for your new node"

            option :prerelease,
              :long => "--prerelease",
              :description => "Install the pre-release chef gems"

            option :bootstrap_version,
              :long => "--bootstrap-version VERSION",
              :description => "The version of Chef to install",
              :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

            option :distro,
              :short => "-d DISTRO",
              :long => "--distro DISTRO",
              :description => "Bootstrap a distro using a template. [DEPRECATED] Use --bootstrap-template option instead.",
              :proc        => Proc.new { |v|
                  Chef::Log.warn("[DEPRECATED] -d / --distro option is deprecated. Use --bootstrap-template option instead.")
                  v
                }

            option :template_file,
              :long => "--template-file TEMPLATE",
              :description => "Full path to location of template to use. [DEPRECATED] Use -t / --bootstrap-template option instead.",
              :proc        => Proc.new { |v|
                  Chef::Log.warn("[DEPRECATED] --template-file option is deprecated. Use -t / --bootstrap-template option instead.")
                  v
                }

            option :bootstrap_template,
              :long => "--bootstrap-template TEMPLATE",
              :description => "Bootstrap Chef using a built-in or custom template. Set to the full path of an erb template or use one of the built-in templates."

            option :run_list,
              :short => "-r RUN_LIST",
              :long => "--run-list RUN_LIST",
              :description => "Comma separated list of roles/recipes to apply",
              :proc => lambda { |o| o.split(/[\s,]+/) },
              :default => []

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

            option :bootstrap_proxy,
              :long => "--bootstrap-proxy PROXY_URL",
              :description => "The proxy server for the node being bootstrapped",
              :proc => Proc.new { |p| Chef::Config[:knife][:bootstrap_proxy] = p }

            option :bootstrap_no_proxy,
              :long => "--bootstrap-no-proxy [NO_PROXY_URL|NO_PROXY_IP]",
              :description => "Do not proxy locations for the node being bootstrapped; this option is used internally by Opscode",
              :proc => Proc.new { |np| Chef::Config[:knife][:bootstrap_no_proxy] = np }

            option :bootstrap_url,
              :long        => "--bootstrap-url URL",
              :description => "URL to a custom installation script",
              :proc        => Proc.new { |u| Chef::Config[:knife][:bootstrap_url] = u }

            option :bootstrap_install_command,
              :long        => "--bootstrap-install-command COMMANDS",
              :description => "Custom command to install chef-client",
              :proc        => Proc.new { |ic| Chef::Config[:knife][:bootstrap_install_command] = ic }

            option :bootstrap_wget_options,
              :long        => "--bootstrap-wget-options OPTIONS",
              :description => "Add options to wget when installing chef-client",
              :proc        => Proc.new { |wo| Chef::Config[:knife][:bootstrap_wget_options] = wo }

            option :bootstrap_curl_options,
              :long        => "--bootstrap-curl-options OPTIONS",
              :description => "Add options to curl when install chef-client",
              :proc        => Proc.new { |co| Chef::Config[:knife][:bootstrap_curl_options] = co }

            option :bootstrap_vault_file,
              :long        => '--bootstrap-vault-file VAULT_FILE',
              :description => 'A JSON file with a list of vault(s) and item(s) to be updated'

            option :bootstrap_vault_json,
              :long        => '--bootstrap-vault-json VAULT_JSON',
              :description => 'A JSON string with the vault(s) and item(s) to be updated'

            option :bootstrap_vault_item,
              :long        => '--bootstrap-vault-item VAULT_ITEM',
              :description => 'A single vault and item to update as "vault:item"',
              :proc        => Proc.new { |i|
                  (vault, item) = i.split(/:/)
                  Chef::Config[:knife][:bootstrap_vault_item] ||= {}
                  Chef::Config[:knife][:bootstrap_vault_item][vault] ||= []
                  Chef::Config[:knife][:bootstrap_vault_item][vault].push(item)
                  Chef::Config[:knife][:bootstrap_vault_item]
                }

            option :use_sudo_password,
              :long => "--use-sudo-password",
              :description => "Execute the bootstrap via sudo with password",
              :boolean => false

            option :hint,
              :long => "--hint HINT_NAME[=HINT_FILE]",
              :description => "Specify Ohai Hint to be set on the bootstrap target.  Use multiple --hint options to specify multiple hints.",
              :proc => Proc.new { |h|
                  Chef::Config[:knife][:hints] ||= {}
                  name, path = h.split("=")
                  Chef::Config[:knife][:hints][name] = path ? JSON.parse(::File.read(path)) : Hash.new
                }
                
  	  	  end
  	  	end
  	  end
  	end
  end
end

