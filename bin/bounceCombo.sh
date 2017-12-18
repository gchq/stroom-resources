#!/usr/bin/env bash 

#TODO verify arg count is >= 1
comboFile=$1

shift

#TODO verify comboFile exists

source $comboFile

#comboFile can look like:
#SERVICE_LIST=stroom stroom-db stroom-stats-db
#STROOM_TAG=master-SNAPSHOT
#STROOM_DEVELOPMENT_MODE=true
#etc.

#TODO verify SERVICE_LIST is set to something

#comboFile needs to set the var SERVICE_LIST

#Call bounceIt with any extra args passed to this script, plus the list of services obtained from sourcing the comboFile
./bounceIt.sh $@ $SERVICE_LIST

