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

# ~~~ Common based stage ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM redhat/ubi10-minimal:10.3-1795196920@sha256:d63890a635f8f19177bce1775f74f587a47f4456844f1392456c4e3673a48753 AS common_base_stage
# Curl is needed by two later stages, so install it once
RUN \
  microdnf install -y --nodocs \
    curl; \
  microdnf clean all
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~





# ~~~ Download supercronic stage ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM common_base_stage AS download_supercronic_stage

WORKDIR /supercronic

ENV \
  SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.51/supercronic-linux-amd64 \
  SUPERCRONIC_SHA1SUM=1692066e350a88ff4d7d6474fe3c7a6c41ec5e89 \
  SUPERCRONIC=supercronic-linux-amd64

RUN \
  echo "Downloading supercronic from ${SUPERCRONIC_URL}"; \
  curl -fsSLO "$SUPERCRONIC_URL"; \
  # The following string must have two spaces between the hash and the filename \
  # else sha1sum check won't work \
  echo "Verifying sha1 hash ${SUPERCRONIC_SHA1SUM}"; \
  echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c -; \
  chmod +x "$SUPERCRONIC"; \
  # Create a symlink with a simpler name \
  ln -s "${SUPERCRONIC}" supercronic; \
  echo "Supercronic download stage complete"
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~






# ~~~ send logs scripts stage ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Intermediate build stage to grab all the send logs scripts
# later copy them all in one go to reduce the number of layers
# Have to use a real image rather than scratch so we can chmod
FROM common_base_stage AS send_logs_scripts_stage

WORKDIR /scripts

ARG \
  SEND_TO_STROOM_VERSION=send-to-stroom-v3.4.0

ADD \
  --chmod=770 \
  https://github.com/gchq/stroom-clients/releases/download/${SEND_TO_STROOM_VERSION}/send_to_stroom.sh \
  ./
ADD \
  --chmod=770 \
  https://github.com/gchq/stroom-clients/releases/download/${SEND_TO_STROOM_VERSION}/send_to_stroom_args.sh \
  ./
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~






# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Final build stage
FROM common_base_stage AS main_stage

ARG USER_NAME=sender
ARG USER_ID=1000
# The root group which should be GID 0
# This is to allow OKD/Openshift to run as any user it likes that is also a member of GID 0
ARG GROUP_NAME=root
ARG GROUP_ID=0

# Set some useful defualts
# The log-sender script to run
ENV LOG_SENDER_SCRIPT="/stroom-log-sender/send_to_stroom.sh"
# The root path of all the logs, can be used in the crontab.txt file
ENV LOGS_DIR="/stroom-log-sender/log-volumes"
# The environment, e.g. DEV/REF/OPS/etc.
ENV ENVIRONMENT="DEV"
# The maximum random delay in secs to wait to balance network load
ENV MAX_DELAY_SECS="15"
# Set the user ID into env so entrypoint can see them
ENV USER_ID=$USER_ID
ENV GROUP_ID=$GROUP_ID

#This is the root dir for all our files/scripts
WORKDIR /stroom-log-sender

ENTRYPOINT [ "/stroom-log-sender/docker-entrypoint.sh" ]

# Start supercronic with our crontab file
# -quiet - Suppress informational log messages; only warnings and errors are logged.
# -passthrough - Pass job output through without wrapping it in supercronic log entries.
# -split-logs - Route debug and info level logs to stdout.
CMD [ \
  "/usr/local/bin/supercronic", \
  "-quiet", \
  "-passthrough-logs", \
  "-split-logs", \
  "/stroom-log-sender/config/crontab.txt" ]

# bash required for send_to_stroom.sh
# curl is already in common_base_stage
# gettext needed for 'envsubst' using in the entrypoint script
# procps-ng needed for a richer 'ps' command as used in send_to_stroom.sh
# util-linux provides setpriv to drop down to a non-root user if the container is run as root
# gzip needed for compressing data sent over curl
# Create a user with no home and no shell
# The log-volumes dir is where we expect volumes to be mounted
RUN \
    set -eu; \
    echo "http_proxy: ${http_proxy:-}"; \
    echo "https_proxy: ${https_proxy:-}"; \
    echo "USER_ID: ${USER_ID:-}"; \
    echo "GROUP_ID: ${GROUP_ID:-}"; \
    microdnf install -y --nodocs \
        bash \
        gettext \
        gzip \
        procps-ng \
        util-linux; \
    # Snapshot all current installed packages so we can remove any new ones later \
    rpm -qa --queryformat "%{NAME}\n" | sort > /tmp/current_pkgs; \
    # Needed for groupadd/useradd \
    microdnf install -y --nodocs \
        shadow-utils; \
    if ! getent group "${GROUP_NAME}" >/dev/null 2>&1; then \
        groupadd \
            --gid "${GROUP_ID}" \
            --system "${GROUP_NAME}"; \
    fi; \
    useradd \
        --uid ${USER_ID} \
        --system \
        --gid ${GROUP_ID} \
        --shell /sbin/nologin \
        --no-create-home ${USER_NAME}; \
    # shadow-utils was only needed for groupadd/useradd, so now can be removed \
    # along with any deps it pulled in \
    rpm -qa --queryformat "%{NAME}\n" | sort > /tmp/new_pkgs; \
    # Get a list of all added packages then remove them if there are any \
    added_pkgs="$(comm -13 /tmp/current_pkgs /tmp/new_pkgs)"; \
    rm /tmp/current_pkgs /tmp/new_pkgs; \
    echo "[${added_pkgs}]"; \
    [[ -n "${added_pkgs}" ]] \
        && microdnf remove -y "${added_pkgs}" ; \
    microdnf clean all; \
    mkdir -p /stroom-log-sender \
      /stroom-log-sender/config \
      /stroom-log-sender/certs \
      /stroom-log-sender/log-volumes; \
    chown -R "$USER_ID:$GROUP_ID" /stroom-log-sender; \
    chmod -R 770 /stroom-log-sender

# Copy in all the send logs scripts downloaded in the intermediate build stage
COPY \
  --from=send_logs_scripts_stage \
  --chown=$USER_ID:$GROUP_ID \
  --chmod=770 \
  /scripts \
  /stroom-log-sender

# Copy in the supercronic binary downloaded in the intermediate build stage
COPY \
  --from=download_supercronic_stage \
  --chmod=770 \
  /supercronic \
  /usr/local/bin/

# Copy in the scripts for running the container
COPY \
  --chown=$USER_ID:$GROUP_ID \
  --chmod=770 \
  docker-entrypoint.sh \
  /stroom-log-sender/

# Intentiaonally done near the end because they will often change on each build
ARG GIT_COMMIT=unspecified
ARG GIT_TAG=unspecified

# Pass the GIT_TAG through to the running container
# This should not be set at container run time
ENV GIT_TAG=$GIT_TAG

# Label the image so we can see what commit/tag it came from
LABEL git_commit="$GIT_COMMIT"
LABEL git_tag="$GIT_TAG"

# config is where the crontab file is placed to be loaded into cron on each boot
VOLUME /stroom-log-sender/config/
# certs is where the various certificates and keys are placed
VOLUME /stroom-log-sender/certs/

# Run as our non-root user
USER "$USER_ID"
