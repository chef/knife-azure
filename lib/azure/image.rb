#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
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

class Azure
  class Images
    def initialize(connection)
      @connection=connection
    end
    def all
      images = Array.new
      response = @connection.query_azure('images')
      osimages = response.css('OSImage')
      osimages.each do |image|
        item = Image.new(image)
        images << item
      end
      images
    end
    def exists(name)
      imageExists = false
      self.all.each do |host|
        next unless host.name == name
        imageExists = true
      end
      imageExists
    end
  end
end

class Azure
  class Image
    attr_accessor :category, :label
    attr_accessor :name, :os, :eula, :description
    def initialize(image)
      @category = image.at_css('Category').content
      @label = image.at_css('Label').content
      @name = image.at_css('Name').content
      @os = image.at_css('OS').content
      @eula = image.at_css('Eula').content if image.at_css('Eula')
      @description = image.at_css('Description').content if image.at_css('Description')
    end
  end
end
