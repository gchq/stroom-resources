#zookeeper

#Modified version of https://github.com/jplock/docker-zookeeper


# ~~~ zk download stage ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FROM alpine:3.8 as zk-download-stage

#Older versions get relegated to the archive mirror, currently the mirror only goes as far back as 3.4.6
ARG VERSION=3.4.5
ARG MIRROR=http://archive.apache.org/dist
#ARG MIRROR=http://apache.mirrors.pair.com
ARG URL="$MIRROR/zookeeper/zookeeper-$VERSION/zookeeper-$VERSION.tar.gz"

WORKDIR /

# Download the ZK archive and extract it
# Rename the directory
# Remove all the windows executables
# Make a config file from the default
# Change the dataDir prop
# Cat the config file to check the change was made
RUN \
    echo "Downloading $VERSION from $MIRROR" && \
    echo "URL: $URL" && \
    apk add --no-cache wget && \
    wget -q -O - $URL | tar -xzf -  && \
    mv /zookeeper-$VERSION /zookeeper && \
    rm /zookeeper/bin/*.cmd && \
    cp /zookeeper/conf/zoo_sample.cfg /zookeeper/conf/zoo.cfg && \
    sed -i'' 's#dataDir=.*#dataDir=/var/lib/zookeeper#' /zookeeper/conf/zoo.cfg && \
    cat /zookeeper/conf/zoo.cfg | grep "dataDir="

COPY ./entrypoint.sh /zookeeper/bin/

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



# ~~~ Final build stage ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# We probably don't need the full jdk but that is consistent with stroom so we can share the
# same base image.
FROM openjdk:8u181-jdk-alpine3.8

ARG VERSION=3.4.5

LABEL name="zookeeper" version=$VERSION

WORKDIR /opt/zookeeper

EXPOSE 2181 2888 3888

#TODO do we care about having access to tmp and conf?
#VOLUME ["/opt/zookeeper/conf", "/tmp/zookeeper"]

# Use a volume for ZKs dataDir
VOLUME ["/var/lib/zookeeper"]

#ENTRYPOINT ["./bin/entrypoint.sh"]
ENTRYPOINT ["/sbin/tini", "--", "/opt/zookeeper/bin/entrypoint.sh"]
#ENTRYPOINT ["/bin/bash", "-c", "echo \"JVMFLAGS: [${JVMFLAGS}]\"; echo \"cmd: [$@]\"; /opt/zookeeper/bin/zkServer.sh $@"]

#default command for ENTRYPOINT
CMD ["start-foreground"]

RUN \
    apk add --no-cache \
        bash \
        tini && \
    mkdir -p /opt/zookeeper && \
    mkdir -p /var/lib/zookeeper

COPY  --from=zk-download-stage /zookeeper /opt/zookeeper/

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
