require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')

describe 'images' do
  include AzureSpecHelper
  include QueryAzureMock
  before 'setup connection' do
    setup_query_azure_mock
  end

  context 'mock with actually retrieved values' do
    it 'should find strings' do
      items = @connection.images.all
      expect(items.length).to be > 1
      items.each do |image|
        expect(image.category).to_not be nil
        expect(image.label).to_not be nil
        expect(image.name).to_not be nil
        expect(image.os).to_not be nil
        expect(image.eula).to_not be nil
        expect(image.description).to_not be nil
      end
    end
    it 'should contain a linux image' do
      items = @connection.images.all
      foundLinux = false
      items.each do |item|
        if item.os == 'Linux'
          foundLinux = true
        end
      end
      expect(foundLinux).to be true
    end
  end
end
