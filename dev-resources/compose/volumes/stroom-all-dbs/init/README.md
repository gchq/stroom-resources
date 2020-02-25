# MySQL Initialisation files

MySQL will process all files the root of this directory with one of the
following extensions:

* `.sh` - sourced by the parent script
* `.sql`- run against the database as the root user
* `.sql.gz` - uncompressed (gzip) and run against the database as the root user
* `.sql.xz` - uncompressed (xzcat) and run against the database as the root user

The only file in this directory should be `000_stroom_init.sh`. All of our
stroom init scripts should be located in `/docker-entrypoint-initdb.d/stroom/`.

When `000_stroom_init.sh` is called it will process any `.template` files
substituting their tags with environment variables and then remove thier
`.template` extension. After this all files matching the above list of
extensions will be processed by MySQL's function.
