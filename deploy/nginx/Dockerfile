# Copyright 2017 Crown Copyright
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM nginx:1.13.8-alpine

#Copy our templated conf file in ready for substitution of the host name variables
COPY ./nginx.conf.template /tmp/

#Copy in our dev certificates
COPY ./certs/* /etc/nginx/certs/

#Add bash in case we want to shell onto the container
RUN apk add --no-cache bash

#We need to create nginx.conf from nginx.conf.template, substituting NGINX_ADVERTISED_HOST from its environment variable
#As nginx.conf contains stiff like '$proxy_add_x_forwarded_for', we need to give envsubst a specific list of variables
#to substitute, else it will breake the config
CMD [ "/bin/bash", "-c", "envsubst '${NGINX_ADVERTISED_HOST}' < /tmp/nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"]
