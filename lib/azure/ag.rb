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

class Azure
  class AGs
    def initialize(connection)
      @connection = connection
    end

    def load
      @ags ||= begin
        @ags = {}
        response = @connection.query_azure('ags')
        response.css('AffinityGroup').each do |ag|
          item = AG.new(ag)
          @ags[item.name] = item
        end
        @ags
      end
    end

    def all
      load.values
    end

    def exists?(name)
      all.key?(name)
    end

    def find(name)
      load[name]
    end
  end
end

class Azure
  class AG
    attr_accessor :name, :label, :description, :location
    def initialize(image)
      @name = image.at_css('Name').content
      @label = image.at_css('Label').content
      @description = image.at_css('Description').content if
        image.at_css('Description')
      @location = image.at_css('Location').content if image.at_css('Location')
    end
  end
end
