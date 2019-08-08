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

module Azure
  class Images
    def initialize(connection)
      @connection = connection
    end

    def load
      @images ||= begin
        osimages = get_images("OSImage")   # get OSImages
        vmimages = get_images("VMImage")   # get VMImages

        all_images = osimages.merge(vmimages)
      end
    end

    def all
      load.values
    end

    # img_type = OSImages or VMImage
    def get_images(img_type)
      images = {}

      if img_type == "OSImage"
        response = @connection.query_azure("images")
      elsif img_type == "VMImage"
        response = @connection.query_azure("vmimages")
      end

      unless response.to_s.empty?
        osimages = response.css(img_type)

        osimages.each do |image|
          item = Image.new(image)
          images[item.name] = item
        end
      end

      images
    end

    def is_os_image(image_name)
      os_images = get_images("OSImage").values
      os_images.detect { |img| img.name == image_name } ? true : false
    end

    def is_vm_image(image_name)
      vm_images = get_images("VMImage").values
      vm_images.detect { |img| img.name == image_name } ? true : false
    end

    def exists?(name)
      all.detect { |img| img.name == name } ? true : false
    end

    def find(name)
      load[name]
    end
  end
end

module Azure
  class Image
    attr_accessor :category, :label
    attr_accessor :name, :os, :eula, :description, :location
    def initialize(image)
      @category = image.at_css("Category").content
      @label = image.at_css("Label").content
      @name = image.at_css("Name").content
      @os = image.at_css("OS").content
      @location = image.at_css("Location").content.gsub(";", ", ") if image.at_css("Location")
      @eula = image.at_css("Eula").content if image.at_css("Eula")
      @description = image.at_css("Description").content if image.at_css("Description")
    end
  end
end
