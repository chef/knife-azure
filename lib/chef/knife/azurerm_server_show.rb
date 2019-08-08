#
# Author:: Meera Navale (meera.navale@msystechnologies.com)
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

require File.expand_path("../azurerm_base", __FILE__)

class Chef
  class Knife
    class AzurermServerShow < Knife

      include Knife::AzurermBase

      banner "knife azurerm server show SERVER (options)"

      def run
        $stdout.sync = true
        # check azure cli version due to azure changed `azure` to `az` in azure-cli2.0
        get_azure_cli_version
        validate_arm_keys!(:azure_resource_group_name)
        begin
          service.show_server(@name_args[0], locate_config_value(:azure_resource_group_name))
        rescue => error
          service.common_arm_rescue_block(error)
        end
      end

    end
  end
end
