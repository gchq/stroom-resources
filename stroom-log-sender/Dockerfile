#**********************************************************************
# Copyright 2018 Crown Copyright
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
#**********************************************************************


# ~~~ send logs scripts stage ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Intermediate build stage to grab all the send logs scripts
# later copy them all in one go to reduce the number of layers
# Have to use alpine rather than scratch so we can chmod
FROM alpine:3.8 as send-logs-scripts-stage
WORKDIR /scripts

ARG SEND_TO_STROOM_VERSION=send-to-stroom-v2.0

ADD https://raw.githubusercontent.com/gchq/stroom-clients/${SEND_TO_STROOM_VERSION}/bash/send_to_stroom.sh .
ADD https://raw.githubusercontent.com/gchq/stroom-clients/${SEND_TO_STROOM_VERSION}/bash/send_to_stroom_args.sh .

RUN chmod u+x ./*.sh
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Final build stage

FROM alpine:3.8

#This is the root dir for all our files/scripts
WORKDIR /stroom-log-sender

# This is where the crontab file is placed to be loaded into cron on each boot
VOLUME /stroom-log-sender/config/

# This is where the various certificates and keys are placed
VOLUME /stroom-log-sender/certs/

# run entrypoint script inside tini for better unix process handling, 
# see https://github.com/krallin/tini/issues/8
ENTRYPOINT ["/sbin/tini", "--", "/stroom-log-sender/docker-entrypoint.sh"]

# bash required for send_to_stroom.sh
# coreutils required for 'date' command to output millis
# curl required for sending logs
# tini required for process control in the entrypoint
# procps needed for a richer 'ps' command as used in send_to_stroom.sh
# Create a user with no home and no shell
# The log-volumes dir is where we expect volumes to be mounted 
RUN echo "http_proxy: $http_proxy" && \
    echo "https_proxy: $https_proxy" && \
    apk add --no-cache \
        bash \
        coreutils \
        curl \
        procps \
        tini && \
    addgroup -g 1000 -S sender && \
    adduser -u 1000 -S -s /bin/false -D -G sender sender && \
    mkdir -p /stroom-log-sender && \
    mkdir -p /stroom-log-sender/config && \
    mkdir -p /stroom-log-sender/certs && \
    mkdir -p /stroom-log-sender/log-volumes && \
    chown -R sender:sender /stroom-log-sender

# Copy in all the send logs scripts downloaded in the intermediate build stage
COPY --chown=sender:sender --from=send-logs-scripts-stage /scripts /stroom-log-sender

# Copy in the scripts for running the container
COPY --chown=sender:sender docker-entrypoint.sh /stroom-log-sender/

# Label the image so we can see what commit/tag it came from
ARG GIT_COMMIT=unspecified
ARG GIT_TAG=unspecified
LABEL \
    git_commit="$GIT_COMMIT" \
    git_tag="$GIT_TAG"
