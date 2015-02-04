require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')

describe 'hosts' do
  include AzureSpecHelper
  include QueryAzureMock
  before 'setup connection' do
    setup_query_azure_mock
  end

  context 'get all hosts' do
    specify { expect(@connection.hosts.all.length).to be > 1 }
    it 'entry fields should not be nil' do
      items = @connection.hosts.all
      items.each do |host|
        expect(host.name).to_not be nil
        expect(host.url).to_not be nil
        expect(host.label).to_not be nil
        expect(host.date_created).to_not be nil
        expect(host.description).to_not be nil
        expect(host.location).to_not be nil
        expect(host.date_modified).to_not be nil
        expect(host.status).to_not be nil
      end
    end
    specify { expect(@connection.hosts.exists?('notExpectedName')).to be == false }
    specify { expect(@connection.hosts.exists?('service001')).to be == true }
  end

  context 'create a new host with service location' do
    it 'using explicit parameters it should pass in expected body' do
      params = { :azure_dns_name => 'service003', :azure_service_location => 'West US', 'hosted_azure_service_location' => 'Windows Azure Preview' }
      host = @connection.hosts.create(params)
      expect(@postname).to be == 'hostedservices'
      expect(@postverb).to be == 'post'
      expect(@postbody).to eq(readFile('create_host_location.xml'))
    end
    it 'using default parameters it should pass in expected body' do
      params = { :azure_dns_name => 'service003', :azure_service_location => 'West US' }
      host = @connection.hosts.create(params)
      expect(@postname).to be == 'hostedservices'
      expect(@postverb).to be == 'post'
      expect(@postbody).to eq(readFile('create_host_location.xml'))
    end
  end
  context 'create a new host with affinity group' do
    it 'using explicit parameters it should pass in expected body' do
      params = { :azure_dns_name => 'service003', :azure_affinity_group => 'test-affinity' }
      host = @connection.hosts.create(params)
      expect(@postname).to be == 'hostedservices'
      expect(@postverb).to be == 'post'
      expect(@postbody).to eq(readFile('create_host_affinity.xml'))
    end
  end
  context 'delete a host' do
    it 'should pass in correct name, verb, and body' do
      @connection.hosts.delete('service001')
      expect(@deletename).to be == 'hostedservices/service001'
      expect(@deleteverb).to be == 'delete'
      expect(@deletebody).to be nil
    end
  end
end
