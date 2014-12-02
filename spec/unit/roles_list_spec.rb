require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')
describe 'roles' do
  include AzureSpecHelper
  include QueryAzureMock
  before do
    setup_query_azure_mock
  end

  it 'show all roles' do
    roles = @connection.roles.all
    roles.each do |role|
      expect(role.name).to_not be nil
    end
    expect(roles.length).to be == 7
  end
  specify { expect(@connection.roles.exists?('vm01')).to be true }
  specify { expect(@connection.roles.exists?('vm002')).to be true }
  specify { expect(@connection.roles.exists?('role001')).to be true }
  specify { expect(@connection.roles.exists?('role002')).to be true }
  specify { expect(@connection.roles.exists?('role002qqqqq')).to be false }

  it 'each role should have values' do
    role = @connection.roles.find('vm01')
    expect(role.name).to_not be nil
    expect(role.status).to_not be nil
    expect(role.size).to_not be nil
    expect(role.ipaddress).to_not be nil
    expect(role.sshport).to_not be nil
    expect(role.publicipaddress).to_not be nil
  end
end
