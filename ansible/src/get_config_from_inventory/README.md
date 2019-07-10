# get_config_from_inventory

As you can see from the main `README.md` setting up the config is still a drag. This script might evolve to make things easier, but it's currently a WiP. It's goal is to generate the config from the inventory.

I hesitate to evolve this too much because the inventory will probably change a fair bit with k8s (or not), i.e. from `stroom_services` to individual host groups such as `nginx`, `stroom-auth-service`, `stroom-auth-ui`. So any major work done here might not adapt too well.
