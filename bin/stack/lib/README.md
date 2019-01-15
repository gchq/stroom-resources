# Stroom

Use the scripts in this directory to control a set of Docker containers that make up a working Stroom stack.
This stack is not intended for production use, it is intended to be used for testing, trialing or demonstrating the Stroom software.

The file _VERSIONS.txt_ defines the version of each container in use.

## Prerequisites

In order to use these scripts you will need: 

* [_Docker_](https://docs.docker.com/install/)
* [_Docker Compose_](https://docs.docker.com/compose/install/)
* _GNU sed_
* _GNU grep_

In order to use the `health.sh` script you will need

* [_jq_](https://stedolan.github.io/jq/)

## Quick Start

Run `start.sh`. The script will attempt to wait for all the applications to start up and will indicate when the stack is ready.
Then navigate to [http://localhost/stroom](http://localhost/stroom) to be taken into Stroom. 
Login with a username of `admin` and the default password `admin`. 

If you have a firewall running you will need to open some ports to allow the Docker containers to talk to each other. 
Currently these ports are:

- 3307
- 8080
- 8081
- 8090
- 8091
- 8543
- 5000
- 2888
- 443
- 80

So if you're firewall is `firewalld` then you'll want to do something like this:

``` bash
sudo firewall-cmd --zone=public --permanent --add-port=3307/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8080/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8081/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8090/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8091/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8443/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8543/tcp
sudo firewall-cmd --zone=public --permanent --add-port=5000/tcp
sudo firewall-cmd --zone=public --permanent --add-port=2888/tcp
sudo firewall-cmd --zone=public --permanent --add-port=443/tcp
sudo firewall-cmd --zone=public --permanent --add-port=80/tcp
sudo firewall-cmd --reload
```

## Scripts

The following scripts are available to control the docker containers:

* `config.sh` - Displays the effective configuration that docker-compose will use.
* `health.sh` - Checks the health of the applications in the stack.
* `info.sh` - Displays information about the various URLs to use for accessing Stroom.
* `logs.sh` - Starts tailing the logs of all containers from the last 5 entries of each.
* `remove.sh` - Removes all the containers in the stack, destroying any state.
* `restart.sh` - Restarts all the containers in the stack.
* `send-data.sh` - A script for sending data into Stroom or Stroom Proxy
* `stack.sh` - A single script for controlling the stack, e.g. `./stack.sh start`
* `start.sh` - Starts all the containers for the stack.
* `status.sh` - Displays the status of all the docker containers in the stack.
* `stop.sh` - Stops all the containers in the stack.

## Sending data to Stroom

Data can be POSTed to Stroom or Stroom Proxy at the URLs described when you run the `./info.sh` script. 
The data should be sent with the following HTTP header attributes as a minimum:

* `Feed: MY_FEED_NAME` - The name of the feed in Stroom that the data will be stored against.
* `System: MY_SYSTEM_NAME` - The name of the system that produced the data.
* `Environment: DEV` - The type of environment of the source system, e.g. DEV, OPS, etc.

A helper script is provided for easily sending all files in a directory to Stroom or Stroom Proxy, e.g.:

``` bash
./send_data.sh /tmp/data stroom TEST_FEED TEST_SYSTEM DEV

```

or

``` bash
./send_data.sh /tmp/data stroom-proxy TEST_FEED TEST_SYSTEM DEV

```

For more configuration options you can use the script `./lib/send_to_stroom.sh`.

### Proxy configuration

The stack is configured with two _stroom-proxy_ instances.
The proxies have the same datafeed interface as stroom but abstract stroom from the source of the data, allowing stroom to be shutdown while the proxies are still collecting data.
A stroom-proxy can proxy for another proxy which is how the _remote_ proxy in the stack is configured.
The following diagram shows how the data can flow.

```
  data                      data                data
    +                         +                   +
    |                         |                   |
    |                         |                   |
+---v--------+  push    +-----v------+ pull  +----v-----+
|stroom-proxy|--------->|stroom-proxy|------>|  stroom  |
|  (remote)  |          |   (local)  |       |          |
+------------+          +------------+       +----------+
```

The 'remote' proxy is configured to store then forward.
This aggregates the received data then periodically forwards the aggregated data (in larger batches) to the 'local' proxy.
The 'local' proxy is configured to store the received data. 
The stored data in the 'local' proxy is then periodically pulled into stroom, using a shared directory.

## Volumes

The Stroom stack uses a mixture of Docker managed volumes and volumes bound to the file system.  The bound volumes are all
bound to directories in `./volumes`, however these volumes are all read-only so the containers will only read from them.  All application state (e.g. database tables, stream store, indexes, proxy repositories, etc.) is held in the docker managed volumes and is independent of the containers.

## Upgrading the stack

To run a new version of the stack with existing data (e.g. streams, indexes, etc.) follow the following steps:

1. Stop the existing stack using `./stop.sh`
1. Download and extract the new stack release into a different location to the existing stack.
1. If you have changed any of the stack configuration in the `./config/` directory then compare the old config to the new config and re-apply your changes as required.
1. Start the new stack using the `./start.sh` script.  Docker will upgrade any containers with new images as required and maintain existing volume links.
