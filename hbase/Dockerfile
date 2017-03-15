FROM harisekhon/hbase:1.2

ADD hbase-site.xml /hbase/conf/hbase-site.xml
ADD ./wait-for-it/wait-for-it_busybox.sh wait-for-it_busybox.sh

# We need `openssl` or `wget` will fail. Alpine-specific requirement, which is what `harisekhon/hbase` is built on.
RUN apk update \
    && apk add openssl \
    && wget https://github.com/gchq/stroom-stats/releases/download/v0.1-alpha/stroom-stats-hbase-filter-v0.1-alpha-all.jar -O /hbase/lib/stroom-stats-hbase-filter-v0.1-alpha-all.jar
