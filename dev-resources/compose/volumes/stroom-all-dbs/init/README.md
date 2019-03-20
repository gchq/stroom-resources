# MySQL Initialisation files

All files in this directory with one of the following extensions

* `.sh` - sourced by the parent script
* `.sql`- run against the database as the root user
* `.sql.gz` - uncompressed and run against the database as the root user
* `.sql.template` - tags will be substituted and the resulting file will 
  be run aginst the database as the root user

will be processed in name order when the container is first run. The
processing is performed by the scripts `/usr/local/bin/docker-entrypoint.sh`
and `000_init_override.sh`.
