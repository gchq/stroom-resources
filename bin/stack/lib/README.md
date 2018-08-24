# Stroom

Use the scripts in this directory to start, stop, examine, or remove Stroom.

Run `start.sh` and, after the services have started, navigate to http://localhost/stroom to be taken into Stroom. The default username and password is `admin:admin`. It takes a while to startup and if you try too soon you might get 502 Bad Gateway.

If you have a firewall running you will need to open some ports to allow the Docker containers to talk to each other. Currently these ports are:

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

```
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
