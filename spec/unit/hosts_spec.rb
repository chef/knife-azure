require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')

describe "hosts" do
  include AzureSpecHelper
  include QueryAzureMock
  before 'setup connection' do
    setup_query_azure_mock
  end

  context 'get all hosts' do
    specify {@connection.hosts.all.length.should be > 1}
    it "entry fields should not be nil" do
      items = @connection.hosts.all
      items.each do |host|
        host.name.should_not be_nil
        host.url.should_not be_nil
        host.label.should_not be_nil
        host.dateCreated.should_not be_nil
        host.description.should_not be_nil
        host.location.should_not be_nil
        host.dateModified.should_not be_nil
        host.status.should_not be_nil
      end
    end
    specify {@connection.hosts.exists?("notExpectedName").should == false}
    specify {@connection.hosts.exists?("service001").should == true}
  end

  context 'create a new host with service location' do
    it 'using explicit parameters it should pass in expected body' do
      params = {:azure_dns_name=>'service003', :azure_service_location=>'West US', 'hosted_azure_service_location'=>'Windows Azure Preview'}
      host = @connection.hosts.create(params)
      @postname.should == 'hostedservices'
      @postverb.should == 'post'
      Nokogiri::XML(@postbody).should be_equivalent_to(Nokogiri::XML readFile('create_host_location.xml'))
    end
    it 'using default parameters it should pass in expected body' do
      params = {:azure_dns_name=>'service003', :azure_service_location=>'West US'}
      host = @connection.hosts.create(params)
      @postname.should == 'hostedservices'
      @postverb.should == 'post'
      Nokogiri::XML(@postbody).should be_equivalent_to(Nokogiri::XML readFile('create_host_location.xml'))
    end
  end
  context 'create a new host with affinity group' do
    it 'using explicit parameters it should pass in expected body' do
      params = {:azure_dns_name=>'service003', :azure_affinity_group=>'test-affinity' }
      host = @connection.hosts.create(params)
      @postname.should == 'hostedservices'
      @postverb.should == 'post'
      Nokogiri::XML(@postbody).should be_equivalent_to(Nokogiri::XML readFile('create_host_affinity.xml'))
    end
  end
  context 'delete a host' do
    it 'should pass in correct name, verb, and body' do
      @connection.hosts.delete('service001');
      @deletename.should == 'hostedservices/service001'
      @deleteverb.should == 'delete'
      @deletebody.should == nil
    end
  end
end

