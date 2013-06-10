#
# Author:: Barry Davis (barryd@jetstreamsoftware.com)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Azure
  class Deploys
    def initialize(connection)
      @connection=connection
    end
    def all
      deploys = Array.new
      hosts = @connection.hosts.all
      hosts.each do |host|
        deploy = Deploy.new(@connection)
        deploy.retrieve(host.name)
        unless deploy.name == nil
          deploys << deploy
        end
      end
      deploys
    end
    def find(hostedservicename)
      deployName = nil
      self.all.each do |deploy|
        next unless deploy.hostedservicename == hostedservicename
        deployName = deploy.name
      end
      deployName
    end
    def create(params)
      if params[:azure_connect_to_existing_dns]
        unless @connection.hosts.exists(params[:azure_dns_name])
          Chef::Log.fatal 'The specified Azure DNS Name does not exist.'
          exit 1
        end
      else
        ret_val = @connection.hosts.create(params)
        if ret_val.css('Error Code').length > 0
          Chef::Log.fatal 'Unable to create DNS:' + ret_val.at_css('Error Code').content + ' : ' + ret_val.at_css('Error Message').content
          exit 1
        end
      end
      unless @connection.storageaccounts.exists(params[:azure_storage_account])
        @connection.storageaccounts.create(params)
      end
      if params[:identity_file]
        params[:fingerprint] = @connection.certificates.create(params)
      end
      params['deploy_name'] = find(params[:azure_dns_name])

      if params['deploy_name'] != nil
        role = Role.new(@connection)
        roleXML = role.setup(params)
        ret_val = role.create(params, roleXML)
      else
        params['deploy_name'] = params[:azure_dns_name]
        deploy = Deploy.new(@connection)
        deployXML = deploy.setup(params)
        ret_val = deploy.create(params, deployXML)
      end
      if ret_val.css('Error Code').length > 0
          Chef::Log.fatal 'Unable to create role:' + ret_val.at_css('Error Code').content + ' : ' + ret_val.at_css('Error Message').content
          exit 1
      end
      @connection.roles.find(params[:azure_vm_name])
    end
    def delete(rolename)
    end
  end

  class Deploy
    include AzureUtility
    attr_accessor :connection, :name, :status, :url, :roles, :hostedservicename
    def initialize(connection)
      @connection = connection
    end
    def retrieve(hostedservicename)
      @hostedservicename = hostedservicename
      deployXML = @connection.query_azure("hostedservices/#{hostedservicename}/deploymentslots/Production")
      if deployXML.at_css('Deployment Name') != nil
        @name = xml_content(deployXML, 'Deployment Name')
        @status = xml_content(deployXML,'Deployment Status')
        @url = xml_content(deployXML, 'Deployment Url')
        @roles = Array.new
        rolesXML = deployXML.css('Deployment RoleInstanceList RoleInstance')
        rolesXML.each do |roleXML|
          role = Role.new(@connection)
          role.parse(roleXML, hostedservicename, @name)
          @roles << role
        end
      end
    end
    def setup(params)
      role = Role.new(@connection)
      roleXML = role.setup(params)
      #roleXML = Nokogiri::XML role.setup(params)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Deployment(
          'xmlns'=>'http://schemas.microsoft.com/windowsazure',
          'xmlns:i'=>'http://www.w3.org/2001/XMLSchema-instance'
        ) {
          xml.Name params['deploy_name']
          xml.DeploymentSlot 'Production'
          xml.Label Base64.encode64(params['deploy_name']).strip
          xml.RoleList { xml.Role('i:type'=>'PersistentVMRole') }
        }
      end
      builder.doc.at_css('Role') << roleXML.at_css('PersistentVMRole').children.to_s
      builder.doc
    end
    def create(params, deployXML)
      servicecall = "hostedservices/#{params[:azure_dns_name]}/deployments"
      @connection.query_azure(servicecall, "post", deployXML.to_xml)
    end
  end
end
