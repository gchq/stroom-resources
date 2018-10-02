# Stroom

Use the scripts in this directory to control a set of Docker containers that make up a working Stroom stack.
The file _VERSIONS.txt_ defines the version of each container in use.

## Prerequisites

In order to use these scripts you will need _Docker_, _Docker Compose_ and _GNU sed/grep_.

## Quick Start

Run `start.sh` and, after the services have started, navigate to http://localhost/stroom to be taken into Stroom. 
The default username and password is `admin:admin`. 
It takes a while to startup and if you try too soon you might get 502 Bad Gateway.

If you have a firewall running you will need to open some ports to allow the Docker containers to talk to each other. 
Currently these ports are:

- 3307
- 3308
- 3309
- 8080
- 8081
- 5000
- 2888
- 443
- 80

So if you're firewall is `firewalld` then you'll want to do something like this:

``` bash
sudo firewall-cmd --zone=public --permanent --add-port=3307/tcp
sudo firewall-cmd --zone=public --permanent --add-port=3308/tcp
sudo firewall-cmd --zone=public --permanent --add-port=3309/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8080/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8081/tcp
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
* `logs.sh` - Starts tailing the logs of all containers from the last 5 entries of each.
* `remove.sh` - Removes all the containers in the stack.
* `restart.sh` - Restarts all the containers in the stack.
* `stack.sh` - A single script for controlling the stack, e.g. `./stack.sh start`
* `start.sh` - Starts all the containers for the stack.
* `status.sh` - Displays the status of all the docker containers in the stack.
* `stop.sh` - Stops all the containers in the stack.
