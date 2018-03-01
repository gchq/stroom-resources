#!/usr/bin/env bash

# Given a local filename to use for storing credentials, and a list of environment variable names,
# This script checks for the existence of the credential file.
# It then runs the file as a script
# For each environment variable required, it then checks to see if the value was exported (expecting the credential file to do this)
# Any credentials that are not set, are captured form the user and then written to the script file
# This way the script file will contains a source file that can set the various environment variables for future runs of docker-compose

## Colour constants for use with echo -e
GREEN='\033[1;32m'
DGREY='\e[90m'
NC='\033[0m' # No Color

CREDENTIALS_FILE=$1
ENVIRONMENT_VARS_FILE=$2

echo -e "Capturing values for the environment variables listed in ${GREEN}${ENVIRONMENT_VARS_FILE}${NC}"
echo -e "These will be saved to ${GREEN}${CREDENTIALS_FILE}${NC} for re-use in this environment"

ENV_VARS_TO_CAPTURE=`cat ${ENVIRONMENT_VARS_FILE}`

if [ -f ${CREDENTIALS_FILE} ]; then
   echo "Credentials File ${CREDENTIALS_FILE} already exists."
   source ${CREDENTIALS_FILE}
else
   echo "Credentials File ${CREDENTIALS_FILE} does not exist."
   touch ${CREDENTIALS_FILE}
fi

for ENV_VAR_TO_CAPTURE in ${ENV_VARS_TO_CAPTURE}
do
    if [ -z "${!ENV_VAR_TO_CAPTURE}" ]; then
        echo -e "Please type in value of ${GREEN}${ENV_VAR_TO_CAPTURE}${NC}"
        read VALUE
        echo "export ${ENV_VAR_TO_CAPTURE}=${VALUE}" >> ${CREDENTIALS_FILE}
    else
        echo -e "Value of ${DGREY}${ENV_VAR_TO_CAPTURE}${NC} is ${DGREY}${!ENV_VAR_TO_CAPTURE}${NC}"
    fi
done