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

require "net/http" unless defined?(Net::HTTP)
require "openssl" unless defined?(OpenSSL)

module Azure
  class ResourceManagement
    module Rest
      # Builds Net::HTTP connections with TLS certificate verification always
      # enabled for HTTPS, so bearer tokens and client secrets are never sent
      # over a channel where a forged/man-in-the-middle certificate could be
      # accepted. All outbound connections in this layer go through here.
      module SecureConnection
        module_function

        # Bounded, overridable defaults. Net::HTTP defaults both timeouts to
        # unlimited, so without these a stalled Azure or token endpoint could
        # block the CLI forever (and the HTTP layer's LRO deadline can't help
        # while http.request itself is blocked).
        DEFAULT_OPEN_TIMEOUT = 60  # seconds to establish the connection
        DEFAULT_READ_TIMEOUT = 120 # seconds to wait for each response

        def build(uri, open_timeout: DEFAULT_OPEN_TIMEOUT, read_timeout: DEFAULT_READ_TIMEOUT)
          http = Net::HTTP.new(uri.host, uri.port)
          http.open_timeout = open_timeout
          http.read_timeout = read_timeout
          if uri.scheme == "https"
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
            http.cert_store = default_cert_store
          end
          http
        end

        # System CA trust store, loaded once and reused.
        def default_cert_store
          @default_cert_store ||= OpenSSL::X509::Store.new.tap(&:set_default_paths)
        end
      end
    end
  end
end
