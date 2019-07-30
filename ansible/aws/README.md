# Ansible scripts to set up AWS 

These scripts are a work in progress.

You can use these scripts and configurations to set up an AWS ansible environment for Stroom. 

The credentials and config for ansible are all encrypted in an Ansible vault. If you want to use them you must create a vault password file. The location for this file is specified in `./ansible.cfg`. 

## ec2 Key Pairs
Key pairs provide access to ec2 using certificates. You'll need to use the creationg key pair scripts if you don't already have one on your machine. 
