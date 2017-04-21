#
# Author:: Aliasgar Batterywala (aliasgar.batterywala@clogeny.com)
# Copyright:: Copyright (c) 2015-2016 Opscode, Inc.
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

module Azure::ARM
    module ARMBase

      def get_vm_size(size_name)
        size_hash = { "ExtraSmall" => "Standard_A0", "Small" => "Standard_A1",
                      "Medium" => "Standard_A2", "Large" => "Standard_A3",
                      "ExtraLarge" => "Standard_A4" }
        size_hash[size_name].nil? ? size_name : size_hash[size_name]
      end
    end
end
