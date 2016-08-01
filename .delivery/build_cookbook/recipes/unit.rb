#
# Cookbook Name:: build_cookbook
# Recipe:: unit
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

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