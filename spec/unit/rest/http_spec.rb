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
require_relative "../../../lib/azure/resource_management/rest/http"

describe Azure::ResourceManagement::Rest::Http do
  let(:token_provider) { double("TokenProvider", authorization_header: "Bearer x") }
  let(:http) { described_class.new(token_provider, retry_interval: 0) }

  before do
    allow(http).to receive(:sleep)
  end

  def response(status, headers = {}, body = nil)
    Azure::ResourceManagement::Rest::Http::Response.new(status, headers, body)
  end

  describe "#request_and_poll" do
    context "with a Location monitor that completes with a bodyless non-202" do
      it "treats the non-202 as terminal success instead of polling forever" do
        allow(http).to receive(:do_request).and_return(
          response(202, { "location" => "https://monitor/loc" }, nil),
          response(202, { "location" => "https://monitor/loc" }, nil),
          response(200, {}, { "id" => "done" })
        )

        expect(http.request_and_poll(:delete, "https://x")).to eq("id" => "done")
      end

      it "handles a 204 with no body as completion" do
        allow(http).to receive(:do_request).and_return(
          response(202, { "location" => "https://monitor/loc" }, nil),
          response(204, {}, nil)
        )

        expect(http.request_and_poll(:delete, "https://x")).to be_nil
      end
    end

    context "with an Azure-AsyncOperation status monitor" do
      it "polls the status document until it reports Succeeded" do
        allow(http).to receive(:do_request).and_return(
          response(201, { "azure-asyncoperation" => "https://monitor/op" }, nil),
          response(200, {}, { "status" => "InProgress" }),
          response(200, {}, { "status" => "Succeeded" })
        )

        expect(http.request_and_poll(:put, "https://x", {})).to eq("status" => "Succeeded")
      end

      it "raises an OperationError when the operation ends in Failed" do
        allow(http).to receive(:do_request).and_return(
          response(201, { "azure-asyncoperation" => "https://monitor/op" }, nil),
          response(200, {}, { "status" => "Failed" })
        )

        expect { http.request_and_poll(:put, "https://x", {}) }.to raise_error(
          Azure::ResourceManagement::Rest::OperationError, /ended in state 'Failed'/
        )
      end

      it "prefers the status monitor when both headers are present" do
        allow(http).to receive(:do_request).and_return(
          response(201, { "azure-asyncoperation" => "https://monitor/op", "location" => "https://monitor/loc" }, nil),
          response(200, {}, { "status" => "Succeeded" })
        )

        expect(http.request_and_poll(:put, "https://x", {})).to eq("status" => "Succeeded")
      end
    end

    context "when the operation completes synchronously (no monitor headers)" do
      it "returns the response body immediately without polling" do
        expect(http).to receive(:do_request).once.and_return(response(200, {}, { "id" => "sync" }))

        expect(http.request_and_poll(:delete, "https://x")).to eq("id" => "sync")
      end
    end

    context "when the operation never reaches a terminal state" do
      it "gives up after the poll limit instead of looping forever" do
        capped = described_class.new(token_provider, retry_interval: 0, max_polls: 2)
        allow(capped).to receive(:sleep)
        allow(capped).to receive(:do_request).and_return(
          response(202, { "location" => "https://monitor/loc" }, nil),
          response(202, { "location" => "https://monitor/loc" }, nil),
          response(202, { "location" => "https://monitor/loc" }, nil)
        )

        expect { capped.request_and_poll(:delete, "https://x") }.to raise_error(
          Azure::ResourceManagement::Rest::OperationError, /Timed out/
        )
      end
    end
  end

  describe "#get_all" do
    it "follows nextLink across multiple pages and concatenates the results" do
      allow(http).to receive(:do_request).and_return(
        response(200, {}, { "value" => [{ "id" => 1 }, { "id" => 2 }], "nextLink" => "https://page2" }),
        response(200, {}, { "value" => [{ "id" => 3 }], "nextLink" => "https://page3" }),
        response(200, {}, { "value" => [{ "id" => 4 }] })
      )

      expect(http.get_all("https://page1").map { |h| h["id"] }).to eq([1, 2, 3, 4])
    end
  end

  describe "#request retry behaviour" do
    it "honours the Retry-After delay carried on a throttled response" do
      calls = 0
      allow(http).to receive(:do_request) do
        calls += 1
        if calls == 1
          raise Azure::ResourceManagement::Rest::TransientError.new("429", retry_after: 7)
        end

        response(200, {}, { "ok" => true })
      end

      expect(http).to receive(:sleep).with(7)
      expect(http.get("https://x").body).to eq("ok" => true)
    end

    it "falls back to the default retry interval when no Retry-After is given" do
      calls = 0
      throttler = described_class.new(token_provider, retry_interval: 3)
      allow(throttler).to receive(:do_request) do
        calls += 1
        raise Azure::ResourceManagement::Rest::TransientError.new("503") if calls == 1

        response(200, {}, {})
      end

      expect(throttler).to receive(:sleep).with(3)
      throttler.get("https://x")
    end
  end
end
