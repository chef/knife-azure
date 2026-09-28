#
# Copyright:: Copyright (c) 2012-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
  class ResourceManagement
    module Rest
      # Wraps a parsed ARM JSON response (a Hash) so existing consumers can keep
      # using SDK-style dot notation. The retired Azure SDK exposed models with
      # snake_case accessors and flattened the ARM "properties" envelope; this
      # wrapper reproduces both behaviours:
      #
      #   * Key matching ignores case and underscores, so camelCase ARM keys
      #     line up with the snake_case names the code already uses
      #     (e.g. "osType" <-> os_type, "publicIPAddress" <-> public_ipaddress).
      #   * When a name is not found at the top level, the nested "properties"
      #     object is searched too, mirroring the SDK's flattened models
      #     (e.g. vm.provisioning_state, vm.storage_profile).
      class RestObject
        def initialize(data)
          @data = data || {}
        end

        # Wraps a raw value (Hash, Array or scalar) into RestObjects as needed.
        def self.wrap(value)
          case value
          when RestObject
            value
          when Hash
            new(value)
          when Array
            value.map { |v| wrap(v) }
          else
            value
          end
        end

        def to_h
          @data
        end
        alias_method :to_hash, :to_h

        def [](key)
          RestObject.wrap(@data[key])
        end

        def key?(name)
          !lookup_key(name).nil?
        end

        def nil?
          @data.nil? || @data.empty?
        end

        def respond_to_missing?(_name, _include_private = false)
          true
        end

        def method_missing(name, *args)
          key = lookup_key(name)
          return RestObject.wrap(@data[key]) unless key.nil?

          properties = @data["properties"]
          if properties.is_a?(Hash)
            pkey = lookup_key(name, properties)
            return RestObject.wrap(properties[pkey]) unless pkey.nil?
          end

          nil
        end

        private

        def lookup_key(name, hash = @data)
          return nil unless hash.is_a?(Hash)

          target = normalize(name)
          hash.keys.find { |k| normalize(k) == target }
        end

        def normalize(str)
          str.to_s.delete("_").downcase
        end
      end
    end
  end
end
