# stroom-resources

Runs Stroom's dependencies in Docker containers. Suitable for development but not production.

To use the docker-compose.yml you need to add the some entries to `/etc/hosts` on the host machine:

```bash
sudo bash -c 'echo "# For stroom resources" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 stroom.kafka" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 stroom.hbase" >> /etc/hosts'
```