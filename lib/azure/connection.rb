#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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
require File.expand_path('../utility', __FILE__)
require File.expand_path('../rest', __FILE__)
require File.expand_path('../host', __FILE__)
require File.expand_path('../storageaccount', __FILE__)
require File.expand_path('../deploy', __FILE__)
require File.expand_path('../role', __FILE__)
require File.expand_path('../disk', __FILE__)
require File.expand_path('../image', __FILE__)
require File.expand_path('../certificate', __FILE__)

class ConnectionExceptions
  class QueryAzureException < RuntimeError; end
end
class Azure
  class Connection
    include AzureAPI
    attr_accessor :hosts, :rest, :images, :deploys, :roles, :disks, :storageaccounts, :certificates
    def initialize(params={})
      @rest = Rest.new(params)
      @hosts = Hosts.new(self)
      @storageaccounts = StorageAccounts.new(self)
      @images = Images.new(self)
      @deploys = Deploys.new(self)
      @roles = Roles.new(self)
      @disks = Disks.new(self)
      @certificates = Certificates.new(self)
    end
    def query_azure(service_name, verb = 'get', body = '')
      Chef::Log.info 'calling ' + verb + ' ' + service_name
      Chef::Log.debug body unless body == ''
      response = @rest.query_azure(service_name, verb, body)
      if response.code.to_i == 200
        ret_val = Nokogiri::XML response.body
      elsif response.code.to_i >= 201 && response.code.to_i <= 299
        ret_val = wait_for_completion()
      else
        if response.body
          ret_val = Nokogiri::XML response.body
          e = ret_val.at_css('Error Code').content + ' : ' + ret_val.at_css('Error Message').content
          Chef::Log.warn e
          raise ConnectionExceptions::QueryAzureException, e
        else
          Chef::Log.warn 'http error: ' + response.code
        end
      end
      ret_val
    end
    def wait_for_completion()
      status = 'InProgress'
      Chef::Log.info 'Waiting while status returns InProgress'
      while status == 'InProgress'
        response = @rest.query_for_completion()       
        ret_val = Nokogiri::XML response.body
        status = ret_val.at_css('Status').content
        if status == 'InProgress'
          print '.'
          sleep(0.5)
        elsif status == 'Succeeded'
          Chef::Log.debug 'not InProgress : ' + ret_val.to_xml
        else
          Chef::Log.warn status + ret_val.at_css('Error Code').content + ' : ' + ret_val.at_css('Error Message').content
        end
      end
      ret_val
    end
  end
end
