require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module QueryAzureMock
  include AzureUtility
  def setup_query_azure_mock
    create_connection
    stub_query_azure (@connection)
  end

  def create_connection
    @connection = Azure::Connection.new(TEST_PARAMS)
  end

  def lookup_resource_in_test_xml(lookup_name, lookup_pty, tag, in_file)
    dataXML = Nokogiri::XML readFile(in_file)
    itemsXML = dataXML.css(tag)
    not_found = true
    retval = ''
    itemsXML.each do |itemXML|
      if xml_content(itemXML, lookup_pty) == lookup_name
        not_found = false
        retval = itemXML
        break
      end
    end
    retval = Nokogiri::XML readFile('error_404.xml') if not_found
    retval
  end

  def stub_query_azure (connection)
    @getname = ''
    @getverb = ''
    @getbody = ''

    @postname = ''
    @postverb = ''
    @postbody = ''

    @deletename = ''
    @deleteverb = ''
    @deletebody = ''
    @deleteparams= ''
    @deletecount = 0

    @receivedXML = Nokogiri::XML ''
    connection.stub(:query_azure) do |name, verb, body, params|
      Chef::Log.info 'calling web service:' + name
      if verb == 'get' || verb == nil
        retval = ''
        if name == 'images'
          retval = Nokogiri::XML readFile('list_images.xml')
        elsif name == 'disks'
          retval = Nokogiri::XML readFile('list_disks.xml')
        elsif name == 'disks/deployment001-role002-0-201241722728'
          retval = Nokogiri::XML readFile('list_disks_for_role002.xml')
        elsif name == 'hostedservices'
          retval = Nokogiri::XML readFile('list_hosts.xml')
        elsif name =~ /hostedservices\/([-\w]*)$/ && params == "embed-detail=true"
          retval = Nokogiri::XML readFile('list_deployments_for_service001.xml')
        elsif name =~ /hostedservices\/([-\w]*)$/
          service_name = /hostedservices\/([-\w]*)/.match(name)[1]
          retval = lookup_resource_in_test_xml(service_name, 'ServiceName', 'HostedServices HostedService', 'list_hosts.xml')
        elsif name == 'hostedservices/service001/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_service001.xml')
        elsif name == 'hostedservices/service001/deployments/deployment001/roles/role001'
          retval = Nokogiri::XML readFile('list_deployments_for_service001.xml')
        elsif name == 'hostedservices/service002/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_service002.xml')
        elsif name == 'hostedservices/service002/deployments/testrequest'
          retval = Nokogiri::XML readFile('list_deployments_for_service002.xml')
        elsif name == 'hostedservices/service003/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_service003.xml')
        elsif name == 'hostedservices/vmname/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_vmname.xml')
        elsif name == 'hostedservices/service004/deploymentslots/Production'
          retval = Nokogiri::XML readFile('list_deployments_for_service004.xml')
        elsif name == 'storageservices'
          retval = Nokogiri::XML readFile('list_storageaccounts.xml')
        elsif name =~ /storageservices\/[-\w]*$/
          service_name = /storageservices\/([-\w]*)/.match(name)[1]
          retval = lookup_resource_in_test_xml(service_name, 'ServiceName', 'StorageServices StorageService', 'list_storageaccounts.xml')
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
        elsif name == 'hostedservices/service004/deployments/deployment004/roles'
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        elsif name =~ /hostedservices\/vm01.*\/deployments/
          retval = Nokogiri::XML readFile('post_success.xml')
          @receivedXML = body
        elsif name =~ /hostedservices\/vmname\/deployments/
          # Case when vm name and service name are same.
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
        @deleteparams = params
        @deletecount += 1
      else
        Chef::Log.warn 'unknown verb:' + verb
      end
      retval
    end

  end
end
