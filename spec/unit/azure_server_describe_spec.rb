require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureAgList do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    @server_instance = Chef::Knife::AzureServerDescribe.new
      {
        :azure_subscription_id => 'azure_subscription_id',
        :azure_mgmt_cert => @cert_file,
        :azure_api_host_name => 'preview.core.windows-int.net',
        }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    stub_query_azure(@server_instance.connection)

    @server_instance.stub(:puts)
  end

  it 'should display server information.' do
    @server_instance.name_args = %w(role206 role001 role002 vm002 vm01 ssh-vm
                                    winrm-vm vmname)
    @server_instance.ui.should_receive(:list).with(
      ['Role name', 'role001',
       'Status', 'ReadyRole',
       'Size', 'Small',
       'Hosted service name', 'service001',
       'Deployment name', 'deployment001',
       'Host name', 'role001',
       'SSH port', '22',
       'Public IP', '65.52.249.191'],
      :columns_across,
      2
    )
    @server_instance.ui.should_receive(:list).with(
      ['Role name', 'role002',
       'Status', 'RoleStateUnknown',
       'Size', 'Small',
       'Hosted service name', 'service001',
       'Deployment name', 'deployment001',
       'Host name', 'role002',
       'SSH port', '23',
       'Public IP', '65.52.249.191'],
      :columns_across,
      2
    )
    @server_instance.ui.should_receive(:list).with(
      ['Role name', 'vm002',
       'Status', 'ReadyRole',
       'Size', 'ExtraSmall',
       'Hosted service name', 'service001',
       'Deployment name', 'deployment001',
       'Host name', 'myVm2',
       'SSH port', '22',
       'Public IP', '65.52.251.57'],
      :columns_across,
      2
    )
    @server_instance.ui.should_receive(:list).with(
      ['Ports open', 'Local port', 'IP', 'Public port',
       'tcp', '66', '65.52.251.57', '66'],
      :columns_across,
      4
    ).exactly(3).times
    @server_instance.ui.should_receive(:list).with(
      ['Role name', 'vm01',
       'Status', 'ReadyRole',
       'Size', 'ExtraSmall',
       'Hosted service name', 'service002',
       'Deployment name', 'testrequest',
       'Host name', 'myVm',
       'SSH port', '54047',
       'Public IP', '65.52.251.144'],
      :columns_across,
      2
    )
    @server_instance.ui.should_receive(:list).with(
      ['Role name', 'ssh-vm',
       'Status', 'ReadyRole',
       'Size', 'ExtraSmall',
       'Hosted service name', 'service004',
       'Deployment name', 'deployment004',
       'Host name', 'ssh-vm',
       'SSH port', '22',
       'Public IP', '65.52.251.57'],
      :columns_across,
      2
    )
    @server_instance.ui.should_receive(:list).with(
      ['Role name', 'winrm-vm',
       'Status', 'ReadyRole',
       'Size', 'Small',
       'Hosted service name', 'service004',
       'Deployment name', 'deployment004',
       'Host name', 'winrm-vm',
       'WinRM port', '5985',
       'Public IP', '65.52.249.191'],
      :columns_across,
      2
    )
    @server_instance.ui.should_receive(:list).with(
      ['Role name', 'vmname',
       'Status', 'ReadyRole',
       'Size', 'ExtraSmall',
       'Hosted service name', 'vmname',
       'Deployment name', 'deployment001',
       'Host name', 'myVm2',
       'SSH port', '22',
       'Public IP', '65.52.251.57'],
      :columns_across,
      2
    )
    @server_instance.run
  end

end
