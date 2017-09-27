#!/bin/sh

#See https://docs.docker.com/engine/reference/commandline/stats/#formatting
docker stats --all --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
