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
require_relative "../../../lib/azure/resource_management/rest/secure_connection"

describe Azure::ResourceManagement::Rest::SecureConnection do
  it "enables TLS with peer verification and a CA store for https URIs" do
    http = described_class.build(URI.parse("https://management.azure.com"))

    expect(http.use_ssl?).to be true
    expect(http.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
    expect(http.cert_store).to be_a(OpenSSL::X509::Store)
  end

  it "does not enable TLS for plain http URIs" do
    http = described_class.build(URI.parse("http://localhost:8080"))

    expect(http.use_ssl?).to be false
  end

  it "applies bounded connection and read timeouts by default" do
    http = described_class.build(URI.parse("https://management.azure.com"))

    expect(http.open_timeout).to eq(described_class::DEFAULT_OPEN_TIMEOUT)
    expect(http.read_timeout).to eq(described_class::DEFAULT_READ_TIMEOUT)
  end

  it "lets callers override the timeouts" do
    http = described_class.build(URI.parse("https://management.azure.com"), open_timeout: 5, read_timeout: 9)

    expect(http.open_timeout).to eq(5)
    expect(http.read_timeout).to eq(9)
  end
end
