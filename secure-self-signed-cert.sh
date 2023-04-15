#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
  echo "Domain missing! Aborting..." >&2
  exit 1
fi

declare -A subject
subject["domain"]="/CN=$1"
subject["root"]="/CN=duxsco root CA for $1"

for type in "${!subject[@]}"; do
  openssl genrsa -aes256 -out "${1}-${type}-key.pem" 2048
  openssl req -new -sha256 -subj "${subject[$type]}" -key "${1}-${type}-key.pem" -out "${1}-${type}-csr.pem"
done

openssl x509 -req -days 400 -in "${1}-root-csr.pem" -out "${1}-root.pem" -signkey "${1}-root-key.pem" -extfile <(
echo "keyUsage = critical,keyCertSign
basicConstraints = critical,CA:TRUE,pathlen:0
nameConstraints=critical,permitted;DNS:$1
subjectKeyIdentifier=hash")

openssl x509 -req -days 370 -in "${1}-domain-csr.pem" -out "${1}-domain.pem" -CA "${1}-root.pem" -CAkey "${1}-root-key.pem" -extfile <(
echo "keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:$1
authorityKeyIdentifier=keyid")
