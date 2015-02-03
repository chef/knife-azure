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
    include AzureUtility
    def initialize(connection)
      @connection = connection
    end
    # force_load should be true when there is something in local cache and we want to reload
    # first call is always load.
    def load(force_load = false)
      unless @deploys || force_load
        @deploys = begin
          deploys = []
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
      load
    end

    # TODO: Current knife-azure plug-in seems to have assumption that single hostedservice
    # will always have one deployment (production). see Deploy#retrieve below
    def get_deploy_name_for_hostedservice(hostedservicename)
      host = @connection.hosts.find(hostedservicename)
      name = host.deploys[0].name if host && host.deploys.length > 0
      name
    end

    def create(params)
      if params[:azure_connect_to_existing_dns]
        unless @connection.hosts.exists?(params[:azure_dns_name])
          Chef::Log.fatal 'The specified Azure DNS Name does not exist.'
          exit 1
        end
      else
        ret_val = @connection.hosts.create(params)
        error_code, error_message = error_from_response_xml(ret_val)
        if error_code.length > 0
          Chef::Log.fatal 'Unable to create DNS:' + error_code + ' : ' + error_message
          exit 1
        end
      end
      unless @connection.storageaccounts.exists?(params[:azure_storage_account])
        @connection.storageaccounts.create(params)
      end
      if params[:identity_file]
        params[:fingerprint] = @connection.certificates.create(params)
      end
      if params[:cert_path]
        cert_data = File.read(params[:cert_path])
        @connection.certificates.add cert_data, params[:cert_password], 'pfx', params[:azure_dns_name]
      elsif (params[:winrm_transport] == 'ssl')
        thumbprint = @connection.certificates.create_ssl_certificate params[:azure_dns_name]
        params[:ssl_cert_fingerprint] = thumbprint.to_s.upcase
      end

      params['deploy_name'] = get_deploy_name_for_hostedservice(params[:azure_dns_name])

      if !params['deploy_name'].nil?
        role = Role.new(@connection)
        role_xml = role.setup(params)
        ret_val = role.create(params, role_xml)
      else
        params['deploy_name'] = params[:azure_dns_name]
        deploy = Deploy.new(@connection)
        deploy_xml = deploy.setup(params)
        ret_val = deploy.create(params, deploy_xml)
      end
      error_code, error_message = error_from_response_xml(ret_val)
      if error_code.length > 0
        Chef::Log.debug(ret_val.to_s)
        fail Chef::Log.fatal 'Unable to create role:' + error_code + ' : ' + error_message
      end
      @connection.roles.find_in_hosted_service(params[:azure_vm_name], params[:azure_dns_name])
    end

    def delete(_rolename)
    end

    def query_deploy(hostedservicename)
      deploy = Deploy.new(@connection)
      deploy.retrieve(hostedservicename)
      deploy
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
      deploy_xml = @connection.query_azure("hostedservices/#{hostedservicename}/deploymentslots/Production")
      return if deploy_xml.at_css('Deployment Name').nil?
      @name = xml_content(deploy_xml, 'Deployment Name')
      @status = xml_content(deploy_xml, 'Deployment Status')
      @url = xml_content(deploy_xml, 'Deployment Url')
      @roles = {}
      roles_xml = deploy_xml.css('Deployment RoleInstanceList RoleInstance')
      roles_xml.each do |role_xml|
        role = Role.new(@connection)
        role.parse(role_xml, hostedservicename, @name)
        @roles[role.name] = role
      end
    end

    def setup(params)
      role = Role.new(@connection)
      role_xml = role.setup(params)
      # role_xml = Nokogiri::XML role.setup(params)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Deployment(
          'xmlns' => 'http://schemas.microsoft.com/windowsazure',
          'xmlns:i' => 'http://www.w3.org/2001/XMLSchema-instance'
        ) do
          xml.Name params['deploy_name']
          xml.DeploymentSlot 'Production'
          xml.Label Base64.encode64(params['deploy_name']).strip
          xml.RoleList { xml.Role('i:type' => 'PersistentVMRole') }
          if params[:azure_network_name]
            xml.VirtualNetworkName params[:azure_network_name]
          end
        end
      end
      builder.doc.at_css('Role') << role_xml.at_css('PersistentVMRole').children.to_s
      builder.doc
    end

    def create(params, deploy_xml)
      servicecall = "hostedservices/#{params[:azure_dns_name]}/deployments"
      @connection.query_azure(servicecall, 'post', deploy_xml.to_xml)
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
