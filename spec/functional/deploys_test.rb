#
# Copyright:: Copyright 2010-2019, Chef Software Inc.
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

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "deploys" do
  before(:all) do
    @connection = Azure::Connection.new(TEST_PARAMS)
    @deploys = @connection.deploys.all
  end

  specify { @deploys.length.should be > 0 }
  it "each deployment should have values" do
    @deploys.each do |deploy|
      deploy.name.should_not be_nil
      deploy.status.should_not be_nil
      deploy.url.should_not be_nil
      deploy.roles.length.should be > 0
    end
  end
  it "each role should have values" do
    @deploys.each do |deploy|
      Chef::Log.info "============================="
      Chef::Log.info "hosted service: " + deploy.hostedservicename + "  deployment: " + deploy.name
      deploy.roles.each do |role|
        role.name.should_not be_nil
        role.status.should_not be_nil
        role.size.should_not be_nil
        role.ipaddress.should_not be_nil
        role.sshport.should_not be_nil
        Chef::Log.info "============================="
        Chef::Log.info "role: " + role.name
        Chef::Log.info "status: " + role.status
        Chef::Log.info "size: " + role.size
        Chef::Log.info "ip address: " + role.ipaddress
        Chef::Log.info "ssh port: " + role.sshport
      end
    end
  end
end
