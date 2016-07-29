#
# Cookbook Name:: build-cookbook
# Recipe:: default
#
# Copyright 2015 Chef Software, Inc.
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

execute 'bundle install' do
  cwd "#{node['delivery']['workspace']['repo']}"
  command 'bundle install --path .bundle'
  notifies :run, 'execute[unit_test]', :immediately
end

execute 'unit_test' do
  cwd "#{node['delivery']['workspace']['repo']}"
  command 'bundle exec rspec spec/unit'
  action :nothing
end