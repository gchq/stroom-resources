#!/bin/bash

############################################################################
# 
#  Copyright 2019 Crown Copyright
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# 
############################################################################

# shellcheck disable=SC2034
{
  MONOCHROME=false
  QUIET_MODE=false
  STACK_SERVICES_FILENAME="ACTIVE_SERVICES.txt"
  ALL_SERVICES_FILENAME="ALL_SERVICES.txt"
  LOGS_DIR_NAME="logs"

  SERVICES_WITH_HEALTH_CHECK=(
      "stroom"
      "stroom-stats"
      "stroom-proxy-local"
      "stroom-proxy-remote"
  )

  SERVICE_SHUTDOWN_ORDER=(
    "stroom-log-sender"
    "stroom-proxy-remote"
    "stroom-proxy-local"
    "nginx"
    "stroom-ui"
    "stroom"
    "stroom-stats"
    "stroom-all-dbs"
    "kafka"
    "hbase"
    "zookeeper"
    "hdfs"
  )
}
