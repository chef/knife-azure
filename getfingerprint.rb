require 'openssl'

certificate = 
OpenSSL::X509::Certificate.new(File.read('myCert.cer'))
mycert = certificate.to_pem



mycert["-----BEGIN CERTIFICATE-----\n"] = ""
mycert["-----END CERTIFICATE-----\n"] = ""


newcert = File.read('azureCert.pem')
puts newcert
newcert["-----BEGIN CERTIFICATE-----\n"] = ""
newcert["-----END CERTIFICATE-----\n"] = ""
sha1 = OpenSSL::Digest::SHA1.new(newcert)
puts sha1
