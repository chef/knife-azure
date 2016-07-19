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

# github key setup
deploy_key = get_project_secrets['github']

build_user_home = '/var/opt/delivery/workspace'

directory "#{build_user_home}/.ssh" do
  owner node['delivery_builder']['build_user']
  group 'root'
  mode '0700'
end

execute "ssh-keyscan -t rsa github.com >> #{build_user_home}/.ssh/known_hosts" do
  not_if "grep -q github.com '#{build_user_home}/.ssh/known_hosts'"
end

deploy_key_path = ::File.join(build_user_home, '.ssh', 'chef-delivery.pem')

file deploy_key_path do
  content deploy_key
  owner node['delivery_builder']['build_user']
  group 'root'
  mode '0600'
  sensitive true
end

file "#{build_user_home}/.ssh/config" do
  content <<-EOH.gsub(/^ {4}/, '')
    Host github.com
      IdentityFile #{deploy_key_path}
      StrictHostKeyChecking no
  EOH
  owner node['delivery_builder']['build_user']
  group 'root'
  mode '0600'
end

# cleanup the cache directory, otherwise provision will fail
directory "#{node['delivery']['workspace']['cache']}/.delivery/cache/generator-cookbooks/pcb" do
  recursive true
  action :delete
end
