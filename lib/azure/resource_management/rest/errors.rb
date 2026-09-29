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
      # Raised for network/transport failures and throttling (HTTP 429/5xx).
      # These are considered retryable by the HTTP layer. When Azure supplies a
      # Retry-After hint, it is carried here so the caller can honour it.
      class TransientError < StandardError
        attr_reader :retry_after

        def initialize(message = nil, retry_after: nil)
          @retry_after = retry_after
          super(message)
        end
      end

      # Raised when Azure Resource Manager returns an API error (HTTP 4xx, or a
      # failed long-running operation). This is the direct replacement for the
      # retired SDK's MsRestAzure2::AzureOperationError and preserves the same
      # accessors that consuming code relied on: #body returns the raw response
      # body string, and #response.body returns the same string.
      class OperationError < StandardError
        # Minimal stand-in for the SDK response object; only #body is consumed.
        ResponseBody = Struct.new(:body)

        attr_reader :body, :code, :http_status

        def initialize(message, body: nil, code: nil, http_status: nil)
          @body = body
          @code = code
          @http_status = http_status
          super(message)
        end

        def response
          ResponseBody.new(@body)
        end
      end
    end
  end
end
