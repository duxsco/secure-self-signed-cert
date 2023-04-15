# secure-self-signed-cert

This script basically creates the same simple certificate chain as [mkcert](https://github.com/FiloSottile/mkcert), but with the [Name Constraints](https://www.openssl.org/docs/man1.1.1/man5/x509v3_config.html#Name-Constraints) restriction.

Thus, you have a root certificate for import in the webbrowser that is valid only for a single domain (leaf) certificate:

```
❯ openssl x509 -noout -in www.mydomain.internal-root.pem -ext nameConstraints
X509v3 Name Constraints: critical
    Permitted:
      DNS:mydomain.internal
    Excluded:
      DNS:.mydomain.internal

❯ echo Q | openssl s_client \
    -connect www.mydomain.internal:443 \
    -servername www.mydomain.internal 2>/dev/null | \
        openssl x509 -noout -subject -ext subjectAltName
subject=CN = www.mydomain.internal
X509v3 Subject Alternative Name:
    DNS:www.mydomain.internal, DNS:mydomain2.internal

❯ curl --cacert www.mydomain.internal-root.pem https://www.mydomain.internal
curl: (60) SSL certificate problem: excluded subtree violation
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

❯ curl --cacert www.mydomain.internal-root.pem https://mydomain2.internal
curl: (60) SSL certificate problem: excluded subtree violation
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
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
❯ diff -y --suppress-common-lines \
    <(openssl x509 -noout -text -in mydomain.internal-root.pem) \
    <(openssl x509 -noout -text -in mkcert/rootCA.pem)
            36:3d:f3:d4:33:8b:60:ae:ff:c7:f7:cd:75:a6:fd:ef:c |             55:c6:95:a7:c6:2c:5c:69:f7:96:ca:db:8d:ac:0b:2d
        Issuer: CN = duxsco root CA for mydomain.internal     |         Issuer: O = mkcert development CA, OU = david@dex, CN
            Not Before: Apr 15 02:36:37 2023 GMT              |             Not Before: Apr 15 02:38:06 2023 GMT
            Not After : May 19 02:36:37 2024 GMT              |             Not After : Apr 15 02:38:06 2033 GMT
        Subject: CN = duxsco root CA for mydomain.internal    |         Subject: O = mkcert development CA, OU = david@dex, C
                RSA Public-Key: (2048 bit)                    |                 RSA Public-Key: (3072 bit)
                    00:b8:41:75:47:05:46:a5:25:68:11:27:6d:6b |                     00:d8:51:1e:73:3c:ea:ab:53:70:b4:63:e8:a4
                    c2:3e:d2:92:ef:65:ad:d6:e5:ad:38:bc:40:ff |                     ed:32:12:a5:ed:04:f6:84:41:83:5f:de:d0:31
                    08:0d:97:35:5b:3d:78:70:7c:8f:2e:ba:d6:8f |                     51:30:87:1a:bb:d6:99:da:ed:8d:57:7d:76:1d
                    3b:f3:b5:72:dc:1e:dc:4b:33:b3:05:33:ec:63 |                     13:12:a1:25:81:ee:ef:45:64:3b:0b:41:70:ff
                    6d:fe:66:36:28:72:ea:99:2a:47:80:7e:6a:29 |                     7e:d4:37:f4:49:f4:a2:af:8c:dd:d4:de:f2:48
                    c8:94:d0:ba:eb:cc:fd:93:88:7e:77:99:d3:87 |                     e9:59:71:fc:f5:4d:22:94:e0:60:3d:d5:41:65
                    51:1c:8c:d0:24:c9:7f:a8:f2:a9:82:33:02:88 |                     20:00:72:0e:09:79:e5:e8:41:15:a1:72:ff:d4
                    fe:e7:5d:d4:ee:70:38:3e:e5:18:d8:0f:3c:dc |                     7a:c4:55:4f:95:15:30:6c:dc:00:12:6b:87:69
                    f1:57:7e:7e:7b:8c:54:01:82:4b:4d:93:67:c7 |                     c1:5c:30:42:2a:85:f5:c1:5a:37:66:8d:32:39
                    ac:7f:95:7f:76:34:ed:ab:9e:84:61:e9:c8:57 |                     09:f3:24:c1:dc:c7:d6:68:9b:2b:4d:9d:4b:0c
                    8f:c3:6a:d9:2a:aa:fe:d9:b5:3f:eb:a7:82:47 |                     d7:59:5c:4c:f9:ba:96:ec:c3:74:b9:a2:d3:5d
                    63:39:c5:cb:9b:35:4e:bf:90:fc:c6:28:2b:b8 |                     e9:03:64:ba:ae:80:31:1b:91:9f:11:ff:8f:f1
                    3f:5e:05:30:0b:91:d7:c9:70:20:47:ca:ff:f5 |                     c5:18:b4:55:74:48:df:53:ed:63:d1:d6:c7:eb
                    9e:b8:92:52:3f:bf:01:7d:f9:70:a1:d2:52:56 |                     51:c7:b9:4f:cf:f3:a6:37:36:e6:ca:b6:78:da
                    d7:94:b1:b3:26:ea:ac:67:4a:83:26:60:af:29 |                     fe:6b:f5:5c:03:1a:66:1e:4b:70:ca:ec:cb:fe
                    09:08:ee:ba:db:a0:ff:a0:68:0f:f9:0d:42:e1 |                     a6:48:5b:6c:44:88:35:98:4b:c9:13:99:17:22
                    c6:24:b8:31:22:1a:c3:44:c4:65:8b:44:91:d5 |                     ac:cb:02:d1:68:6d:92:70:85:46:3f:b1:32:10
                    d6:95                                     |                     fd:80:93:79:b1:1e:91:9e:cd:00:fb:50:65:a2
                                                              >                     5d:a3:4f:d9:27:ef:06:b2:72:63:f3:8f:08:c0
                                                              >                     d3:80:d6:77:6c:91:39:c5:c0:ea:89:a2:30:5e
                                                              >                     18:f7:c1:24:16:99:2c:a4:03:80:99:a9:a0:f9
                                                              >                     d8:e2:36:d6:1d:77:b6:0b:3d:e2:55:f9:84:73
                                                              >                     d9:73:27:dc:99:da:cd:45:51:58:3a:b8:71:26
                                                              >                     e6:0c:86:6b:a9:c7:c1:38:65:cd:0a:ba:50:30
                                                              >                     18:b9:69:f9:e8:04:6a:13:ed:c2:b9:ba:2c:06
                                                              >                     aa:7d:d7:94:2e:b1:73:e8:eb:ef
            X509v3 Name Constraints: critical                 <
                Permitted:                                    <
                  DNS:mydomain.internal                       <
                                                              <
                D9:C1:6C:9F:63:B4:66:FF:E7:03:AF:BA:F7:BD:53: |                 EF:6A:C6:D2:F5:E4:35:7A:02:54:E9:A8:AA:42:8E:
         7a:ad:07:bd:fc:f2:12:f8:d6:7d:dc:42:80:f4:3a:09:a5:7 |          04:51:cb:eb:e1:b1:78:93:4a:96:56:20:2a:6c:1d:4a:68:1
         bb:4e:67:18:a4:9a:f4:3c:fc:ea:82:82:19:8b:dd:39:41:c |          80:db:00:b9:7d:22:61:99:e3:21:27:11:8c:bc:bc:d5:1a:b
         3f:fe:05:5b:5c:3d:8b:9f:27:03:2c:f0:3f:91:33:1e:f1:c |          7c:62:c7:e6:a6:1f:38:be:78:1e:5b:2f:2d:f8:22:67:39:1
         08:38:07:6c:04:b3:12:64:b1:4d:c7:90:7a:ec:6f:1c:2c:5 |          69:76:33:c9:be:37:43:16:8f:cf:ca:63:50:e5:b1:89:c3:9
         e3:20:72:d8:6a:d0:80:c9:95:31:b1:b7:2f:7b:16:d0:db:2 |          56:fe:ca:15:ab:e8:a9:4b:52:be:5b:3c:f1:c4:33:08:db:9
         04:55:15:d3:17:9e:d0:30:8e:54:61:b6:32:06:d2:3d:0a:5 |          78:62:67:3d:7a:1b:8d:8a:aa:a9:ef:a0:09:77:80:21:5e:f
         94:dc:b3:45:30:e2:ec:66:2f:ea:22:9c:14:58:75:5e:6e:a |          e4:1b:07:63:e2:04:2f:9f:46:7b:5f:d9:af:f8:51:4f:68:1
         35:6a:cb:36:80:98:a1:39:69:f8:cc:de:74:35:d7:57:73:2 |          b6:cc:25:fb:a9:07:21:c1:c1:4c:2c:7a:ac:42:f8:e9:bb:3
         a1:87:21:de:14:d5:01:31:46:17:91:13:07:21:1c:77:23:0 |          a5:50:32:cc:9a:17:e7:8c:fe:5e:93:8b:a4:3f:93:35:c7:1
         4d:e7:d0:31:40:de:73:99:96:d0:d7:b5:76:71:d4:07:51:c |          59:49:46:63:1f:a6:35:e5:3e:c4:2b:69:94:c8:95:19:c8:6
         10:1b:19:a0:25:9d:20:75:d8:39:26:5a:63:19:a4:bc:c2:e |          e4:72:f4:14:c6:73:f6:5f:83:16:9a:22:b0:00:1b:96:86:2
         e4:07:83:76:14:d9:3f:11:b6:d5:3b:58:b8:53:ea:86:98:9 |          d8:48:41:ba:8d:a5:c3:45:3c:56:ef:82:91:6a:2d:a1:12:1
         28:3e:34:ca:f6:a8:60:cb:11:98:27:84:d6:59:8d:7e:e4:a |          62:0e:aa:cc:f8:11:c4:2b:2b:6c:60:b0:8b:dc:4d:d5:83:9
         1d:ca:c2:5f:49:26:39:d7:aa:4d:2d:21:dc:00:d8:54:e5:e |          8a:e4:67:26:2b:66:ea:6f:55:2f:d7:5a:13:78:20:d4:32:5
         2f:c5:e4:f0                                          |          e7:03:fe:97:6f:e0:d3:6c:b8:02:ae:ce:ad:0a:fd:c9:1e:3
                                                              >          d7:94:17:9e:25:0e:af:54:59:1a:13:a9:3e:29:10:59:a4:1
                                                              >          f6:05:23:d0:a9:57:28:ce:30:4c:60:09:c0:db:25:e6:6f:c
                                                              >          80:b6:cf:9b:f0:5e:56:73:59:9b:28:67:a0:62:99:2a:92:d
                                                              >          4f:dc:3e:e3:a4:f2:c1:fb:b9:81:90:d0:3a:25:f6:90:5d:8
                                                              >          d7:2a:43:50:db:8a:97:45:a2:22:81:22:67:43:0f:22:54:9
                                                              >          9e:0b:80:6c:8e:68:31:1d:4c:ee:67:5e:57:b5:c3:58:b1:1
                                                              >          ee:68:df:a2:fb:16
```

Domain (leaf) certificate comparison:

```
❯ diff -y --suppress-common-lines \
    <(openssl x509 -noout -text -in mydomain.internal-domain.pem) \
    <(openssl x509 -noout -text -in mkcert/mydomain.internal-domain.pem)
            6b:c5:93:20:11:a0:a3:17:54:f9:55:10:07:81:4c:40:6 |             ac:e3:b6:77:d3:78:17:12:f0:13:d1:63:2a:94:f3:76
        Issuer: CN = duxsco root CA for mydomain.internal     |         Issuer: O = mkcert development CA, OU = david@dex, CN
            Not Before: Apr 15 02:36:37 2023 GMT              |             Not Before: Apr 15 02:38:07 2023 GMT
            Not After : Apr 19 02:36:37 2024 GMT              |             Not After : Jul 15 02:38:07 2025 GMT
        Subject: CN = mydomain.internal                       |         Subject: O = mkcert development certificate, OU = dav
                    00:b1:04:f1:2e:52:0b:13:75:9c:26:1d:fc:bc |                     00:c3:89:52:e1:0e:1c:b4:4b:72:77:f5:ba:19
                    50:a8:55:1d:f8:e7:7a:84:03:cc:1f:ab:24:50 |                     95:40:57:1a:1c:d9:91:9a:2c:24:bc:cb:62:b4
                    25:ac:aa:0d:0d:6f:9b:09:bc:16:6d:90:dd:1c |                     34:5f:02:7f:f9:41:b5:29:d6:b5:e2:97:47:79
                    12:e7:a8:98:de:f8:8d:c6:d5:d3:30:30:e9:32 |                     ab:5e:72:9a:6b:1e:2f:04:7d:4d:d2:b7:bf:b9
                    06:66:a2:88:33:99:17:97:94:7c:75:d8:78:76 |                     25:07:56:fa:7c:57:54:7c:53:4b:2a:a5:6c:9b
                    19:b8:a1:23:d3:d1:7d:36:98:3a:fe:c1:e7:e6 |                     63:3c:41:cf:9e:60:cc:8a:78:aa:ed:7d:a6:03
                    1e:d7:78:31:3b:41:86:4c:d5:5e:f2:5e:ce:fb |                     9c:e9:9e:24:50:00:a2:9c:e5:36:41:e9:f0:8b
                    3c:00:53:3f:52:2c:87:95:d0:09:56:bf:2d:ae |                     b1:45:25:ab:75:6a:df:bc:89:b2:2e:e4:5d:87
                    0f:78:1a:f7:7b:0d:d0:ad:6b:75:15:dc:66:d1 |                     0a:77:11:5d:51:16:e1:03:6f:d0:d0:6c:a2:a4
                    f9:16:66:2a:91:78:62:da:45:ae:31:5d:46:9f |                     87:7d:44:0c:e1:62:22:c5:31:4e:33:1e:d1:ff
                    94:60:76:0d:9f:f4:18:b2:f3:f9:cf:d6:30:51 |                     a2:4f:1f:f3:ab:cd:b2:b1:c8:41:47:be:9f:e9
                    6f:04:d2:e6:63:34:cb:f2:db:c5:ef:8c:24:bc |                     8f:3e:06:eb:2c:81:43:f0:c0:ff:04:e0:07:86
                    ff:85:7c:1c:ab:9b:81:f2:46:15:94:dc:8c:ae |                     0f:88:4e:98:9b:6e:3b:59:6e:68:6e:1a:dc:e6
                    21:fc:7a:85:2f:11:00:69:6c:07:88:4f:b2:98 |                     fc:83:57:59:1f:65:84:50:a3:57:1d:36:84:68
                    13:91:51:68:6d:97:56:58:27:0f:7b:09:d4:cb |                     8d:24:33:a6:b5:6b:bb:13:be:00:a5:54:55:7e
                    4e:a4:13:8b:ec:f9:62:df:64:3d:1a:e5:2e:54 |                     0b:c7:44:35:c9:ac:7d:ea:36:f3:9a:af:32:a4
                    79:bc:f4:d9:3e:70:ad:1e:ac:74:ea:7c:f9:f2 |                     5a:65:80:7d:e8:f8:a0:06:83:22:3e:24:2d:01
                    4d:41                                     |                     90:8f
            X509v3 Subject Alternative Name:                  <
                DNS:mydomain.internal                         <
                keyid:D9:C1:6C:9F:63:B4:66:FF:E7:03:AF:BA:F7: |                 keyid:EF:6A:C6:D2:F5:E4:35:7A:02:54:E9:A8:AA:
                                                              >             X509v3 Subject Alternative Name: 
                                                              >                 DNS:mydomain.internal
         a3:0a:ac:3d:38:79:fc:71:32:b5:6e:16:83:62:c1:35:77:a |          4d:52:0f:59:0e:39:0e:6f:93:4e:79:f8:27:81:f4:83:a2:e
         fa:12:ee:51:d3:8d:60:40:3c:dc:fc:35:7a:3c:3f:97:08:1 |          cc:99:16:50:50:38:e9:28:b4:90:8a:f2:df:41:12:f0:14:8
         54:94:42:1c:e0:a3:92:c2:57:9e:3b:88:f2:7a:eb:d7:09:8 |          48:3c:1e:d1:5b:e4:0a:dc:7e:9e:5d:c0:e3:37:3a:24:d8:8
         61:e7:38:de:e0:f7:34:ba:fd:30:6d:d0:8e:b0:2f:31:9e:f |          89:9e:32:ec:ef:b5:b4:01:2a:38:aa:5d:05:e6:d2:29:84:e
         8b:3b:1c:7d:54:95:e3:a9:3b:00:f9:b7:c0:60:81:51:48:6 |          4a:92:bf:f5:04:da:f9:55:19:b6:d8:f8:89:c9:ec:5a:10:3
         9b:86:ee:55:df:0e:a7:50:b2:34:8a:93:cb:62:38:52:41:b |          bd:8e:cf:bd:89:fb:b7:19:dc:fa:c7:27:47:c9:e5:c3:9d:e
         9b:f5:fe:81:0f:a5:81:b5:1f:ab:d3:3a:98:70:83:80:70:9 |          e4:33:2d:10:57:55:6a:d5:2f:88:8d:7b:1b:89:bd:3a:1e:5
         f7:0a:8b:76:b4:0d:d2:e4:d4:3a:98:13:29:b7:00:16:ce:0 |          de:d6:d7:43:cd:ca:22:e1:70:95:72:db:a0:b6:d3:fe:7f:5
         87:e9:56:49:52:6c:4b:5c:2d:17:d7:4e:58:8f:35:0b:6f:4 |          d4:32:86:36:0a:60:1b:69:e7:a3:7e:ff:df:65:5d:24:fe:3
         55:28:30:ac:e8:0f:6c:db:28:4d:10:56:eb:7b:2e:de:29:5 |          4a:4f:08:bd:a7:f9:13:32:d7:e0:dc:43:30:2f:8f:d0:d9:5
         69:18:99:8f:52:6c:20:f7:02:81:37:1d:9a:c8:bd:58:49:7 |          c7:19:c7:d4:cb:83:40:7d:17:ef:8a:35:08:79:f8:2f:66:8
         da:4c:ce:cb:2d:91:51:b4:1d:2f:0c:d6:ba:76:80:2c:a2:a |          59:05:12:d7:b0:65:63:6f:40:08:ce:0b:7d:c7:4f:aa:ba:4
         1b:ce:9e:b5:fb:66:91:67:18:a0:3c:70:b3:66:bb:91:71:f |          66:bf:c1:3c:c3:21:bc:3c:7b:73:4d:0b:e4:70:13:a3:6c:c
         20:71:06:42:a0:21:57:3e:6a:0e:f3:23:79:13:d7:ba:1c:a |          ff:c6:77:21:20:8c:02:4f:0b:d7:bd:f3:29:90:83:5f:0d:d
         9a:3a:dc:1c                                          |          8f:9c:5a:72:7e:5b:9d:9f:6e:4b:87:db:b9:84:3e:86:4b:2
                                                              >          06:44:9e:9f:3a:18:84:3f:98:02:ec:4e:92:46:d5:1a:6f:a
                                                              >          ad:6c:d0:f4:c8:64:2b:fe:ad:b9:5f:a8:e7:c9:ef:b3:a0:a
                                                              >          c4:d3:ac:71:d6:0c:5c:6b:01:5f:47:e6:ae:ac:22:97:fc:4
                                                              >          40:5e:3f:58:39:85:e2:14:2a:b0:cd:b1:a8:11:e9:47:73:0
                                                              >          1a:d1:ef:ef:38:f1:ef:3e:51:da:f1:6e:69:e1:6f:d7:7c:2
                                                              >          f0:42:05:02:77:3d:c0:7e:64:7c:26:be:05:4c:93:b1:5b:1
                                                              >          a1:8e:f0:da:1b:d6
```
