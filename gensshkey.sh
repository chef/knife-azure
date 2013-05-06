#!/bin/bash 
REQUIRED_ARGS=1 
E_NOT_ENOUGH_ARGS=65

#first argument will be used as the key prefix 
#second argument is optional and if given will be used as a pass #phrase for DES3 protection of the private key 
case $# in 
  1) 
  openssl req -x509  -days 365 -newkey rsa:2048 -keyout $1sshpvt.pem -out $1pub.pem -nodes 
  openssl rsa -in $1sshpvt.pem -out $1pvt.pem 
  ;; 
  2) 
  openssl req -x509  -days 365 -newkey rsa:2048 -keyout $1sshpvt.pem -out $1pub.pem -passout pass:$2 
  openssl rsa -in $1sshpvt.pem -passin pass:$2 -out $1pvt.pem -des3 -passout pass:$2 
  ;; 
  
  *) 
  echo "Usage for unprotected private key: gensshkey.sh <key_prefix>" 
  echo "Example: gensshkey.sh \"db\"" 
  echo "Usage for password protected private key: gensshkey.sh <key_prefix> <pass phrase>" 
  echo "Example: gensshkey.sh db pass@word1" 
  exit $E_NOT_ENOUGH_ARGS 
  ;; 
esac 
echo "generated $1sshpvt.pem, $1pub.pem and $1pvt.pem"
