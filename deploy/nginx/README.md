# NGINX for Stroom

This is a Docker configuration of NGINX for Stroom.
 
The primary purpose of this setup is reverse proxying to our applications. It contains the addresses of these applications. 

## Deploying
1. Change the IP addresses in `nginx.conf`
2. Build and run the docker in the usual way.

## Certificates
The certificates in `./certs` will need to be replaced with real self-signed certificates and keys.