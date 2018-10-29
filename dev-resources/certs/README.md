# Re-creating the dev certificates

## Creating a certificate authority
We create a private key for our new CA:
`openssl genrsa -out ca.key 2048`
We can then use this key to create a certificate:
`openssl req -x509 -new -nodes -key ca.key -sha256 -days 1024 -out ca.pem`

## Creating the certificate for our server
We create the key:
`openssl genrsa -out server.key 2048`
Then we create a signing request:
`openssl req -new -key server.key -out server.csr`
Which we can sign using the CA, to get our server certificate:
`openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out server.crt -days 500 -sha256`

The server then needs the CA's cert (`ca.pem`), it's own cert (`server.pem`) and it's own private key (`server.key`).
