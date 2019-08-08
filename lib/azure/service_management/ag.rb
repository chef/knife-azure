#
# Author:: Jeff Mendoza (jeffmendoza@live.com)
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
  class AGs
    def initialize(connection)
      @connection = connection
    end

    def load
      @ags ||= begin
        @ags = {}
        response = @connection.query_azure("affinitygroups",
          "get",
          "",
          "",
          true,
          false)
        response.css("AffinityGroup").each do |ag|
          item = AG.new(@connection).parse(ag)
          @ags[item.name] = item
        end
        @ags
      end
    end

    def all
      load.values
    end

    def exists?(name)
      load.key?(name)
    end

    def find(name)
      load[name]
    end

    def create(params)
      ag = AG.new(@connection)
      ag.create(params)
    end
  end
end

module Azure
  class AG
    attr_accessor :name, :label, :description, :location

    def initialize(connection)
      @connection = connection
    end

    def parse(image)
      @name = image.at_css("Name").content
      @label = image.at_css("Label").content
      @description = image.at_css("Description").content if
        image.at_css("Description")
      @location = image.at_css("Location").content if image.at_css("Location")
      self
    end

    def create(params)
      builder = Nokogiri::XML::Builder.new(encoding: "utf-8") do |xml|
        xml.CreateAffinityGroup(
          xmlns: "http://schemas.microsoft.com/windowsazure"
        ) do
          xml.Name params[:azure_ag_name]
          xml.Label Base64.strict_encode64(params[:azure_ag_name])
          unless params[:azure_ag_desc].nil?
            xml.Description params[:azure_ag_desc]
          end
          xml.Location params[:azure_location]
        end
      end
      @connection.query_azure("affinitygroups",
        "post",
        builder.to_xml,
        "",
        true,
        false)
    end
  end
end
