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
* `ctop.sh` - Runs the _ctop_ utility for monitoring each of the containers (e.g. memory, CPU, etc.).
* `health.sh` - Checks the health of the applications in the stack.
* `logs.sh` - Starts tailing the logs of all containers from the last 5 entries of each.
* `remove.sh` - Removes all the containers in the stack, destroying any state.
* `restart.sh` - Restarts all the containers in the stack.
* `stack.sh` - A single script for controlling the stack, e.g. `./stack.sh start`
* `start.sh` - Starts all the containers for the stack.
* `status.sh` - Displays the status of all the docker containers in the stack.
* `stop.sh` - Stops all the containers in the stack.

## Volumes

The Stroom stack uses a mixture of Docker manged volumes and volumes bound to the file system.  The bound volumes are all
bound to directories in `./volumes`, however these volumes are all read-only so the containers will only read from them.  All application state (e.g. database tables, stream store, indexes, proxy repositories, etc.) is held in the docker manged volumes and is independent of the containers.

## Upgrading the stack

To run a new version of the stack with existing data (e.g. streams, indexes, etc.) follow the following steps:

1. Stop the existing stack using `./stop.sh`
1. Download and extract the new stack release into a different location to the existing stack.
1. If you have changed any of the stack configuration in the `./config/` directory then compare the old config to the new config and re-apply your changes as required.
1. Start the new stack using the `./start.sh` script.  Docker will upgrade any containers with new images as required and maintain existing volume links.
