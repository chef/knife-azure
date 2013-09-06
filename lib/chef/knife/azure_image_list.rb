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

require 'highline'
require File.expand_path('../azure_base', __FILE__)

class Chef
  class Knife
    class AzureImageList < Knife

      include Knife::AzureBase

      banner "knife azure image list (options)"

      option :show_all_fields,
        :long => "--full",
        :default => false,
        :boolean => true,
        :description => "Show all the fields of the images"

      def h
        @highline ||= HighLine.new
      end

      def run
        $stdout.sync = true

        validate!

        image_labels = !locate_config_value(:show_all_fields) ? ['Name', 'OS'] : ['Name', 'Category', 'Label', 'OS'] 
        image_list =  image_labels.map {|label| ui.color(label, :bold)}
        begin
          items = connection.images.all
        rescue ConnectionExceptions::QueryAzureException => e
          ui.error e.message
          exit 1
        end

        image_items = image_labels.map {|item| item.downcase }
        items.each do |image|
         image_items.each {|item| image_list << image.send(item).to_s }
        end

        puts "\n"
        puts h.list(image_list, :uneven_columns_across, !locate_config_value(:show_all_fields) ? 2 : 4) 

      end
    end
  end
end
