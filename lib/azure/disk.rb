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
  class Disks
    def initialize(connection)
      @connection=connection
    end
    def all
      disks = Array.new
      response = @connection.query_azure('disks')
      founddisks = response.css('Disk')
      founddisks.each do |disk|
        item = Disk.new(disk)
        disks << item
      end
      disks
    end
    def find(name)
      founddisk = nil
      self.all.each do |disk|
        next unless disk.name == name
        founddisk = disk
      end
      founddisk
    end
    def exists(name)
      find(name) != nil
    end
    def clear_unattached
      self.all.each do |disk|
        next unless disk.attached == false
        @connection.query_azure('disks/' + disk.name, 'delete')
      end
    end
  end
end

class Azure
  class Disk
    attr_accessor :name, :attached
    def initialize(disk)
      @name = disk.at_css('Name').content
      @attached = disk.at_css('AttachedTo') != nil
    end
  end
end
