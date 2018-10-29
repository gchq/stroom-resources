# Re-creating the dev certificates

## Creating a certificate authority

We create a private key for our new CA:
`openssl genrsa -out ca.unencrypted.key 2048`

We can then use this key to create a certificate. This asks for information about your organisation, which you can make up or just accept the defaults:
`openssl req -x509 -new -nodes -key ca.unencrypted.key -sha256 -days 99999 -out ca.pem.crt`

We can then optionally create a Java truststore (for use with DropWizard) from the PEM format CA certificate:
`keytool -noprompt -keystore ca.jks -importcert -alias ca -file ca.pem.crt -deststoretype JKS -storepass password`

## Creating the certificate for our server

We create the key:
`openssl genrsa -out server.unencrypted.key 2048`

Then we create a signing request. This asks for information about your organisation, which you can make up or just accept the defaults:
`openssl req -new -key server.unencrypted.key -out server.csr`

Which we can sign using the CA, to get our server certificate: 
`openssl x509 -req -in server.csr -CA ca.pem.crt -CAkey ca.unencrypted.key -CAcreateserial -out server.pem.crt -days 99999 -sha256`

The server then needs the CA's cert (`ca.pem.crt`), it's own cert (`server.pem.crt`) and it's own private key (`server.unencrypted.key`).

We can optionally create a Java keystore (for use with DropWizard) from the PEM format certificate and private key (going via a PKCS12 file):
`openssl pkcs12 -export -in server.pem.crt -inkey server.unencrypted.key -out server.p12 -name server -CAfile ca.pem.crt -caname root -passout pass:password`

`keytool -importkeystore -deststorepass password -destkeypass password -destkeystore server.jks -deststoretype JKS -srckeystore server.p12 -srcstoretype PKCS12 -srcstorepass password -alias server`
