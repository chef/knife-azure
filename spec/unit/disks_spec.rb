require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/query_azure_mock')

describe "disks" do
  include AzureSpecHelper
  include QueryAzureMock
  before 'setup connection' do
    setup_query_azure_mock
  end

  context 'mock with actually retrieved values' do
    it "should find strings" do
      items = @connection.disks.all
      items.length.should be > 1
      items.each do |disk|
        disk.name.should_not be_nil
      end
    end
    it "should contain an attached disk" do
      items = @connection.disks.all
      count = 0;
      items.each do |item|
        if item.attached == true
          count += 1
        end
      end
      count.should == 1
    end
    it "should contain unattached disks" do
      items = @connection.disks.all
      count = 0;
      items.each do |item|
        if item.attached == false
          count += 1
        end
      end
      count.should == 7
    end
    it "should clear all unattached disks" do
      @connection.disks.clear_unattached
      @deletecount.should == 7
    end
  end
end
