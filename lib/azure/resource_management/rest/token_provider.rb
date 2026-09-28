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
require_relative "environments"
require_relative "errors"

module Azure
  class ResourceManagement
    module Rest
      # Provides a bearer token for ARM requests. It supports the same two
      # inputs the caller already produces (see azurerm_base.rb):
      #
      #   * service principal: {azure_tenant_id, azure_client_id,
      #     azure_client_secret} -> client-credentials grant, cached until it
      #     is close to expiry;
      #   * pre-fetched token (the `az login` path): {token, tokentype} -> used
      #     as-is.
      class TokenProvider
        # Refresh a client-credentials token this many seconds before expiry.
        EXPIRY_SKEW = 120

        def initialize(params = {}, environment = Environments.default)
          @params = params
          @environment = environment
        end

        def authorization_header
          "#{token_type} #{access_token}"
        end

        def token_type
          @params[:tokentype] || "Bearer"
        end

        def access_token
          if @params[:azure_client_secret]
            client_credentials_token
          else
            @params[:token]
          end
        end

        private

        def client_credentials_token
          if @cached_token && @expires_at && Time.now.utc < (@expires_at - EXPIRY_SKEW)
            return @cached_token
          end

          response = request_client_credentials_token
          @cached_token = response["access_token"]
          @expires_at = Time.now.utc + response["expires_in"].to_i
          @cached_token
        end

        def request_client_credentials_token
          uri = URI.parse("#{@environment.active_directory_endpoint_url}/#{@params[:azure_tenant_id]}/oauth2/token")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")

          request = Net::HTTP::Post.new(uri.request_uri)
          request.set_form_data(
            "grant_type" => "client_credentials",
            "client_id" => @params[:azure_client_id],
            "client_secret" => @params[:azure_client_secret],
            "resource" => @environment.token_audience
          )

          raw = http.request(request)
          if raw.code.to_i >= 400
            raise OperationError.new(
              "Failed to acquire an Azure access token (HTTP #{raw.code}).",
              body: raw.body,
              http_status: raw.code.to_i
            )
          end

          JSON.parse(raw.body)
        end
      end
    end
  end
end
