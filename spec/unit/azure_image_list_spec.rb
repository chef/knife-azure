require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../unit/query_azure_mock')

describe "knife azure " do
  include AzureSpecHelper
  include QueryAzureMock
  before 'setup connection' do
    setup_query_azure_mock
  end

  context 'image list' do

  before(:each) do
    @server_instance = Chef::Knife::AzureImageList.new
      {
        :azure_subscription_id => 'azure_subscription_id',
        :azure_mgmt_cert => 'AzureLinuxCert.pem',
        :azure_host_name => 'preview.core.windows-int.net',
        :role_name => 'vm01',
        :service_location => 'service_location',
        :source_image => 'source_image',
        :role_size => 'role_size',
        :hosted_service_name => 'service001',
        :storage_account => 'ka001testeurope'
        }.each do |key, value|
      Chef::Config[:knife][key] = value
    end
    stub_query_azure (@server_instance.connection)
    @server_instance.stub(:items).and_return(:true)
  end
    
    it "should display only Name and OS columns." do
      @server_instance.h.should_receive(:list).with(["Name", "OS", "CANONICAL__Canonical-Ubuntu-12-04-20120519-2012-05-19-en-us-30GB.vhd", "Linux", "MSFT__Windows-Server-2008-R2-SP1.11-29-2011", "Windows", "MSFT__Windows-Server-2008-R2-SP1-with-SQL-Server-2012-Eval.11-29-2011", "Windows", "MSFT__Windows-Server-8-Beta.en-us.30GB.2012-03-22", "Windows", "MSFT__Windows-Server-8-Beta.2-17-2012", "Windows", "MSFT__Windows-Server-2008-R2-SP1.en-us.30GB.2012-3-22", "Windows", "OpenLogic__OpenLogic-CentOS-62-20120509-en-us-30GB.vhd", "Linux", "SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd", "Linux", "SUSE__OpenSUSE64121-03192012-en-us-15GB.vhd", "Linux"], :uneven_columns_across, 2)
      @server_instance.run
    end

    it "--full should display Name , Category, Label and OS columns." do
      Chef::Config[:knife][:show_all_fields] = true
      @server_instance.h.should_receive(:list).with(["Name", "Category", "Label", "OS", "CANONICAL__Canonical-Ubuntu-12-04-20120519-2012-05-19-en-us-30GB.vhd", "Canonical", "Ubuntu Server 12.04 20120519", "Linux", "MSFT__Windows-Server-2008-R2-SP1.11-29-2011", "Microsoft", "Windows Server 2008 R2 SP1, Nov 2011", "Windows", "MSFT__Windows-Server-2008-R2-SP1-with-SQL-Server-2012-Eval.11-29-2011", "Microsoft", "SQL Server 2012 Evaluation, Nov 2011", "Windows", "MSFT__Windows-Server-8-Beta.en-us.30GB.2012-03-22", "Microsoft", "Windows Server 8 Beta, Mar 2012", "Windows", "MSFT__Windows-Server-8-Beta.2-17-2012", "Microsoft", "Windows Server 8 Beta, Feb 2012", "Windows", "MSFT__Windows-Server-2008-R2-SP1.en-us.30GB.2012-3-22", "Microsoft", "Windows Server 2008 R2 SP1, Mar 2012", "Windows", "OpenLogic__OpenLogic-CentOS-62-20120509-en-us-30GB.vhd", "OpenLogic", "CentOS 6.2 provided by OpenLogic", "Linux", "SUSE__SUSE-Linux-Enterprise-Server-11SP2-20120521-en-us-30GB.vhd", "SUSE", "SUSE Linux Enterprise Server", "Linux", "SUSE__OpenSUSE64121-03192012-en-us-15GB.vhd", "SUSE", "OpenSUSE64-12.1-Beta", "Linux"], :uneven_columns_across, 4)
      @server_instance.run
    end
  end
end