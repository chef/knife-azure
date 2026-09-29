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
require "uri" unless defined?(URI)
require "json" unless defined?(JSON)
require_relative "errors"

module Azure
  class ResourceManagement
    module Rest
      # Thin Net::HTTP wrapper for talking to Azure Resource Manager. It:
      #
      #   * separates transient/transport failures (retried) from Azure API
      #     errors (surfaced immediately as OperationError), instead of the
      #     retired SDK's behaviour of retrying every failure five times;
      #   * follows nextLink paging for list operations;
      #   * polls long-running operations (LRO) to a terminal state.
      class Http
        # Simple value object for a completed HTTP response.
        Response = Struct.new(:status, :headers, :body)

        TRANSIENT_STATUS = [429, 500, 502, 503, 504].freeze
        DEFAULT_MAX_RETRIES = 3
        DEFAULT_RETRY_INTERVAL = 5 # seconds

        def initialize(token_provider, max_retries: DEFAULT_MAX_RETRIES, retry_interval: DEFAULT_RETRY_INTERVAL)
          @token_provider = token_provider
          @max_retries = max_retries
          @retry_interval = retry_interval
        end

        def get(url)
          request(:get, url)
        end

        def head(url)
          request(:head, url)
        end

        def put(url, body)
          request(:put, url, body)
        end

        def post(url, body)
          request(:post, url, body)
        end

        def delete(url)
          request(:delete, url)
        end

        # Issues a GET and follows nextLink until all pages are collected,
        # returning the concatenated "value" arrays.
        def get_all(url)
          items = []
          next_url = url
          until next_url.nil?
            response = get(next_url)
            body = response.body || {}
            items.concat(Array(body["value"]))
            next_url = body["nextLink"]
          end
          items
        end

        # Performs an LRO request (PUT/DELETE) and polls the async operation to
        # completion. Returns the final resource body (for a PUT) or nil.
        def request_and_poll(method, url, body = nil)
          response = request(method, url, body)
          poll_until_complete(response)
        end

        private

        def request(method, url, body = nil)
          attempts = 0
          begin
            do_request(method, url, body)
          rescue TransientError
            attempts += 1
            raise if attempts > @max_retries

            sleep(@retry_interval)
            retry
          end
        end

        def do_request(method, url, body)
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")

          request = build_request(method, uri, body)

          begin
            raw = http.request(request)
          rescue Timeout::Error, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED, IOError => e
            raise TransientError, "Transport error talking to Azure: #{e.message}"
          end

          handle_response(raw)
        end

        def build_request(method, uri, body)
          klass = {
            get: Net::HTTP::Get,
            head: Net::HTTP::Head,
            put: Net::HTTP::Put,
            post: Net::HTTP::Post,
            delete: Net::HTTP::Delete,
          }[method]

          path = uri.path
          path += "?#{uri.query}" if uri.query
          request = klass.new(path)
          request["Authorization"] = @token_provider.authorization_header
          request["Content-Type"] = "application/json"
          request["Accept"] = "application/json"
          unless body.nil?
            request.body = body.is_a?(String) ? body : JSON.generate(body)
          end
          request
        end

        def handle_response(raw)
          status = raw.code.to_i
          headers = normalize_headers(raw)
          parsed = parse_body(raw.body)

          if TRANSIENT_STATUS.include?(status)
            raise TransientError, "Azure returned a transient error (HTTP #{status})."
          elsif status >= 400
            raise OperationError.new(
              error_message(parsed, status),
              body: raw.body,
              code: error_code(parsed),
              http_status: status
            )
          end

          Response.new(status, headers, parsed)
        end

        def parse_body(raw_body)
          return nil if raw_body.nil? || raw_body.strip.empty?

          JSON.parse(raw_body)
        rescue JSON::ParserError
          nil
        end

        def normalize_headers(raw)
          headers = {}
          raw.each_header { |k, v| headers[k.downcase] = v }
          headers
        end

        def error_code(parsed)
          parsed && parsed["error"] && parsed["error"]["code"]
        end

        def error_message(parsed, status)
          (parsed && parsed["error"] && parsed["error"]["message"]) || "Azure API error (HTTP #{status})."
        end

        # Poll a long-running operation to a terminal state, honouring
        # Retry-After. Azure exposes two distinct monitor styles that must be
        # handled differently:
        #
        #   * Azure-AsyncOperation: a status monitor whose body carries a
        #     "status" field ("InProgress"/"Succeeded"/"Failed"/"Canceled").
        #     Terminal state comes from that field, not the HTTP code.
        #   * Location: a resource monitor that returns 202 while the operation
        #     is still running and a non-202 (200/204, often with no status
        #     body) once it has completed. Terminal success is signalled by the
        #     HTTP code, so a bodyless 200/204 here means "done", not "keep
        #     polling". Azure-AsyncOperation takes precedence when both exist.
        def poll_until_complete(response)
          async_op_url = response.headers["azure-asyncoperation"]
          location_url = response.headers["location"]
          return response.body if async_op_url.nil? && location_url.nil?

          loop do
            sleep(retry_after(response))

            if async_op_url
              response = get(async_op_url)
              state = provisioning_state(response.body)
              case state
              when "Succeeded"
                return response.body
              when "Failed", "Canceled"
                raise OperationError.new(
                  "Long-running operation ended in state '#{state}'.",
                  body: JSON.generate(response.body || {}),
                  code: state,
                  http_status: response.status
                )
              end
              async_op_url = response.headers["azure-asyncoperation"] || async_op_url
              location_url = response.headers["location"] || location_url
            else
              response = get(location_url)
              # Any non-202 response on a Location monitor is terminal success,
              # even when there is no status body.
              return response.body if response.status != 202

              location_url = response.headers["location"] || location_url
            end
          end
        end

        def provisioning_state(body)
          return nil unless body.is_a?(Hash)

          body["status"] || (body["properties"] && body["properties"]["provisioningState"])
        end

        def retry_after(response)
          value = response.headers && response.headers["retry-after"]
          value.nil? ? @retry_interval : value.to_i
        end
      end
    end
  end
end
