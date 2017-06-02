#!/bin/sh

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters ($#)"
    echo "Usage: entry_point.sh zookeeperConnectString"
    echo "e.g. entry_point.sh host1:2181,host2:2181,host3:2181"
    echo "e.g. entry_point.sh localhost:2181"
fi

zkConnectStr=$1

#remove all but the first host from the connect string
#firstZKHost=`echo "$zkConnectStr" | sed '/,.*//'`

scriptFile=./stroom-stats-properties.zk

#echo "Waiting until Zookeeper is listening on $firstZKHost"

#./wait-for-it.sh "{$firstZKHost}" -- echo "Zookeeper is up"

echo "Loading data into zookeeper with connect string $zkConnectStr and script file $scriptFile"

if [ -f ${scriptFile} ]; then
    /opt/zookeeper/bin/zkCli.sh -server "$zkConnectStr" < ${scriptFile}

    [ ! $? -eq 0 ] && echo "Error running script $scriptFile" && exit 1

    #move the script file to prevent it being run again
    doneFile="$scriptFile.done"
    echo "Moving $scriptFile to $doneFile"
    mv $scriptFile ${doneFile}
fi

# Register services
java -jar stroom-services-discovery.jar -n kafka -ip kafka -p 9092 -zk $zkConnectStr
java -jar stroom-services-discovery.jar -n hbase -ip hbase -p 60000 -zk $zkConnectStr
java -jar stroom-services-discovery.jar -n stroom-db -ip stroom-db -p 3306 -zk $zkConnectStr

echo "Loading complete, shuting down container"
#exit so the container will shut down one the script has run
exit 0
