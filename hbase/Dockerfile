FROM harisekhon/hbase:1.2

ADD hbase-site.xml /hbase/conf/hbase-site.xml
ADD ./wait-for-it/wait-for-it_busybox.sh wait-for-it_busybox.sh
    
ADD https://github.com/gchq/stroom-stats/releases/download/v0.1-alpha/stroom-stats-hbase-filter-v0.1-alpha-all.jar /hbase/lib/
