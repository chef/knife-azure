#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
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

module AzureUtility
  def xml_content(xml, key, default = "")
    content = default
    node = xml.at_css(key)
    if node
      content = node.content
    end
    content
  end

  def error_from_response_xml(response_xml)
    error_code_and_message = ["", ""]
    error_node = response_xml.at_css("Error")

    if error_node
      error_code_and_message[0] = xml_content(error_node, "Code")
      error_code_and_message[1] = xml_content(error_node, "Message")
    end

    error_code_and_message
  end
end
