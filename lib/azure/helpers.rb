#
# Author:: vasundhara.jagdale@clogeny.com
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

module Azure
  module Helpers

    def random_string(len=10)
      (0...len).map{65.+(rand(25)).chr}.join
    end

    def strip_non_ascii(string)
      string.gsub(/[^0-9a-z ]/i, '')
    end

    def display_list(ui=nil, columns=[], rows=[])
      columns = columns.map{ |col| ui.color(col, :bold) }
      count = columns.count
      rows = columns.concat(rows)
      puts ''
      puts ui.list(rows, :uneven_columns_across, count)
    end

    def msg_pair(ui=nil, label=nil, value=nil, color=:cyan)
      if value && !value.to_s.empty?
        puts "#{ui.color(label, color)}: #{value}"
      end
    end
  end
end