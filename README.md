# Stroom resources

## Swarm
Some Stroom applications can be run using Docker Swarm, fronted with an NGINX reverse proxy. The `./swarm` directory contains this setup. If you want to run these applications using Swarm you must update the IP addresses in `./swarm/swarm.yml` and in `./swarm/nginx/nginx.conf`. 

See `./swarm/nginx/nginx.confg` for routes, e.g. `http://localhost/stats` is mapped to `stroom-stats`. 

## Dev
Runs Stroom's dependencies in Docker containers. Suitable for development but not production.

To use the docker-compose.yml you need to add the some entries to `/etc/hosts` on the host machine:

```bash
sudo bash -c 'echo "# For stroom resources" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 stroom.kafka" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 stroom.hbase" >> /etc/hosts'
```
