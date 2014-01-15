#
# Author:: Mukta Aphale (mukta.aphale@clogeny.com)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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

require 'highline'
require File.expand_path('../azure_base', __FILE__)

class Chef
  class Knife
    class AzureCertificateAdd < Knife

      include Knife::AzureBase

      banner "knife azure certificate add (options)"

      option :cert_password,
        :long => "--cert-password PASSWORD",
        :description => "Certificate Password"

      option :cert_path,
      :long => "--cert-path PATH",
      :description => "Certificate Path"

      option :cloud_service,
        :long => "--cloud-service DNS-NAME",
        :description => "Name of cloud service/DNS name"

      def h
        @highline ||= HighLine.new
      end

      def run
        $stdout.sync = true

        validate!
        cert_data = File.read (config[:cert_path])

        connection.certificates.add cert_data, config[:cert_password], 'pfx', config[:cloud_service]
      end
    end
  end
end
