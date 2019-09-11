#!/bin/bash
#
# Generates a tmuxinator file from an ansible inventory

readonly local TEMPLATE=scripts/tmuxinator.template.yml
readonly local TARGET=~/.tmuxinator/stroom_test.yml

# We're only appending so we need a fresh layout file
rm -f ${TARGET}
# We're appending so we can just copy the file -- not actually templating happens
cp ${TEMPLATE} ${TARGET}

# Uses JQ to get a list of all hosts, and appends that to the template file.
ansible-inventory --list | jq -r '._meta.hostvars | keys | .[]' | xargs -l echo "        - ssh" >> ${TARGET}
