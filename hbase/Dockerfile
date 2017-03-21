FROM harisekhon/hbase:1.2

ADD hbase-site.xml /hbase/conf/hbase-site.xml
ADD ./wait-for-it/wait-for-it_busybox.sh wait-for-it_busybox.sh
    
#Add the custom hbase filter onto the classpath, without this stroom-stats queries will fail
ADD https://github.com/gchq/stroom-stats/releases/download/v0.2-alpha/stroom-stats-hbase-filter-v0.2-alpha-all.jar /hbase/lib/

#If you want to debug the custom stats filter uncomment the following line
#but be warned if you have a lot of data this will generate a LOT of logging
#as it logs multiple entires per row in the table
#RUN echo "log4j.logger.stroom.stats=TRACE" >> /hbase/conf/log4j.properties
