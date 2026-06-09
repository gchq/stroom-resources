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

ARG BASE_IMAGE="alpine:3.23"




# ~~~ Download supercronic stage ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM ${BASE_IMAGE} AS download-supercronic-stage
WORKDIR /supercronic

ENV \
  SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.46/supercronic-linux-amd64 \
  SUPERCRONIC_SHA1SUM=5bcefed628e32adc08e32634db2d10e9230dbca0 \
  SUPERCRONIC=supercronic-linux-amd64

RUN \
  # tini required for process control in the entrypoint
  apk add --no-cache \
    curl \
    && \
  echo "Downloading supercronic from ${SUPERCRONIC_URL}" && \
  curl -fsSLO "$SUPERCRONIC_URL" && \
  # The following string must have two spaces between the hash and the filename
  # else sha1sum check won't work
  echo "Verifying sha1 hash ${SUPERCRONIC_SHA1SUM}" && \
  echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - && \
  chmod +x "$SUPERCRONIC" && \
  # Create a symlink with a simpler name
  ln -s "${SUPERCRONIC}" supercronic && \
  echo "Supercronic download stage complete"
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



# ~~~ send logs scripts stage ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Intermediate build stage to grab all the send logs scripts
# later copy them all in one go to reduce the number of layers
# Have to use alpine rather than scratch so we can chmod
FROM ${BASE_IMAGE} AS send-logs-scripts-stage
WORKDIR /scripts

ARG SEND_TO_STROOM_VERSION=send-to-stroom-v3.4.0

ADD https://github.com/gchq/stroom-clients/releases/download/${SEND_TO_STROOM_VERSION}/send_to_stroom.sh .
ADD https://github.com/gchq/stroom-clients/releases/download/${SEND_TO_STROOM_VERSION}/send_to_stroom_args.sh .

RUN chmod u+x ./*.sh
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Final build stage

FROM ${BASE_IMAGE} AS main-stage

# Set some useful defualts
ENV \
  # The log-sender script to run
  LOG_SENDER_SCRIPT="/stroom-log-sender/send_to_stroom.sh" \
  # The root path of all the logs, can be used in the crontab.txt file
  LOGS_DIR="/stroom-log-sender/log-volumes" \
  # The environment, e.g. DEV/REF/OPS/etc.
  ENVIRONMENT="DEV" \
  # The maximum random delay in secs to wait to balance network load
  MAX_DELAY_SECS="15" \
  USER_NAME=sender \
  USER_ID=1000 \
  # The root group which should be GID 0
  # This is to allow OKD/Openshift to run as any user it likes that is also a member of GID 0
  GROUP_NAME=root \
  GROUP_ID=0

#This is the root dir for all our files/scripts
WORKDIR /stroom-log-sender

# This is where the crontab file is placed to be loaded into cron on each boot
VOLUME /stroom-log-sender/config/

# This is where the various certificates and keys are placed
VOLUME /stroom-log-sender/certs/

# run entrypoint script inside tini for better unix process handling, 
# see https://github.com/krallin/tini/issues/8
ENTRYPOINT ["/sbin/tini", "--", "/stroom-log-sender/docker-entrypoint.sh"]

# Start supercronic with our crontab file
# -split-logs to route debug and info level logs to stdout.
CMD [ \
  "/usr/local/bin/supercronic", \
  "-quiet", \
  "-passthrough-logs", \
  "-split-logs", \
  "/stroom-log-sender/config/crontab.txt" ]

# bash required for send_to_stroom.sh
# coreutils required for 'date' command to output millis
# curl required for sending logs
# gettext needed for 'envsubst' using in the entrypoint script
# procps needed for a richer 'ps' command as used in send_to_stroom.sh
# tini required for process control in the entrypoint
# Create a user with no home and no shell
# The log-volumes dir is where we expect volumes to be mounted 
RUN echo "http_proxy: $http_proxy" && \
    echo "https_proxy: $https_proxy" && \
    apk add --no-cache \
        bash \
        coreutils \
        curl \
        gettext \
        procps \
        tini && \
    adduser \
      --system \
      --shell /bin/false \
      --disabled-password \
      --ingroup "$GROUP_NAME" \
      --no-create-home \
      --uid "$USER_ID" \
      "$USER_NAME" && \
    mkdir -p /stroom-log-sender && \
    mkdir -p /stroom-log-sender/config && \
    mkdir -p /stroom-log-sender/certs && \
    mkdir -p /stroom-log-sender/log-volumes && \
    chown -R "$USER_ID:$GROUP_ID" /stroom-log-sender

# Copy in all the send logs scripts downloaded in the intermediate build stage
COPY \
  --chown=$USER_ID:$GROUP_ID \
  --from=send-logs-scripts-stage \
  /scripts \
  /stroom-log-sender

# Copy in the supercronic binary downloaded in the intermediate build stage
COPY --from=download-supercronic-stage /supercronic /usr/local/bin

# Copy in the scripts for running the container
COPY \
  --chown=$USER_ID:$GROUP_ID \
  docker-entrypoint.sh \
  /stroom-log-sender/

# Give the group the same perms as the user so any user with GID 0 can run proxy in
# the same way as UID 1000
RUN chmod -R g=u /stroom-log-sender

# Label the image so we can see what commit/tag it came from
ARG GIT_COMMIT=unspecified
ARG GIT_TAG=unspecified
LABEL \
    git_commit="$GIT_COMMIT" \
    git_tag="$GIT_TAG"

# Run as our non-root user
USER "$USER_ID"
