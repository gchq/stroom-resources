FROM nginx:alpine

RUN apk add --no-cache bash 

COPY ./index.html /usr/share/nginx/html/index.html
COPY ./nginx.conf /etc/nginx/nginx.conf

COPY ./certs/server.pem.crt /etc/nginx/certs/server.pem.crt
COPY ./certs/server.unencrypted.key /etc/nginx/certs/server.unencrypted.key
COPY ./certs/ca.pem.crt /etc/nginx/certs/ca.pem.crt
