# secure-self-signed-cert

This script basically creates the same simple certificate chain as [mkcert](https://github.com/FiloSottile/mkcert), but with the [Name Constraints](https://www.openssl.org/docs/man1.1.1/man5/x509v3_config.html#Name-Constraints) restriction. The following examples will have this "Name Constraints" in the root certificate:

```
❯ openssl x509 -noout -in mydomain.internal-root.pem -ext nameConstraints
X509v3 Name Constraints: critical
    Permitted:
      DNS:mydomain.internal
    Excluded:
      DNS:.mydomain.internal
```

Thus, you have a root certificate for import in the webbrowser that is valid only for a single kind of domain (leaf) certificate. Things won't validate successfully as soon as any domain other than the one permitted in the "Name Constraints" is stored in the "Common Name" or "SAN" of the domain certificate.

- Example 1: Forbidden domain in "Common Name"

```
❯ echo Q | openssl s_client \
    -connect mydomain.internal:443 \
    -servername mydomain.internal 2>/dev/null | \
        openssl x509 -noout -subject -ext subjectAltName
subject=CN = www.mydomain.internal

❯ curl --cacert mydomain.internal-root.pem https://www.mydomain.internal
curl: (60) SSL certificate problem: excluded subtree violation
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

- Example 2: Forbidden domain in SAN

```
❯ echo Q | openssl s_client \
    -connect mydomain.internal:443 \
    -servername mydomain.internal 2>/dev/null | \
        openssl x509 -noout -subject -ext subjectAltName
subject=CN = mydomain.internal
X509v3 Subject Alternative Name:
    DNS:mydomain.internal, DNS:www.mydomain.internal

❯ curl --cacert mydomain.internal-root.pem https://mydomain.internal
curl: (60) SSL certificate problem: excluded subtree violation
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

- Example 3: Forbidden domain in "Common Name" and SAN

```
❯ echo Q | openssl s_client \
    -connect mydomain.internal:443 \
    -servername mydomain.internal 2>/dev/null | \
        openssl x509 -noout -subject -ext subjectAltName
subject=CN = www.mydomain.internal
X509v3 Subject Alternative Name:
    DNS:mydomain.internal, DNS:www.mydomain.internal

❯ curl --cacert mydomain.internal-root.pem https://mydomain.internal
curl: (60) SSL certificate problem: excluded subtree violation
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

- Example 3: Valid

```
❯ echo Q | openssl s_client \
    -connect mydomain.internal:443 \
    -servername mydomain.internal 2>/dev/null | \
        openssl x509 -noout -subject -ext subjectAltName
subject=CN = mydomain.internal
X509v3 Subject Alternative Name:
    DNS:mydomain.internal

❯ curl --cacert mydomain.internal-root.pem https://mydomain.internal
hello world!
```

"secure-self-signed-cert.sh" run:

```
❯ bash secure-self-signed-cert.sh mydomain.internal
Generating RSA private key, 2048 bit long modulus (2 primes)
...............+++++
.........+++++
e is 65537 (0x010001)
Enter pass phrase for mydomain.internal-domain-key.pem:
Verifying - Enter pass phrase for mydomain.internal-domain-key.pem:
Enter pass phrase for mydomain.internal-domain-key.pem:
Generating RSA private key, 2048 bit long modulus (2 primes)
...............................................+++++
.....+++++
e is 65537 (0x010001)
Enter pass phrase for mydomain.internal-root-key.pem:
Verifying - Enter pass phrase for mydomain.internal-root-key.pem:
Enter pass phrase for mydomain.internal-root-key.pem:
Signature ok
subject=CN = duxsco root CA for mydomain.internal
Getting Private key
Enter pass phrase for mydomain.internal-root-key.pem:
Signature ok
subject=CN = mydomain.internal
Getting CA Private Key
Enter pass phrase for mydomain.internal-root-key.pem:

❯ ls -1 mydomain.internal-*
mydomain.internal-domain-csr.pem
mydomain.internal-domain-key.pem
mydomain.internal-domain.pem
mydomain.internal-root-csr.pem
mydomain.internal-root-key.pem
mydomain.internal-root.pem
```

"mkcert" run:

```
❯ mkdir mkcert

❯ env CAROOT=mkcert mkcert \
    -cert-file mkcert/mydomain.internal-domain.pem \
    -key-file mkcert/mydomain.internal-domain-key.pem mydomain.internal
Created a new local CA 💥
Note: the local CA is not installed in the system trust store.
Note: the local CA is not installed in the Firefox and/or Chrome/Chromium trust store.
Note: the local CA is not installed in the Java trust store.
Run "mkcert -install" for certificates to be trusted automatically ⚠️

Created a new certificate valid for the following names 📜
 - "mydomain.internal"

The certificate is at "mkcert/mydomain.internal-domain.pem" and the key at "mkcert/mydomain.internal-domain-key.pem" ✅

It will expire on 15 July 2025 🗓


❯ tree -a mkcert
mkcert
├── mydomain.internal-domain-key.pem
├── mydomain.internal-domain.pem
├── rootCA-key.pem
└── rootCA.pem

0 directories, 4 files
```

Root certificate comparison:

```
❯ diff \
    <(openssl x509 -noout -text -certopt no_pubkey,no_sigdump -in mydomain.internal-root.pem) \
    <(openssl x509 -noout -text -certopt no_pubkey,no_sigdump -in mkcert/rootCA.pem)
5c5
<             4c:3e:c9:7f:3a:8f:d2:68:31:72:57:6b:8f:ec:1e:4b:8c:38:5a:d5
---
>             dc:1c:bd:ad:97:64:ac:d0:27:f0:46:4d:f5:f7:24:63
7c7
<         Issuer: CN = duxsco root CA for mydomain.internal
---
>         Issuer: O = mkcert development CA, OU = david@dex, CN = mkcert david@dex
9,11c9,11
<             Not Before: Apr 15 13:44:14 2023 GMT
<             Not After : May 19 13:44:14 2024 GMT
<         Subject: CN = duxsco root CA for mydomain.internal
---
>             Not Before: Apr 15 13:45:24 2023 GMT
>             Not After : Apr 15 13:45:24 2033 GMT
>         Subject: O = mkcert development CA, OU = david@dex, CN = mkcert david@dex
17,22d16
<             X509v3 Name Constraints: critical
<                 Permitted:
<                   DNS:mydomain.internal
<                 Excluded:
<                   DNS:.mydomain.internal
<
24c18
<                 CA:B1:2D:FE:5E:2B:60:5C:1F:9C:BB:56:E0:FD:8E:F2:EB:66:C8:D5
---
>                 25:91:65:BC:23:46:A2:EB:0A:6A:1C:7B:15:DF:F3:1C:F4:50:4A:51
```

Domain (leaf) certificate comparison:

```
❯ diff \
    <(openssl x509 -noout -text -certopt no_pubkey,no_sigdump -in mydomain.internal-domain.pem) \
    <(openssl x509 -noout -text -certopt no_pubkey,no_sigdump -in mkcert/mydomain.internal-domain.pem)
5c5
<             17:87:56:f7:7c:4a:1d:54:2a:ac:9a:e6:df:e2:e6:0c:bd:6d:5c:fc
---
>             e4:80:25:20:e4:64:ef:c7:af:d4:b0:e1:c0:8f:69:b6
7c7
<         Issuer: CN = duxsco root CA for mydomain.internal
---
>         Issuer: O = mkcert development CA, OU = david@dex, CN = mkcert david@dex
9,11c9,11
<             Not Before: Apr 15 13:44:15 2023 GMT
<             Not After : Apr 19 13:44:15 2024 GMT
<         Subject: CN = mydomain.internal
---
>             Not Before: Apr 15 13:45:24 2023 GMT
>             Not After : Jul 15 13:45:24 2025 GMT
>         Subject: O = mkcert development certificate, OU = david@dex
17,18d16
<             X509v3 Subject Alternative Name:
<                 DNS:mydomain.internal
20c18
<                 keyid:CA:B1:2D:FE:5E:2B:60:5C:1F:9C:BB:56:E0:FD:8E:F2:EB:66:C8:D5
---
>                 keyid:25:91:65:BC:23:46:A2:EB:0A:6A:1C:7B:15:DF:F3:1C:F4:50:4A:51
21a20,21
>             X509v3 Subject Alternative Name:
>                 DNS:mydomain.internal
```
