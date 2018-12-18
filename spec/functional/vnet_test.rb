require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "vnets" do
  before(:all) do
    @connection = Azure::Connection.new(TEST_PARAMS)
    @connection.ags.create(azure_ag_name: "func-test-agforvnet",
                           azure_location: "West US")
  end

  it "create" do
    rsp = @connection.vnets.create(
      azure_vnet_name: "func-test-new-vnet",
      azure_ag_name: "func-test-agforvnet",
      azure_address_space: "10.0.0.0/16")
    rsp.at_css("Status").should_not be_nil
    rsp.at_css("Status").content.should eq("Succeeded")
  end

  specify { @connection.vnets.exists?("notexist").should eq(false) }
  specify { @connection.vnets.exists?("func-test-new-vnet").should eq(true) }

  it "run through" do
    @connection.vnets.all.each do |vnet|
      vnet.name.should_not be_nil
      vnet.affinity_group.should_not be_nil
      vnet.state.should_not be_nil
    end
  end
end
