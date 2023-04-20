#!/usr/bin/env bash

unset bits domain
rsa="false"
stronger="false"
years="1"

function help() {
cat <<EOF
${0##*\/} -d <domain> [-r] [-s] [-y <number of years> ]
"-d" specifies the domain, e.g. "www.mydomain.internal"
"-r" uses RSA instead of default ECDSA
"-s" creates stronger keys. Depending on the algorithm in use,
     RSA 3072 bit instead of 2048 bit or
     ECDSA 384 bit instead of 256 bit is used.
"-y" sets number of years the domain certificate should be valid (default: 1 year).
     The root certificate is valid 1 year longer than the domain certificate.
     So, you can issue a new valid domain certificate using the old root key
     if the expiration of the old domain certificate has gone unnoticed.
"-h" prints this help
EOF
}

if [[ $(uname -s) == Darwin ]]; then
    if [[ -n ${HOMEBREW_PREFIX} ]]; then
        openssl="${HOMEBREW_PREFIX}/opt/openssl/bin/openssl"
    else
        echo "Install openssl using HomeBrew, please! Aborting..." >&2
        exit 1
    fi
else
    openssl="openssl"
fi

while getopts d:rsy:h opt; do
    case $opt in
        d) domain="$OPTARG";;
        r) rsa="true";;
        s) stronger="true";;
        y) years="$OPTARG";;
        h) help; exit 0;;
        ?) help; exit 1;;
    esac
done

if [[ -z ${domain} ]]; then
  help
  exit 1
fi

if [[ ${stronger} == true ]]; then
  case $rsa in
    false) bits=384;;
    true)  bits=3072;;
  esac
fi

declare -A subject
subject["domain"]="/CN=${domain}"
subject["root"]="/CN=duxsco root CA for ${domain}"

echo ""
read -r -s -p 'Passphrase to set for private key: ' PASSPHRASE
echo ""
read -r -s -p 'Please, repeat the passphrase: ' PASSPHRASE_REPEAT

if [ "${PASSPHRASE}" != "${PASSPHRASE_REPEAT}" ]; then 
    echo -e "\nPassphrases don't match! Aborting...\n"
    exit 1
else
    echo -e "\n"
    export PASSPHRASE
fi

for type in "${!subject[@]}"; do
  if [[ ${rsa} == "true" ]]; then
    ${openssl} genpkey -pass env:PASSPHRASE -aes256 -out "${domain}-${type}-key.pem" -algorithm RSA -pkeyopt "rsa_keygen_bits:${bits:-2048}"
  else
    ${openssl} genpkey -pass env:PASSPHRASE -aes256 -out "${domain}-${type}-key.pem" -algorithm EC  -pkeyopt "ec_paramgen_curve:P-${bits:-256}" -pkeyopt ec_param_enc:named_curve
  fi

  ${openssl} req -passin env:PASSPHRASE -new -sha256 -subj "${subject[$type]}" -key "${domain}-${type}-key.pem" -out "${domain}-${type}-csr.pem"
done

${openssl} x509 -passin env:PASSPHRASE -req -days $(( ( years + 1 ) * 365 )) -in "${domain}-root-csr.pem" -out "${domain}-root.pem" -signkey "${domain}-root-key.pem" -extfile <(
echo "keyUsage = critical,keyCertSign
basicConstraints = critical,CA:TRUE,pathlen:0
nameConstraints=critical,permitted;DNS:${domain},excluded;DNS:.${domain}
subjectKeyIdentifier=hash")

${openssl} x509 -passin env:PASSPHRASE -req -days $(( years * 365 )) -in "${domain}-domain-csr.pem" -out "${domain}-domain.pem" -CA "${domain}-root.pem" -CAkey "${domain}-root-key.pem" -extfile <(
echo "keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:${domain}
authorityKeyIdentifier=keyid")

if ! ${openssl} verify -CAfile "${domain}-root.pem" "${domain}-domain.pem" >/dev/null 2>&1; then
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
