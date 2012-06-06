require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')

describe "images" do
  include AzureSpecHelper
  include QueryAzureMock
  before 'setup connection' do
    setup_query_azure_mock
  end

  context 'mock with actually retrieved values' do
    it "should find strings" do
      items = @connection.images.all
      items.length.should be > 1
      items.each do |image|
        image.category.should_not be_nil
        image.label.should_not be_nil
        image.name.should_not be_nil
        image.os.should_not be_nil
        image.eula.should_not be_nil
        image.description.should_not be_nil
      end
    end
    it "should contain a linux image" do
      items = @connection.images.all
      foundLinux = false
      items.each do |item|
        if item.os == 'Linux'
          foundLinux = true 
        end
      end
      foundLinux.should == true
    end
  end
end
