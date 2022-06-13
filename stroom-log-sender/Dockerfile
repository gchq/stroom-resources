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

# Intermediate build stage to grab all the send logs scripts then
# later copy them all in one go to reduce the number of layers
FROM rust:1.61-slim-bullseye as send-logs-scripts-stage
WORKDIR /scripts

ARG SEND_TO_STROOM_VERSION=send-to-stroom-v3.1.0

ADD https://github.com/gchq/stroom-clients/releases/download/${SEND_TO_STROOM_VERSION}/send_to_stroom.sh .
ADD https://github.com/gchq/stroom-clients/releases/download/${SEND_TO_STROOM_VERSION}/send_to_stroom_args.sh .

RUN chmod u+x ./*.sh
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~ rust build stage ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FROM rust:1.61-slim-bullseye as rust-builder-stage
WORKDIR /usr/src/rust-log-sender

COPY ./rust-log-sender/Cargo.* ./

# Build a dummy project using the cargo.toml to pull in all the deps then
# if cargo.toml doesn't change docker can cache this layer to avoid compiling all
# the deps again.
RUN \
  mkdir ./src && \
  echo 'fn main() { println!("Dummy!"); }' > ./src/main.rs && \
  cargo build --release && \
  rm -rf ./src

COPY ./rust-log-sender/src ./src

# Now build the actual project
RUN \
  touch -a -m ./src/main.rs && \
  cargo build --release
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~ Final build stage ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FROM debian:11.3-slim

#This is the root dir for all our files/scripts
WORKDIR /stroom-log-sender

# This is where the crontab file is placed to be loaded into cron on each boot
VOLUME /stroom-log-sender/config/

# This is where the various certificates and keys are placed
VOLUME /stroom-log-sender/certs/

# run entrypoint script inside tini for better unix process handling, 
# see https://github.com/krallin/tini/issues/8
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD [ "/stroom-log-sender/rust-log-sender", "/stroom-log-sender/config/config.yml"]

# curl required for sending logs
# procps for ps command used by send_to_stroom.sh
# tini required for process control in the entrypoint
# Create a user with no home and no shell
# The log-volumes dir is where we expect volumes to be mounted 
RUN echo "http_proxy: $http_proxy" && \
    echo "https_proxy: $https_proxy" && \
    apt-get update && apt-get install -y \
      curl \
      procps \
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

# Label the image so we can see what commit/tag it came from
ARG GIT_COMMIT=unspecified
ARG GIT_TAG=unspecified
LABEL \
    git_commit="$GIT_COMMIT" \
    git_tag="$GIT_TAG"

USER sender
