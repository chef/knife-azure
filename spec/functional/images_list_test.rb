require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Connection" do

  before(:all) do
    params = { :azure_subscription_id => "155a9851-88a8-49b4-98e4-58055f08f412",
      :azure_pem_file => "AzureLinuxCert.pem",
      :azure_host_name => "management-preview.core.windows-int.net",
      :service_name => "hostedservices"}
    @connection = Azure::Connection.new(params)
    @items = @connection.images.all
  end

  it "should be contain images" do 
    @items.length.should be > 1
  end
  it "each image should have all fields valid" do
    @items.each do |image|
      image.category.should_not be_nil
      image.label.should_not be_nil
      image.name.should_not be_nil
      image.os.should_not be_nil
      image.eula.should_not be_nil
      image.description.should_not be_nil
    end
  end


  #  it "should get services" do
  #    @demo.DemoGet
  #  end
  #  it "bad subscription should fail with ResourceNotFound" do
  #    @demo.subscription = "ae2ff9b3-12b2-45cf-b58e-468bc7e29110xxxxx"
  #
  #    expect{@demo.DemoGet}.to raise_error(RuntimeError, /ResourceNotFound/)
  #  end
  #  it "bad pem_path should fail with CertificateError" do
  #    @demo.pem_file = ""
  #
  #    expect{@demo.DemoGet}.to raise_error(OpenSSL::X509::CertificateError)
  #  end
  #  it "bad service_name should fail with " do
  #    @demo.service_name = ""
  #
  #    expect{@demo.DemoGet}.to raise_error(RuntimeError, /ResourceNotFound/)
  #  end
end

