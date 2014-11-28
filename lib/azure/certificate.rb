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
    def add(certificate_data, certificate_password, certificate_format, dns_name)
      certificate = Certificate.new(@connection)
      certificate.add_certificate certificate_data, certificate_password, certificate_format, dns_name
    end

    def generate_keypair key_length
        OpenSSL::PKey::RSA.new(key_length.to_i)
      end

      def prompt_for_passphrase
        passphrase = ""
        begin
          print "Passphrases do not match.  Try again.\n" unless passphrase.empty?
          print "Enter certificate passphrase (empty for no passphrase):"
          passphrase = STDIN.gets
          return passphrase.strip if passphrase == "\n"
          print "Enter same passphrase again:"
          confirm_passphrase = STDIN.gets
        end until passphrase == confirm_passphrase
        passphrase.strip
      end

      def generate_certificate(rsa_key, cert_params)
        @hostname = "*"
        if cert_params[:domain]
          @hostname = "*." + cert_params[:domain]
        end

        #Create a self-signed X509 certificate from the rsa_key (unencrypted)
        cert = OpenSSL::X509::Certificate.new
        cert.version = 2
        cert.serial = Random.rand(65534) + 1 # 2 digit byte range random number for better security aspect

        cert.subject = OpenSSL::X509::Name.parse "/CN=#{@hostname}"
        cert.issuer = cert.subject
        cert.public_key = rsa_key.public_key
        cert.not_before = Time.now
        cert.not_after = cert.not_before + 2 * 365 * cert_params[:cert_validity].to_i * 60 * 60 # 2 years validity
        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = cert
        cert.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
        cert.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
        cert.add_extension(ef.create_extension("extendedKeyUsage", "1.3.6.1.5.5.7.3.1", false))
        cert.sign(rsa_key, OpenSSL::Digest::SHA1.new)
        @thumbprint = OpenSSL::Digest::SHA1.new(cert.to_der)
        cert
      end

      def write_certificate_to_file cert, file_path, rsa_key, cert_params
        File.open(file_path + ".pem", "wb") { |f| f.print cert.to_pem }
        @winrm_cert_passphrase = prompt_for_passphrase unless @winrm_cert_passphrase
        pfx = OpenSSL::PKCS12.create("#{cert_params[:winrm_cert_passphrase]}", "winrmcert", rsa_key, cert)
        File.open(file_path + ".pfx", "wb") { |f| f.print pfx.to_der }
        File.open(file_path + ".der", "wb") { |f| f.print Base64.strict_encode64(pfx.to_der) }
      end

    def create_ssl_certificate cert_params    
      file_path = cert_params[:output_file].sub(/\.(\w+)$/,'')

      rsa_key = generate_keypair cert_params[:key_length]
          cert = generate_certificate(rsa_key, cert_params)
          write_certificate_to_file cert, file_path, rsa_key, cert_params
          puts "*"*70
          puts "Generated Certificates:"
          puts " PKCS12 FORMAT (needed on the server machine, contains private key): #{file_path}.pfx"
          puts " BASE64 ENCODED (used for creating SSL listener through cloud provider api, contains private key): #{file_path}.der"
          puts " PEM FORMAT (required by the client to connect to the server): #{file_path}.pem"
          puts "Certificate Thumbprint: #{@thumbprint.to_s.upcase}"
          puts "*"*70
      @winrm_cert_passphrase
    end
  end
end

class Azure
  class Certificate
    attr_accessor :connection
    attr_accessor :cert_data, :fingerprint, :certificate_version
    def initialize(connection)
      @connection = connection
      @certificate_version = 2 # cf. RFC 5280 - to make it a "v3" certificate
    end
    def create(params)
      # If RSA private key has been specified, then generate an x 509 certificate from the
      # public part of the key
      @cert_data = generate_public_key_certificate_data({:ssh_key => params[:identity_file],
                                             :ssh_key_passphrase => params[:identity_file_passphrase]})
      add_certificate @cert_data, 'knifeazure', 'pfx', params[:azure_dns_name]
      # Return the fingerprint to be used while adding role
      @fingerprint
    end

    def generate_public_key_certificate_data (params)
      # Generate OpenSSL RSA key from the mentioned ssh key path (and passphrase)
      key = OpenSSL::PKey::RSA.new(File.read(params[:ssh_key]), params[:ssh_key_passphrase])
      # Generate X 509 certificate
      ca = OpenSSL::X509::Certificate.new
      ca.version = @certificate_version
      ca.serial = Random.rand(65534) + 1 # 2 digit byte range random number for better security aspect
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

    def add_certificate certificate_data, certificate_password, certificate_format, dns_name
        require 'pry'
        binding.pry
       # Generate XML to call the API
       # Add certificate to the hosted service
       builder = Nokogiri::XML::Builder.new do |xml|
         xml.CertificateFile('xmlns'=>'http://schemas.microsoft.com/windowsazure') {
         xml.Data certificate_data
         xml.CertificateFormat certificate_format
         xml.Password certificate_password
         }
       end
       # Windows Azure API call
       @connection.query_azure("hostedservices/#{dns_name}/certificates", "post", builder.to_xml)
    end

  end
end
