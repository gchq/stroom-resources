# Overrides Directory

All files in this directory are overrides or additions to the services defined
in the parent directory. The name of the files is key as they are parsed in
`create_stack_yaml.sh`.  The name should be of the form:

`<service A name>_<service B name>.yml`

Where service A is the service that this file is overriding or aumenting and
service B is the service that service A is being overriden for.  For example
where service A needs to mount a volume 'owned' by service B.
