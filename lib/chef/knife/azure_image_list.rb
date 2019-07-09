#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Author:: Adam Jacob (<adam@chef.io>)
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

require File.expand_path("../azure_base", __FILE__)

class Chef
  class Knife
    class AzureImageList < Knife

      include Knife::AzureBase

      banner "knife azure image list (options)"

      option :show_all_fields,
        long: "--full",
        default: false,
        boolean: true,
        description: "Show all the fields of the images"

      def run
        $stdout.sync = true

        validate_asm_keys!
        items = service.list_images

        image_labels = !locate_config_value(:show_all_fields) ? %w{Name OS Location} : %w{Name Category Label OS Location}
        image_list =  image_labels.map { |label| ui.color(label, :bold) }

        image_items = image_labels.map(&:downcase)
        items.each do |image|
          image_items.each { |item| image_list << image.send(item).to_s }
        end

        puts "\n"
        puts ui.list(image_list, :uneven_columns_across, !locate_config_value(:show_all_fields) ? 3 : 5)
      end
    end
  end
end
