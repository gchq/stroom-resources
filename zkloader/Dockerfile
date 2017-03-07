#zkloader

FROM stroom-stats/zookeeper

ARG VERSION=3.4.6

LABEL name="zkloader" version=$VERSION

ADD entry_point.sh ./entry_point.sh
ADD ./stroom-stats-properties.zk ./stroom-stats-properties.zk
ADD ./wait-for-it/wait-for-it_busybox.sh ./wait-for-it_busybox.sh
ADD ./stroom-services-discovery.jar stroom-services-discovery.jar

ENTRYPOINT ["./entry_point.sh"]

#default args for the entrypoint if none are supplied
CMD ["localhost:2181"]

