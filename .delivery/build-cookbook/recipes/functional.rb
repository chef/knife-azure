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
#

cache = node['delivery']['workspace']['cache']
target_cookbook_name = 'maelstrom'
path = "#{node['delivery']['workspace']['repo']}/#{target_cookbook_name}"
github_repo = node['delivery']['config']['delivery-truck']['publish']['github']

execute "chef generate cookbook #{target_cookbook_name}" do
  cwd node['delivery']['workspace']['repo']
end

# we're not doing `delivery init`, so we need to make the directory
directory File.join(path, '.delivery')

execute 'git add and commit' do
  cwd path
  command <<-EOF.gsub(/^\s*/, '')
    git add .
    git commit -m 'a swirling vortex of terror'
  EOF
end

directory "#{cache}/.delivery/cache/generator-cookbooks/pcb" do
  recursive true
end

git "#{cache}/.delivery/cache/generator-cookbooks/pcb" do
  repository "git@github.com:#{github_repo}.git"
  revision 'master'
  action :checkout
end

execute 'generate build-cookbook' do
  command "chef generate cookbook .delivery/build-cookbook -g #{cache}/.delivery/cache/generator-cookbooks/pcb"
  cwd path
end

build_cookbook_path = File.expand_path(File.join(node['delivery']['workspace']['repo'],
                                                 'maelstrom', '.delivery', 'build-cookbook'))

# Enable audit mode, because it'll be disabled by default. This will
# fail if the chef client is below 12.1.0, but we're fine here because
# our delivery builders have ChefDK.
Chef::Config[:audit_mode] = :enabled

control_group 'Verify Build Cookbook' do
  control 'It wraps delivery-truck' do
    it 'has delivery-truck in the berksfile' do
      expect(file("#{build_cookbook_path}/Berksfile").content).to match(/cookbook 'delivery-truck'/)
    end

    it 'has delivery-sugar in the berksfile' do
      expect(file("#{build_cookbook_path}/Berksfile").content).to match(/cookbook 'delivery-sugar'/)
    end

    it 'depends on delivery-truck' do
      expect(file("#{build_cookbook_path}/metadata.rb").content).to match(/depends 'delivery-truck'/)
    end

    # .each an array
    %w(default deploy functional lint provision publish quality security smoke syntax unit).each do |phase|
      it "includes the delivery-truck recipe in #{phase}" do
        expect(file("#{build_cookbook_path}/recipes/#{phase}.rb").content).to match(
          /include_recipe 'delivery-truck::#{phase}'/
        )
      end
    end
  end
end
