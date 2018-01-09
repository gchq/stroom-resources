FROM nginx:1.13.8-alpine

#Copy our templated conf file in ready for substitution of the host name variables
COPY ./nginx.conf.template /tmp/

#Copy in our dev certificates
COPY ./certs/* /etc/nginx/certs/

#Add bash in case we want to shell onto the container
RUN apk add --no-cache \ 
        bash

#We need to create nginx.conf from nginx.conf.template, substituting NGINX_ADVERTISED_HOST from its environment variable
#As nginx.conf contains stiff like '$proxy_add_x_forwarded_for', we need to give envsubst a specific list of variables
#to substitute, else it will breake the config
CMD [ "/bin/bash", "-c", "envsubst '${NGINX_ADVERTISED_HOST}' < /tmp/nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"]
