require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe Chef::Knife::AzureImageList do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    @server_instance = Chef::Knife::AzureImageList.new
    {
      :azure_subscription_id => 'azure_subscription_id',
      :azure_mgmt_cert => @cert_file,
      :azure_api_host_name => 'preview.core.windows-int.net',
      :azure_service_location => 'West Europe',
      :azure_source_image => 'SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd',
      :azure_dns_name => 'service001',
      :azure_vm_name => 'vm01',
      :azure_storage_account => 'ka001testeurope',
      :azure_vm_size => 'Small'
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    stub_query_azure (@server_instance.connection)
    allow(@server_instance).to receive(:items).and_return(:true)
    allow(@server_instance).to receive(:puts)
  end

  it 'should display only Name OS and Location columns.' do
    expect(@server_instance.h).to receive(:list)
      .with(['Name', 'OS', 'Location', 'CANONICAL__Canonical-Ubuntu-12-04-20120519-2012-05-19-en-us-30GB.vhd',
             'Linux', 'East Asia', 'MSFT__Windows-Server-2008-R2-SP1.11-29-2011', 'Windows',
             'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'MSFT__Windows-Server-2008-R2-SP1-with-SQL-Server-2012-Eval.11-29-2011',
             'Windows', 'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'MSFT__Windows-Server-8-Beta.en-us.30GB.2012-03-22',
             'Windows', 'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'MSFT__Windows-Server-8-Beta.2-17-2012', 'Windows',
             'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'MSFT__Windows-Server-2008-R2-SP1.en-us.30GB.2012-3-22', 'Windows',
             'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'OpenLogic__OpenLogic-CentOS-62-20120509-en-us-30GB.vhd', 'Linux',
             'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd', 'Linux',
             'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'SUSE__OpenSUSE64121-03192012-en-us-15GB.vhd', 'Linux',
             'East Asia, West US'], :uneven_columns_across, 3)
    @server_instance.run
  end

  it 'should display Name, Category, Label and OS columns when show_all_fields set to true.' do
    Chef::Config[:knife][:show_all_fields] = true
    expect(@server_instance.h).to receive(:list)
      .with(['Name', 'Category', 'Label', 'OS', 'Location',
             'CANONICAL__Canonical-Ubuntu-12-04-20120519-2012-05-19-en-us-30GB.vhd', 'Canonical',
             'Ubuntu Server 12.04 20120519', 'Linux', 'East Asia', 'MSFT__Windows-Server-2008-R2-SP1.11-29-2011',
             'Microsoft', 'Windows Server 2008 R2 SP1, Nov 2011',
             'Windows', 'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'MSFT__Windows-Server-2008-R2-SP1-with-SQL-Server-2012-Eval.11-29-2011', 'Microsoft',
             'SQL Server 2012 Evaluation, Nov 2011', 'Windows',
             'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'MSFT__Windows-Server-8-Beta.en-us.30GB.2012-03-22', 'Microsoft', 'Windows Server 8 Beta, Mar 2012',
             'Windows', 'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'MSFT__Windows-Server-8-Beta.2-17-2012', 'Microsoft', 'Windows Server 8 Beta, Feb 2012',
             'Windows', 'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'MSFT__Windows-Server-2008-R2-SP1.en-us.30GB.2012-3-22', 'Microsoft',
             'Windows Server 2008 R2 SP1, Mar 2012', 'Windows',
             'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'OpenLogic__OpenLogic-CentOS-62-20120509-en-us-30GB.vhd', 'OpenLogic', 'CentOS 6.2 provided by OpenLogic', 'Linux',
             'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd', 'SUSE', 'SUSE Linux Enterprise Server', 'Linux',
             'East Asia, Southeast Asia, North Europe, West Europe, East US, West US',
             'SUSE__OpenSUSE64121-03192012-en-us-15GB.vhd', 'SUSE', 'OpenSUSE64-12.1-Beta', 'Linux',
             'East Asia, West US'], :uneven_columns_across, 5)
    @server_instance.run
  end

  it 'returns OSImage list.' do
    osimages = @server_instance.connection.images.get_images('OSImage')
    expect(osimages).not_to be_empty
    expect(osimages.values).to be_kind_of(Array)
  end

  it 'returns empty VMImage list.' do
    expect(@server_instance.connection.images.get_images('VMImage')).to be_empty
  end

  it 'checks if the image is OSImage or VMImage' do
    expect(@server_instance.connection.images.os_image?('CANONICAL__Canonical-Ubuntu-12-04-20120519-2012-05-19-en-us-30GB.vhd')).to be true
    expect(@server_instance.connection.images.vm_image?('CANONICAL__Canonical-Ubuntu-12-04-20120519-2012-05-19-en-us-30GB.vhd')).to be false
  end
end
