# _stroom-log-sender_ Docker Image

_stroom-log-sender_ is a Docker image whoes purpose is to send completed log
files to _stroom_. Typically you will have an application that is generating
application and audit log envents that are being appended to a file that is
periodically rolled. The aim of _stroom_log_sender_ is to poll a shared docker
volume for new rolled log files and send them to _stroom_ then delete them.

_stroom-_log_sender_ removes the need for the application that is generating
the logs to concern itself with the mechanics of sending logs to _stroom_ such
as cron schedules and certificates.

_stroom_log_sender_ uses 
[supercronic](https://github.com/aptible/supercronic) to schedule the polling
and the
[_send_to_stroom.sh_](https://github.com/gchq/stroom-clients/tree/master/bash)
script to send the completed logs.

For details on how to use _stroom_log_sender_ see the
[DockerHub](https://hub.docker.com/r/gchq/stroom-log-sender) page.

This is the Docker configuration for building a _stroom-log-sender_ container.
The purpose of _stroom-log-sender_ is to pick up rolled log files in shared
Docker volumes and to send them to _stroom_. A cron configuration is used to
schedule the sending of the logs.  One cron configuration entry is used for
each log source.

The cron configuration is achieved by placing a file called `crontab.txt` in
the docker volume

``` docker
VOLUME /stroom-log-sender/config/.
```

On each container start, this file will be used to set the cron configuration.

The following is an example of the crontab entries used to send logs in
`crontab.txt`:

``` crontab
# stroom logs
* * * * * /stroom-log-sender/send_to_stroom.sh /stroom-log-sender/log-volumes/stroom/user STROOM-USER-EVENTS Stroom Dev http://stroom:8080/stroom/datafeed --file-regex '.*/[a-z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}\.log' -m 15 --delete-after-sending --secure > /dev/stdout

* * * * * /stroom-log-sender/send_to_stroom.sh /stroom-log-sender/log-volumes/stroom/app STROOM-APP-EVENTS Stroom Dev http://stroom:8080/stroom/datafeed --file-regex '.*/[a-z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}\.log' -m 15 --delete-after-sending --secure > /dev/stdout

* * * * * /stroom-log-sender/send_to_stroom.sh /stroom-log-sender/log-volumes/stroom/access STROOM-ACCESS-EVENTS Stroom Dev http://stroom:8080/stroom/datafeed --file-regex '.*/[a-z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}\.log' -m 15 --delete-after-sending --secure > /dev/stdout
```

As each log source is processed using a separate cron entry, they can operate
concurrently and a failure of one will not affect the others. The logging
output for the send process is all sent to stdout.

It is expected that all log sources are exposed to the stroom-log-sender as
shared Docker volumes, mounted as sub directories in
`/stroom-log-sender/log-volumes/`


