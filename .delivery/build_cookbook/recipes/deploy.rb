#
# Cookbook Name:: build_cookbook
# Recipe:: deploy
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

gem_build_path = "#{node['delivery']['workspace']['repo']}".gsub("acceptance/deploy", "build/publish")

cookbook_file '/tmp/azure-credentials.publishsettings' do
  source 'azure-credentials.publishsettings'
  mode '0777'
  action :create
end

template "/tmp/knife.rb" do
  source "knife.erb"
  mode '0777'
end

template '/tmp/client.pem' do
  source "client.erb"
  mode '0777'
end

execute "gem_install_knife_azure" do
  cwd "#{gem_build_path}"
  command "gem install knife-azure-*.gem "
  notifies :run, 'execute[knife_azure_server_create]', :immediately
end

execute "knife_azure_server_create" do
  cwd "#{node['delivery']['workspace']['repo']}"
  command "knife azure server create --azure-vm-name #{node['delivery']['azure']['linux_vmname']} --node-name #{node['delivery']['azure']['linux_vmname']} --azure-source-image 0b11de9248dd4d87b18621318e037d37__RightImage-Ubuntu-14.04-x64-v14.1.5.1 --bootstrap-protocol cloud-api --azure-service-location 'West US' --ssh-user azure --ssh-password azure@123 --azure-publish-settings-file /tmp/azure-credentials.publishsettings -c /tmp/knife.rb -VV"
  action :nothing
  notifies :run, 'execute[knife_azure_server_delete]', :immediately
end

execute "knife_azure_server_delete" do
  cwd "#{node['delivery']['workspace']['repo']}"
  command "knife azure server delete #{node['delivery']['azure']['linux_vmname']} --node-name #{node['delivery']['azure']['linux_vmname']} --azure-publish-settings-file /tmp/azure-credentials.publishsettings --purge -c /tmp/knife.rb -y -VV"
  action :nothing
  notifies :run, 'execute[knife_azurerm_server_create]', :immediately
end

execute "knife_azurerm_server_create" do
  cwd "#{node['delivery']['workspace']['repo']}"
  command "knife azurerm server create --azure-resource-group-name build-test-grp --azure-vm-name #{node['delivery']['azurerm']['linux_vmname']} --node-name #{node['delivery']['azurerm']['linux_vmname']} --azure-service-location westus --azure-image-os-type ubuntu -x azure -P azure@123 -c /tmp/knife.rb -VV"
  action :nothing
  notifies :run, 'execute[knife_azurerm_server_delete]', :immediately
end

execute "knife_azurerm_server_delete" do
  cwd "#{node['delivery']['workspace']['repo']}"
  command "knife azurerm server delete #{node['delivery']['azurerm']['linux_vmname']} --azure-resource-group-name build-test-grp --node-name #{node['delivery']['azurerm']['linux_vmname']} --purge -y -c /tmp/knife.rb -VV"
  action :nothing
  notifies :run, 'execute[knife_azure_server_create_windows]', :immediately
end

execute "knife_azure_server_create_windows" do
  cwd "#{node['delivery']['workspace']['repo']}"
  command "knife azure server create --azure-vm-name #{node['delivery']['azure']['windows_vmname']} --node-name #{node['delivery']['azure']['windows_vmname']} --azure-source-image bd507d3a70934695bc2128e3e5a255ba__RightImage-Windows-2012R2-x64-v14.2 --bootstrap-protocol cloud-api --azure-service-location 'West US' -x azure -P azure@123 --azure-publish-settings-file /tmp/azure-credentials.publishsettings -c /tmp/knife.rb -VV"
  action :nothing
  notifies :run, 'execute[knife_azure_server_delete_windows]', :immediately
end

execute "knife_azure_server_delete_windows" do
  cwd "#{node['delivery']['workspace']['repo']}"
  command "knife azure server delete #{node['delivery']['azure']['windows_vmname']} --node-name #{node['delivery']['azure']['windows_vmname']} --azure-publish-settings-file /tmp/azure-credentials.publishsettings --purge -c /tmp/knife.rb -y -VV"
  action :nothing
  notifies :run, 'execute[knife_azurerm_server_create_windows]', :immediately
end

execute "knife_azurerm_server_create_windows" do
  cwd "#{node['delivery']['workspace']['repo']}"
  command "knife azurerm server create --azure-resource-group-name build-test-grp --azure-vm-name #{node['delivery']['azurerm']['windows_vmname']} --node-name #{node['delivery']['azurerm']['windows_vmname']} --azure-service-location westus --azure-image-os-type windows --azure-image-reference-offer WindowsServer --azure-image-reference-publisher MicrosoftWindowsServer --azure-image-reference-sku 2012-R2-Datacenter -x azure -P azure@123 -c /tmp/knife.rb -VV"
  action :nothing
  notifies :run, 'execute[knife_azurerm_server_delete_windows]', :immediately
end

execute "knife_azurerm_server_delete_windows" do
  cwd "#{node['delivery']['workspace']['repo']}"
  command "knife azurerm server delete #{node['delivery']['azurerm']['windows_vmname']} --azure-resource-group-name build-test-grp --node-name #{node['delivery']['azurerm']['windows_vmname']} --purge -y -c /tmp/knife.rb -VV"
  action :nothing
end
