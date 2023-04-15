#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
  echo "Domain missing! Aborting..." >&2
  exit 1
fi

domain="$1"

declare -A subject
subject["domain"]="/CN=${domain}"
subject["root"]="/CN=duxsco root CA for ${domain}"

for type in "${!subject[@]}"; do
  openssl genrsa -aes256 -out "${domain}-${type}-key.pem" 2048
  openssl req -new -sha256 -subj "${subject[$type]}" -key "${domain}-${type}-key.pem" -out "${domain}-${type}-csr.pem"
done

openssl x509 -req -days 400 -in "${domain}-root-csr.pem" -out "${domain}-root.pem" -signkey "${domain}-root-key.pem" -extfile <(
echo "keyUsage = critical,keyCertSign
basicConstraints = critical,CA:TRUE,pathlen:0
nameConstraints=critical,permitted;DNS:${domain},excluded;DNS:.${domain}
subjectKeyIdentifier=hash")

openssl x509 -req -days 370 -in "${domain}-domain-csr.pem" -out "${domain}-domain.pem" -CA "${domain}-root.pem" -CAkey "${domain}-root-key.pem" -extfile <(
echo "keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:${domain}
authorityKeyIdentifier=keyid")

if ! openssl verify -CAfile "${domain}-root.pem" "${domain}-domain.pem" >/dev/null 2>&1; then
echo '
  _________________
< Something smells! >
  -----------------
         \   ^__^
          \  (oo)\_______
             (__)\       )\/\
                 ||----w |
                 ||     ||
'
fi
