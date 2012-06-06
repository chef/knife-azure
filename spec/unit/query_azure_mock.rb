
module QueryAzureMock
  def setup_query_azure_mock
    @getname = ''
    @getverb = ''
    @getbody = ''

    @postname = ''
    @postverb = ''
    @postbody = ''

    @deletename = ''
    @deleteverb = ''
    @deletebody = ''
    @deletecount = 0

    params = {:azure_subscription_id => "155a9851-88a8-49b4-98e4-58055f08f412", :azure_pem_file => "AzureLinuxCert.pem",
      :azure_host_name => "management-preview.core.windows-int.net",
      :service_name => "hostedservices"}
    @receivedXML = Nokogiri::XML ''
    @connection = Azure::Connection.new(params)
    @connection.stub(:query_azure) do |name, verb, body|
      Chef::Log.info 'calling web service:' + name
      if verb == 'get' || verb == nil
        retval = ''
        if name == 'images'
          retval = Nokogiri::XML readFile('list_images.xml') 
        elsif name == 'disks'
          retval = Nokogiri::XML readFile('list_disks.xml') 
        elsif name == 'hostedservices'
          retval = Nokogiri::XML readFile('list_hosts.xml') 
        elsif name == 'hostedservices/service001/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_service001.xml')
        elsif name == 'hostedservices/service002/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_service002.xml')
        elsif name == 'hostedservices/service003/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_service003.xml')
        else
          Chef::Log.warn 'unknown get value:' + name
        end
        @getname = name
        @getverb = verb
        @getbody = body
      elsif verb == 'post'
        if name == 'hostedservices'
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        elsif name == 'hostedservices/unknown_yet/deployments'
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        elsif name == 'hostedservices/service001/deployments/deployment001/roles'
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        else
          Chef::Log.warn 'unknown post value:' + name
        end
        @postname = name
        @postverb = verb
        @postbody = body
      elsif verb == 'delete'
        @deletename = name
        @deleteverb = verb
        @deletebody = body
        @deletecount += 1
      else
        Chef::Log.warn 'unknown verb:' + verb
      end
      retval
    end

  end
end
