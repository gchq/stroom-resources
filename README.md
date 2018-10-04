# Stroom resources

This repository provides various shell scripts and docker-compose configuration files for managing all the moving parts that make up the Stroom ecosystem.

## Pre-canned Docker stacks

The build scripts in `./bin/stack` can be used to create a pre-canned stroom stack that will run in Docker.
The released stacks are available on github at [github.com/gchq/stroom-resources/releases](https://github.com/gchq/stroom-resources/releases).

For more details on the docker stacks see this [README](./bin/stack/README.md)

## Setting up a development environment
If you want to clone all the git repositories that make up the Stroom ecosystem then run the following command from the directory where you want all the repositories cloned in to:

`bash <(curl https://raw.githubusercontent.com/gchq/stroom-resources/master/bin/cloneOrCheckStroomRepos.sh)`

Once this has been run you can run that script again to check the status of all of the branches in those repositories.

`stroom-resources/bin/cloneOrCheckStroomRepos.sh`

## Deploy
`stroom-stats` and `stroom-proxy` can be run using Docker Swarm, fronted with an NGINX reverse proxy. The `./deploy` directory contains this setup. 

### Running in dev
1. Start Zookeeper, Kafka, HBase, and Stroom databases by running the `runDevResources.sh` script in `./bin`. 
2. Run the deploy script `runDeploy.sh` in `./bin`. 

### Configuring the deployment
The `runDeploy.sh` script configures the deployment. 

The dev resources all publish their ports to the local machine. NGINX and the Swarm of Stroom applications need this IP address. `localhost` won't do because they run in Docker containers and `localhost` means the container itself. This IP address is injected as part of the `runDeploy.sh` script in `./bin`. This is needed in `nginx/nginx.conf` and in `swarm.yml`.

### Extending
See `./deploy/templates/nginx.confg` for routes, e.g. `http://localhost/stats` is mapped to `stroom-stats`. 

## Dev-resources
Runs Stroom's dependencies in Docker containers. Suitable for development but not production.

To use the docker-compose.yml you need to add the some entries to `/etc/hosts` on the host machine:

```bash
sudo bash -c 'echo "# For stroom resources" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 kafka" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 hbase" >> /etc/hosts'
```

To start a set of containers required for developing stroom you can use the `./bin/bounceIt.sh` script.
This script is intended for development use to provide an easy way of running parts of the stroom ecosystem in Docker.

When first run, `bounceIt` will create the file `./bin/local.env` which contains all the default configuration values.
This file is not in source control and thus can be tweaked to tweak modify the behaviour of `bounceIt`, e.g. configuring which services will be started, what docker image versions to use and configure various application specific settings.
For example you may want to run stroom in an IDE but the rest of the stack in docker.

To see all the options for running `bounceIt`, run:

```bash
./bounceIt.sh -h
```
