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
FROM rust:1.61-slim-bullseye as send-logs-scripts-stage
WORKDIR /scripts

ARG SEND_TO_STROOM_VERSION=send-to-stroom-v3.1.0

ADD https://github.com/gchq/stroom-clients/releases/download/${SEND_TO_STROOM_VERSION}/send_to_stroom.sh .
ADD https://github.com/gchq/stroom-clients/releases/download/${SEND_TO_STROOM_VERSION}/send_to_stroom_args.sh .

RUN chmod u+x ./*.sh
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~ rust build stagte ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#FROM rust:1.61-alpine3.15 as rust-builder-stage
FROM rust:1.61-slim-bullseye as rust-builder-stage
WORKDIR /usr/src/rust-log-sender

COPY ./rust-log-sender/Cargo.toml .
COPY ./rust-log-sender/Cargo.lock .
RUN \
  mkdir ./src && \
  echo 'fn main() { println!("Dummy!"); }' > ./src/main.rs && \
  cargo build --release && \
  rm -rf ./src

COPY ./rust-log-sender/Cargo.* ./
COPY ./rust-log-sender/src ./src
RUN \
  touch -a -m ./src/main.rs && \
  cargo build --release

RUN pwd
RUN find .
RUN ls -l /usr/src/rust-log-sender/target/release/

#RUN cargo \
  #install \
  #--path . \
  #--root .

#RUN ls -l .

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Final build stage

#FROM alpine:3.8
FROM debian:11.3-slim

#This is the root dir for all our files/scripts
WORKDIR /stroom-log-sender

# This is where the crontab file is placed to be loaded into cron on each boot
VOLUME /stroom-log-sender/config/

# This is where the various certificates and keys are placed
VOLUME /stroom-log-sender/certs/

# run entrypoint script inside tini for better unix process handling, 
# see https://github.com/krallin/tini/issues/8
ENTRYPOINT ["/usr/bin/tini", "--", "/stroom-log-sender/rust-log-sender"]

# bash required for send_to_stroom.sh
# coreutils required for 'date' command to output millis
# curl required for sending logs
# gettext needed for 'envsubst' using in the entrypoint script
# procps needed for a richer 'ps' command as used in send_to_stroom.sh
# tini required for process control in the entrypoint
# Create a user with no home and no shell
# The log-volumes dir is where we expect volumes to be mounted 
    #groupadd --gid 1000 --system sender && \
RUN echo "http_proxy: $http_proxy" && \
    echo "https_proxy: $https_proxy" && \
    apt-get update && apt-get install -y \
      tini && \
    rm -rf /var/lib/apt/lists/* && \
    adduser --uid 1000 --system --shell /bin/false --disabled-password --group --gecos 'log-sender user' sender && \
    mkdir -p /stroom-log-sender && \
    mkdir -p /stroom-log-sender/config && \
    mkdir -p /stroom-log-sender/certs && \
    mkdir -p /stroom-log-sender/log-volumes && \
    chown -R sender:sender /stroom-log-sender

COPY \
  --chown=sender:sender \
  --from=rust-builder-stage \
  /usr/src/rust-log-sender/target/release/rust-log-sender \
  /stroom-log-sender/

# Copy in all the send logs scripts downloaded in the intermediate build stage
COPY \
  --chown=sender:sender \
  --from=send-logs-scripts-stage \
  /scripts \
  /stroom-log-sender

# Copy in the scripts for running the container
#COPY \
  #--chown=sender:sender \
  #docker-entrypoint.sh \
  #/stroom-log-sender/

# Label the image so we can see what commit/tag it came from
ARG GIT_COMMIT=unspecified
ARG GIT_TAG=unspecified
LABEL \
    git_commit="$GIT_COMMIT" \
    git_tag="$GIT_TAG"

USER sender
