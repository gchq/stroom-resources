# stroom-log-sender Docker Image

This is the Docker configuration for building a _stroom-log-sender_ container.
The purpose of _stroom-log-sender_ is to pick up rolled log files in shared Docker volumes and to send them to _stroom_.
A cron configuration is used to scedule the sending of the logs.
One cron configuration entry is used for each log source.

The cron configuration is achecived by placing a file called `crontab.txt` in the docker volume `VOLUME /stroom-log-sender/config/`.
On each container start, this file will be used to set the cron configuration.

The following is an example of the crontab entries used to send logs in `crontab.txt`:

``` crontab
# stroom logs
* * * * * /stroom-log-sender/send_to_stroom.sh /stroom-log-sender/log-volumes/stroom/user STROOM-USER-EVENTS http://stroom:8080/stroom/datafeed --system Stroom --environment Dev --file-regex '.*/[a-z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}\.log' -m 15 --delete-after-sending --secure > /dev/stdout

* * * * * /stroom-log-sender/send_to_stroom.sh /stroom-log-sender/log-volumes/stroom/app STROOM-APP-EVENTS http://stroom:8080/stroom/datafeed --system Stroom --environment Dev --file-regex '.*/[a-z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}\.log' -m 15 --delete-after-sending --secure > /dev/stdout

* * * * * /stroom-log-sender/send_to_stroom.sh /stroom-log-sender/log-volumes/stroom/access STROOM-ACCESS-EVENTS http://stroom:8080/stroom/datafeed --system Stroom --environment Dev --file-regex '.*/[a-z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}\.log' -m 15 --delete-after-sending --secure > /dev/stdout
```

As each log source is processed using a separate cron entry, they can operate concurrently and a failure of one will not affect the others.
The logging output for the send process is all sent to stdout.

For more information on the arguments available with the send_to_stroom.sh script, see [send_to_stroom](https://github.com/gchq/stroom-clients/blob/master/bash/README.md)

It is expected that all log sources are exposed to the stroom-log-sender as shared Docker volumes, mounted as sub directories in `/stroom-log-sender/log-volumes/`


