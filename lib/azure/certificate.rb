#
# Author:: Mukta Aphale (mukta.aphale@clogeny.com)
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
  class Certificates
    def initialize(connection)
      @connection=connection
    end
    def create(params)
      certificate = Certificate.new(@connection)
      certificate.create(params)
    end
  end
end

class Azure
  class Certificate
    attr_accessor :connection, :certificate_name, :hosted_service_name
    attr_accessor :cert_data, :fingerprint
    def initialize(connection)
      @connection = connection
    end
    def create(params)
      # If ssh-key has been specified, then generate an x 509 certificate from the
      # given RSA private key
      @cert_data = generateCertificateData({:ssh_key => params[:identity_file],
                                             :ssh_key_passphrase => params[:identity_file_passphrase]})
      # Generate XML to call the API
      # Add certificate to the hosted service
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.CertificateFile('xmlns'=>'http://schemas.microsoft.com/windowsazure') {
          xml.Data @cert_data
          xml.CertificateFormat 'pfx'
          xml.Password 'knifeazure'
        }
      end
      # Windows Azure API call
      @connection.query_azure("hostedservices/#{params[:hosted_service_name]}/certificates", "post", builder.to_xml)
      # Return the fingerprint to be used while adding role
      @fingerprint
    end

    def generateCertificateData (params)
      # Generate OpenSSL RSA key from the mentioned ssh key path (and passphrase)
      key = OpenSSL::PKey::RSA.new(File.read(params[:ssh_key]), params[:ssh_key_passphrase])
      # Generate X 509 certificate
      ca = OpenSSL::X509::Certificate.new
      ca.version = 2 # cf. RFC 5280 - to make it a "v3" certificate
      ca.serial = Random.rand(100) # 2 digit random number for better security aspect
      ca.subject = OpenSSL::X509::Name.parse "/DC=org/DC=knife-plugin/CN=Opscode CA"
      ca.issuer = ca.subject # root CA's are "self-signed"
      ca.public_key = key.public_key # Assign the ssh-key's public part to the certificate
      ca.not_before = Time.now
      ca.not_after =  ca.not_before + 2 * 365 * 24 * 60 * 60 # 2 years validity
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = ca
      ef.issuer_certificate = ca
      ca.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
      ca.add_extension(ef.create_extension("keyUsage","keyCertSign, cRLSign", true))
      ca.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
      ca.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
      ca.sign(key, OpenSSL::Digest::SHA256.new)
      # Generate the SHA1 fingerprint of the der format of the X 509 certificate
      @fingerprint =  OpenSSL::Digest::SHA1.new(ca.to_der)
      # Create the pfx format of the certificate
      pfx = OpenSSL::PKCS12.create('knifeazure', 'knife-azure-pfx',  key,  ca)
      # Encode the pfx format - upload this certificate 
      Base64.strict_encode64(pfx.to_der)
    end
  end
end
