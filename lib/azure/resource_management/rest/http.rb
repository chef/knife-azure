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
require "time" unless defined?(Time.httpdate)
require_relative "errors"
require_relative "secure_connection"

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
        # Hard caps so a stuck long-running operation cannot poll forever.
        DEFAULT_LRO_TIMEOUT = 30 * 60 # seconds
        DEFAULT_MAX_POLLS = 360

        def initialize(token_provider, max_retries: DEFAULT_MAX_RETRIES, retry_interval: DEFAULT_RETRY_INTERVAL,
                       lro_timeout: DEFAULT_LRO_TIMEOUT, max_polls: DEFAULT_MAX_POLLS,
                       open_timeout: SecureConnection::DEFAULT_OPEN_TIMEOUT,
                       read_timeout: SecureConnection::DEFAULT_READ_TIMEOUT)
          @token_provider = token_provider
          @max_retries = max_retries
          @retry_interval = retry_interval
          @lro_timeout = lro_timeout
          @max_polls = max_polls
          @open_timeout = open_timeout
          @read_timeout = read_timeout
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

        # Issues a GET and returns the full list of items. Handles both ARM
        # list shapes: most endpoints return a paged { "value": [...],
        # "nextLink": ... } envelope, but a few (e.g. VM extension image
        # versions) return a bare JSON array. nextLink is followed for the
        # paged shape.
        def get_all(url)
          items = []
          next_url = url
          until next_url.nil?
            body = get(next_url).body
            if body.is_a?(Array)
              items.concat(body)
              next_url = nil
            else
              body ||= {}
              items.concat(Array(body["value"]))
              next_url = body["nextLink"]
            end
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
          rescue TransientError => e
            attempts += 1
            raise if attempts > @max_retries

            # Honour the server's Retry-After hint (throttling) when present.
            sleep(e.retry_after || @retry_interval)
            retry
          end
        end

        def do_request(method, url, body)
          uri = URI.parse(url)
          http = SecureConnection.build(uri, open_timeout: @open_timeout, read_timeout: @read_timeout)

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
            raise TransientError.new(
              "Azure returned a transient error (HTTP #{status}).",
              retry_after: parse_retry_after(headers["retry-after"])
            )
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

        # Azure Resource Manager errors are nested ({ "error": { "code",
        # "message" } }); the AAD/OAuth token endpoint returns a flat shape
        # ({ "error": "invalid_client", "error_description": "..." }). Both are
        # handled here so a meaningful message/code is surfaced either way.
        def error_code(parsed)
          return nil unless parsed.is_a?(Hash)

          err = parsed["error"]
          err.is_a?(Hash) ? err["code"] : err
        end

        def error_message(parsed, status)
          fallback = "Azure API error (HTTP #{status})."
          return fallback unless parsed.is_a?(Hash)

          err = parsed["error"]
          if err.is_a?(Hash)
            err["message"] || fallback
          elsif err.is_a?(String)
            parsed["error_description"] ? "#{err}: #{parsed["error_description"]}" : err
          else
            fallback
          end
        end

        # Parse a Retry-After header value (delta-seconds or an HTTP-date) into
        # a number of seconds, or nil when absent/unparseable.
        def parse_retry_after(value)
          return nil if value.nil? || value.to_s.strip.empty?

          return value.to_i if value.to_s =~ /\A\d+\z/

          begin
            seconds = (Time.httpdate(value) - Time.now).round
            seconds > 0 ? seconds : 0
          rescue ArgumentError
            nil
          end
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

          deadline = Time.now + @lro_timeout
          polls = 0
          loop do
            polls += 1
            if polls > @max_polls || Time.now >= deadline
              raise OperationError.new(
                "Timed out waiting for the long-running operation to complete " \
                  "(after #{polls - 1} polls / #{@lro_timeout}s).",
                body: JSON.generate(response.body || {}),
                code: "PollingTimeout",
                http_status: response.status
              )
            end

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
          parse_retry_after(response.headers && response.headers["retry-after"]) || @retry_interval
        end
      end
    end
  end
end
