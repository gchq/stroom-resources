# Dev certs
These certs may be used to test SSL termination in NGINX.

## Using HTTPie to test

When using self-signed certificates, like we are here, HTTPie needs to be passed `--verify=no`, otherwise it'll fail. For example:

```
http --cert=client.pem.crt --cert-key=client.unencrypted.key https://localhost/login --verify=no

```

Conversely, if NGINX doesn't specify `ssl_verify_client on;`, then it won't extract the DN from the client's certificate.

## References

[How to generate client certificates](http://nategood.com/client-side-certificate-authentication-in-ngi)

[How to remove a pass phrase from a certificate](http://www.insivia.com/removing-a-pass-phrase-from-a-ssl-certificate/)

[Useful OpenSSL commands](https://www.sslshopper.com/article-most-common-openssl-commands.html)

[More useful OpenSSL commands](https://support.asperasoft.com/hc/en-us/articles/216128468-OpenSSL-commands-to-check-and-verify-your-SSL-certificate-key-and-CSR)

[Converting PEM to DER](https://support.ssl.com/Knowledgebase/Article/View/19/0/der-vs-crt-vs-cer-vs-pem-certificates-and-how-to-convert-them)