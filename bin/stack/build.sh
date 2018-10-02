#!/usr/bin/env bash
#
# Builds a Stroom stack 

set -e

source lib/shell_utils.sh
setup_echo_colours

[ "$#" -ge 2 ] || die "${RED}Error${NC}: Invalid arguments, usage: ${BLUE}build.sh stackName serviceX serviceY etc.${NC}"

readonly STACK_NAME=$1
readonly SERVICES=${@:2}

./create_stack_yaml.sh $STACK_NAME $SERVICES
./create_stack_env.sh $STACK_NAME
./create_stack_scripts.sh $STACK_NAME
./create_stack_assets.sh $STACK_NAME $SERVICES

echo -e "${GREEN}Creating build/$STACK_NAME.tar.gz ${NC}"
tar -zcf build/$STACK_NAME.tar.gz build/$STACK_NAME
