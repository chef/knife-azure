#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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

require File.expand_path('../azure_base', __FILE__)

class Chef
  class Knife
    class AzureImageList < Knife

      include Knife::AzureBase

      banner "knife azure image list (options)"

      def run
        $stdout.sync = true

        validate!

        image_list = [
          ui.color('Name', :bold),
          #ui.color('Category', :bold),
          #ui.color('Label', :bold),
          #ui.color('OS', :bold),
          #ui.color('Eula', :bold),
        ]
        items = connection.images.all
        items.each do |image|
          if image.os == 'Linux'
            image_list << image.name.to_s
            #image_list << image.category.to_s
            #image_list << image.label.to_s
            #image_list << image.os.to_s
            #image_list << image.eula.to_s
          end
        end
        puts ''
        puts ui.list(image_list, :columns_across, 1)
      end
    end
  end
end
