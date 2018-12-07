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

# This is the root dir for all our files/scripts
WORKDIR /stroom-nginx

# All certs/keys required for SSL
VOLUME [ "/stroom-nginx/certs" ]

# The location of the template configuration file to use as the base for generating
# the actual nginx.conf file on container start and the cron configuration
VOLUME [ "/stroom-nginx/config" ]

# Volume for file based logs for collection by stroom-log-sender
# Nginx will also log to /var/log/nginx/access.log|error.log which are sym links
# to stdout|stderr so 'docker logs' can see them.
VOLUME [ "/stroom-nginx/logs" ]

# Volume to hold any state/config for logrotate
VOLUME [ "/stroom-nginx/logrotate" ]

# run entrypoint script inside tini for better unix process handling, 
# see https://github.com/krallin/tini/issues/8
ENTRYPOINT ["/sbin/tini", "--", "/stroom-nginx/docker-entrypoint.sh"]

CMD ["sh", "-c", "nginx -g 'daemon off;'"]

# logrotate for rotation of the file based access/app logs
# tini required for process control in the entrypoint
RUN \
    apk add --no-cache \
        logrotate \
        tini && \
    mkdir -p /stroom-nginx/logs && \
    mkdir -p /stroom-nginx/logrotate && \
    mkdir -p /stroom-nginx/certs && \
    mkdir -p /stroom-nginx/config

# Copy entrypoint and related shell scripts
COPY *.sh /stroom-nginx/

# Label the image so we can see what commit/tag it came from
ARG GIT_COMMIT=unspecified
ARG GIT_TAG=unspecified
LABEL \
    git_commit="$GIT_COMMIT" \
    git_tag="$GIT_TAG"
# Pass the GIT_TAG through to the running container
# This should not be set at container run time
ENV GIT_TAG=$GIT_TAG
