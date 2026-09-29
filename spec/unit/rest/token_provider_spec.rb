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

require_relative "../../spec_helper"
require_relative "../../../lib/azure/resource_management/rest/token_provider"

describe Azure::ResourceManagement::Rest::TokenProvider do
  describe "pre-fetched token (az login path)" do
    let(:provider) { described_class.new(token: "abc123", tokentype: "Bearer") }

    it "returns the supplied token as-is" do
      expect(provider.access_token).to eq("abc123")
    end

    it "builds the Authorization header from the token type and token" do
      expect(provider.authorization_header).to eq("Bearer abc123")
    end

    it "defaults the token type to Bearer when none is supplied" do
      expect(described_class.new(token: "t").token_type).to eq("Bearer")
    end
  end

  describe "service principal (client-credentials grant)" do
    let(:params) do
      { azure_tenant_id: "tenant", azure_client_id: "client", azure_client_secret: "secret" }
    end
    let(:provider) { described_class.new(params) }

    it "requests a token once and serves subsequent calls from cache" do
      expect(provider).to receive(:request_client_credentials_token).once.and_return(
        "access_token" => "tok", "expires_in" => 3600
      )

      expect(provider.access_token).to eq("tok")
      expect(provider.access_token).to eq("tok")
    end

    it "re-requests once the cached token is near expiry" do
      allow(provider).to receive(:request_client_credentials_token).and_return(
        { "access_token" => "first", "expires_in" => 0 },
        { "access_token" => "second", "expires_in" => 3600 }
      )

      expect(provider.access_token).to eq("first")
      expect(provider.access_token).to eq("second")
    end

    context "over HTTP" do
      let(:net_http) { double("Net::HTTP") }

      before do
        allow(Net::HTTP).to receive(:new).and_return(net_http)
        allow(net_http).to receive(:use_ssl=)
      end

      it "returns the access token on a successful response" do
        raw = double(code: "200", body: '{"access_token":"live-token","expires_in":3599}')
        allow(net_http).to receive(:request).and_return(raw)

        expect(provider.access_token).to eq("live-token")
        expect(provider.authorization_header).to eq("Bearer live-token")
      end

      it "surfaces the OAuth error_description on a failed response" do
        raw = double(code: "401", body: '{"error":"invalid_client","error_description":"bad secret"}')
        allow(net_http).to receive(:request).and_return(raw)

        expect { provider.access_token }.to raise_error(
          Azure::ResourceManagement::Rest::OperationError, /bad secret/
        )
      end
    end
  end
end
