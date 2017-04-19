#
# Cookbook Name:: build_cookbook
# Recipe:: publish
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

execute 'gem build knife-azure.gemspec' do
  cwd "#{node['delivery']['workspace']['repo']}"
  command "gem build knife-azure.gemspec -V"
end
