#
# Author:: Mukta Aphale (mukta.aphale@clogeny.com)
# Copyright:: Copyright 2010-2019, Chef Software Inc.
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

module Azure
  class Certificates
    def initialize(connection)
      @connection = connection
    end

    def create(params)
      certificate = Certificate.new(@connection)
      certificate.create(params)
    end

    def add(certificate_data, certificate_password, certificate_format, dns_name)
      certificate = Certificate.new(@connection)
      certificate.add_certificate certificate_data, certificate_password, certificate_format, dns_name
    end

    def create_ssl_certificate(azure_dns_name)
      cert_params = { output_file: "winrm", key_length: 2048, cert_validity: 24,
                      azure_dns_name: azure_dns_name }
      certificate = Certificate.new(@connection)
      thumbprint = certificate.create_ssl_certificate(cert_params)
    end

    def get_certificate(dns_name, fingerprint)
      certificate = Certificate.new(@connection)
      certificate.get_certificate(dns_name, fingerprint)
    end
  end
end

module Azure
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
      @cert_data = generate_public_key_certificate_data({ ssh_key: params[:ssh_identity_file],
                                                          ssh_key_passphrase: params[:identity_file_passphrase] })
      add_certificate @cert_data, "knifeazure", "pfx", params[:azure_dns_name]

      # Return the fingerprint to be used while adding role
      @fingerprint
    end

    def generate_public_key_certificate_data(params)
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
      ca.add_extension(ef.create_extension("basicConstraints", "CA:TRUE", true))
      ca.add_extension(ef.create_extension("keyUsage", "keyCertSign, cRLSign", true))
      ca.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
      ca.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))
      ca.sign(key, OpenSSL::Digest::SHA256.new)
      # Generate the SHA1 fingerprint of the der format of the X 509 certificate
      @fingerprint = OpenSSL::Digest::SHA1.new(ca.to_der)
      # Create the pfx format of the certificate
      pfx = OpenSSL::PKCS12.create("knifeazure", "knife-azure-pfx", key, ca)
      # Encode the pfx format - upload this certificate
      Base64.strict_encode64(pfx.to_der)
    end

    def add_certificate(certificate_data, certificate_password, certificate_format, dns_name)
      # Generate XML to call the API
      # Add certificate to the hosted service
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.CertificateFile("xmlns" => "http://schemas.microsoft.com/windowsazure") do
          xml.Data certificate_data
          xml.CertificateFormat certificate_format
          xml.Password certificate_password
        end
      end
      # Windows Azure API call
      @connection.query_azure("hostedservices/#{dns_name}/certificates", "post", builder.to_xml)

      # Check if certificate is available else raise error
      for attempt in 0..4
        Chef::Log.info "Waiting to get certificate ..."
        res = get_certificate(dns_name, @fingerprint)
        break unless res.empty?
        if attempt == 4
          raise "The certificate with thumbprint #{fingerprint} was not found."
        else
          sleep 5
        end
      end
    end

    def get_certificate(dns_name, fingerprint)
      @connection.query_azure("hostedservices/#{dns_name}/certificates/sha1-#{fingerprint}", "get").search("Certificate")
    end

    ########   SSL certificate generation for knife-azure ssl bootstrap ######
    def create_ssl_certificate(cert_params)
      file_path = cert_params[:output_file].sub(/\.(\w+)$/, "")
      path = prompt_for_file_path
      file_path = File.join(path, file_path) unless path.empty?
      cert_params[:domain] = prompt_for_domain

      rsa_key = generate_keypair cert_params[:key_length]
      cert = generate_certificate(rsa_key, cert_params)
      write_certificate_to_file cert, file_path, rsa_key, cert_params
      puts "*" * 70
      puts "Generated Certificates:"
      puts "- #{file_path}.pfx - PKCS12 format keypair. Contains both the public and private keys, usually used on the server."
      puts "- #{file_path}.b64 - Base64 encoded PKCS12 keypair. Contains both the public and private keys, for upload to the Azure REST API."
      puts "- #{file_path}.pem - Base64 encoded public certificate only. Required by the client to connect to the server."
      puts "Certificate Thumbprint: #{@thumbprint.to_s.upcase}"
      puts "*" * 70

      Chef::Config[:knife][:ca_trust_file] = file_path + ".pem" if Chef::Config[:knife][:ca_trust_file].nil?
      cert_data = File.read (file_path + ".b64")
      add_certificate cert_data, @winrm_cert_passphrase, "pfx", cert_params[:azure_dns_name]
      @thumbprint
    end

    def generate_keypair(key_length)
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

    def prompt_for_file_path
      file_path = ""
      counter = 0
      begin
        print "Invalid location! \n" unless file_path.empty?
        print 'Enter the file path for certificates e.g. C:\Windows (empty for current location):'
        file_path = STDIN.gets
        stripped_file_path = file_path.strip
        return stripped_file_path if file_path == "\n"

        counter += 1
        exit(1) if counter == 3
      end until File.directory?(stripped_file_path)
      stripped_file_path
    end

    def prompt_for_domain
      counter = 0
      begin
        print "Enter the domain (mandatory):"
        domain = STDIN.gets
        domain = domain.strip
        counter += 1
        exit(1) if counter == 3
      end until !domain.empty?
      domain
    end

    def generate_certificate(rsa_key, cert_params)
      @hostname = "*"
      if cert_params[:domain]
        @hostname = "*." + cert_params[:domain]
      end

      # Create a self-signed X509 certificate from the rsa_key (unencrypted)
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
      cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
      cert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))
      cert.add_extension(ef.create_extension("extendedKeyUsage", "1.3.6.1.5.5.7.3.1", false))
      cert.sign(rsa_key, OpenSSL::Digest::SHA1.new)
      @thumbprint = OpenSSL::Digest::SHA1.new(cert.to_der)
      cert
    end

    def write_certificate_to_file(cert, file_path, rsa_key, cert_params)
      File.open(file_path + ".pem", "wb") { |f| f.print cert.to_pem }
      @winrm_cert_passphrase = prompt_for_passphrase unless @winrm_cert_passphrase
      pfx = OpenSSL::PKCS12.create("#{cert_params[:winrm_cert_passphrase]}", "winrmcert", rsa_key, cert)
      File.open(file_path + ".pfx", "wb") { |f| f.print pfx.to_der }
      File.open(file_path + ".b64", "wb") { |f| f.print Base64.strict_encode64(pfx.to_der) }
    end

    ##########   SSL certificate generation ends ###########

  end
end
