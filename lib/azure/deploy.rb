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
    # force_load should be true when there is something in local cache and we want to reload
    # first call is always load.
    def load(force_load = false)
      if not @deploys || force_load
        @deploys = begin
          deploys = Array.new
          hosts = @connection.hosts.all
          hosts.each do |host|
            deploy = Deploy.new(@connection)
            deploy.retrieve(host.name)
            if deploy.name
              host.add_deploy(deploy)
              deploys << deploy
            end
          end
          deploys
        end
      end
      @deploys
    end

    def all
      self.load
    end

    # TODO - Current knife-azure plug-in seems to have assumption that single hostedservice
    # will always have one deployment (production). see Deploy#retrieve below
    def get_deploy_name_for_hostedservice(hostedservicename)
      host = @connection.hosts.find(hostedservicename)
      if host && host.deploys.length > 0
        host.deploys[0].name
      else
        nil
      end
    end

    def create(params)
      if params[:azure_connect_to_existing_dns]
        unless @connection.hosts.exists?(params[:azure_dns_name])
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
      unless @connection.storageaccounts.exists?(params[:azure_storage_account])
        @connection.storageaccounts.create(params)
      end
      if params[:identity_file]
        params[:fingerprint] = @connection.certificates.create(params)
      end
      params['deploy_name'] = get_deploy_name_for_hostedservice(params[:azure_dns_name])

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
        raise Chef::Log.fatal 'Unable to create role:' + ret_val.at_css('Error Code').content + ' : ' + ret_val.at_css('Error Message').content
      end
      @connection.roles.find_in_hosted_service(params[:azure_vm_name], params[:azure_dns_name])
    end
    def delete(rolename)
    end
  end

  class Deploy
    include AzureUtility
    attr_accessor :connection, :name, :status, :url, :hostedservicename

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
        @roles = Hash.new
        rolesXML = deployXML.css('Deployment RoleInstanceList RoleInstance')
        rolesXML.each do |roleXML|
          role = Role.new(@connection)
          role.parse(roleXML, hostedservicename, @name)
          @roles[role.name] = role
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
          if params[:azure_network_name]
            xml.VirtualNetworkName params[:azure_network_name]
          end
        }
      end
      builder.doc.at_css('Role') << roleXML.at_css('PersistentVMRole').children.to_s
      builder.doc
    end
    def create(params, deployXML)
      servicecall = "hostedservices/#{params[:azure_dns_name]}/deployments"
      @connection.query_azure(servicecall, "post", deployXML.to_xml)
    end

    def roles
      @roles.values if @roles
    end

    # just delete from local cache
    def delete_role_if_present(role)
      @roles.delete(role.name) if @roles
    end

    def find_role(name)
      @roles[name] if @roles
    end

  end
end
