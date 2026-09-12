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

FROM nginx:1.31.5-alpine3.24@sha256:72ba65eb42c10344912a84ff42408db7d34f2feb642204570ab8fc5ffd29f1d3

# This is the root dir for all our files/scripts
WORKDIR /stroom-nginx

# All certs/keys required for SSL
VOLUME [ "/stroom-nginx/certs" ]

# The location of the template configuration file to use as the base for generating
# the actual nginx.conf file on container start and the cron configuration
VOLUME [ "/stroom-nginx/config" ]

# The location of any html served by nginx
VOLUME [ "/stroom-nginx/html" ]

# Volume for file based logs for collection by stroom-log-sender
# Nginx will also log to /var/log/nginx/access.log|error.log which are sym links
# to stdout|stderr so 'docker logs' can see them.
VOLUME [ "/stroom-nginx/logs" ]

# Volume to hold any state/config for logrotate
VOLUME [ "/stroom-nginx/logrotate" ]

# Run the entrypoint inside tini and forward signals to its process group so both
# nginx and the log rotation scheduler stop cleanly.
ENTRYPOINT ["/sbin/tini", "-g", "--", "/stroom-nginx/docker-entrypoint.sh"]

CMD ["sh", "-c", "nginx -g 'daemon off;'"]

# bash for the entrypoint script
# logrotate and supercronic for rotation of the file based access/app logs
# libcap allows nginx to bind ports 80/443 without running as root
# tini required for process control in the entrypoint
# remove the default nginx html path to avoid confusion
RUN \
    apk add --no-cache \
        bash \
        libcap \
        logrotate \
        supercronic \
        tini && \
    mkdir -p /stroom-nginx/logs && \
    mkdir -p /stroom-nginx/logrotate && \
    mkdir -p /stroom-nginx/certs && \
    mkdir -p /stroom-nginx/config && \
    mkdir -p /stroom-nginx/html && \
    setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx && \
    chown -R nginx:nginx \
        /etc/nginx \
        /run \
        /stroom-nginx \
        /var/cache/nginx \
        /var/log/nginx && \
    rm -rf /usr/share/nginx/html

# Copy entrypoint and related shell scripts
COPY *.sh /stroom-nginx/

USER nginx

# Label the image so we can see what commit/tag it came from
ARG GIT_COMMIT=unspecified
ARG GIT_TAG=unspecified
LABEL \
    git_commit="$GIT_COMMIT" \
    git_tag="$GIT_TAG"
# Pass the GIT_TAG through to the running container
# This should not be set at container run time
ENV GIT_TAG=$GIT_TAG
