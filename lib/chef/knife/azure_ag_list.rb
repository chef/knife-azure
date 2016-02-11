#
# Author:: Jeff Mendoza (jeffmendoza@live.com)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
    class AzureAgList < Knife
      include Knife::AzureBase

      deps { require 'highline' }

      banner 'knife azure ag list (options)'

      def hl
        @highline ||= HighLine.new
      end

      def run
        $stdout.sync = true

        validate!

        cols = %w{Name Location Description}

        the_list = cols.map { |col| ui.color(col, :bold) }

        ags = service.list_ags

        ags.each do |ag|
          cols.each { |attr| the_list << ag.send(attr.downcase).to_s }
        end

        puts "\n"
        puts hl.list(the_list, :uneven_columns_across, cols.size)
      end
    end
  end
end
