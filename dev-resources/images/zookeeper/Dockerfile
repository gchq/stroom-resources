#zookeeper

#Modified version of https://github.com/jplock/docker-zookeeper

FROM openjdk:8u171-jre-alpine

#Older versions get relegated to the archive mirror, currently the mirror only goes as far back as 3.4.6
ARG MIRROR=http://archive.apache.org/dist
#ARG MIRROR=http://apache.mirrors.pair.com
ARG VERSION=3.4.5

LABEL name="zookeeper" version=$VERSION

RUN echo "http_proxy: $http_proxy" \
    && echo "https_proxy: $https_proxy" \
    && echo "Building $VERSION from $MIRROR" \
    && apk add --no-cache wget bash \
    && mkdir -p /opt \
    && mkdir -p /var/lib/zookeeper \
    && wget -q -O - $MIRROR/zookeeper/zookeeper-$VERSION/zookeeper-$VERSION.tar.gz | tar -xzf - -C /opt \
    && mv /opt/zookeeper-$VERSION /opt/zookeeper \
    && cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg \
    && sed -i'' 's#dataDir=/tmp/zookeeper#dataDir=/var/lib/zookeeper#' /opt/zookeeper/conf/zoo.cfg 

EXPOSE 2181 2888 3888

WORKDIR /opt/zookeeper

#TODO do we care about having access to tmp and conf?
#VOLUME ["/opt/zookeeper/conf", "/tmp/zookeeper"]

# Use a volume for ZKs dataDir
VOLUME ["/var/lib/zookeeper"]

ENTRYPOINT ["/opt/zookeeper/bin/zkServer.sh"]

#default command for ENTRYPOINT
CMD ["start-foreground"]
