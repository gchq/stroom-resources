#!/usr/bin/env bash 
#
# Shows a count of the number of emails received

echo -e "Total emails received: "
docker exec -it fake-smtp sh -c 'ls -l  /var/mail/* | wc -l'
