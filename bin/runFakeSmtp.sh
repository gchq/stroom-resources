#!/usr/bin/env bash 
#
# Runs fakesmtp and tails the logs so you can see new things arrive

# Exit the script on any error
set -e

# Shell Colour constants for use in 'echo -e'
#shellcheck disable=SC2034
RED='\033[1;31m'
#shellcheck disable=SC2034
GREEN='\033[1;32m'
#shellcheck disable=SC2034
YELLOW='\033[1;33m'
#shellcheck disable=SC2034
BLUE='\033[1;34m'
#shellcheck disable=SC2034
LGREY='\e[37m'
#shellcheck disable=SC2034
DGREY='\e[90m'
#shellcheck disable=SC2034
NC='\033[0m' # No Color

# Get the dir that this script lives in, no matter where it is called from
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "To use fakeSmtp you need to configure ${BLUE}stroom-auth-service's${NC} environment variables. They will need to look like this:"
echo -e "    ${BLUE}STROOM_AUTH_EMAIL_SMTP_HOST=<\$HOST_IP for a stack>"
echo -e "    ${BLUE}STROOM_AUTH_EMAIL_SMTP_PORT=2525${NC}"
echo -e "    ${BLUE}STROOM_AUTH_EMAIL_SMTP_TRANSPORT=\"plain\"${NC}"
echo -e "    ${BLUE}STROOM_AUTH_EMAIL_SMTP_USERNAME=\"this-gets-ignored\"${NC}"
echo -e "    ${BLUE}STROOM_AUTH_EMAIL_SMTP_PASSWORD=\"this-gets-ignored\"${NC}"
echo -e "    ${BLUE}STROOM_AUTH_ALLOW_PASSWORD_RESETS=\"true\"${NC}"
echo
echo -e "If you're doing this for a stack then these settings need to be in ${BLUE}config/<stack_name>.env${NC}."
echo
echo -e "This script depends on ${BLUE}multitail${NC} so if you don't have that you'll need to install it first."
echo

read -rsp $'Press space to continue, or ctrl-c to exit...\n' -n1 keyPressed
if [ "$keyPressed" = '' ]; then
    echo
else
    echo "Exiting"
    exit 0
fi

docker-compose -f compose/containers/fakeSmtp.yml up -d

multitail -Q 1 "${SCRIPT_DIR}/../dev-resources/volumes/fakesmtp/*"

