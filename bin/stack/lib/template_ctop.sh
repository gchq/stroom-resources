#!/usr/bin/env bash
#
# Run ctop, top for docker containers. 
#
# ctop keybindings are as follows
#   <enter>   Open container menu
#   a         Toggle display of all (running and non-running) containers
#   f	        Filter displayed containers (esc to clear when open)
#   H	        Toggle ctop header
#   h	        Open help dialog
#   s	        Select container sort field
#   r	        Reverse container sort order
#   o	        Open single view
#   l	        View container logs (t to toggle timestamp when open)
#   S	        Save current configuration to file
#   q	        Quit ctop

docker run -ti --name ctop --rm \
   -v /var/run/docker.sock:/var/run/docker.sock \
   quay.io/vektorlab/ctop:latest