#!/bin/bash
# This script executes orders to repair a service
# Basically, it stops Docker service instance and then rebuild and re-run it

# Usage : In production mode:
#   ./repair_service
#         In debug mode (to force the service to repair)
#   ./repair_service <SERVICE NAME>

# Check pre-requisites
if [ "$USER" != "root" ]; then
    echo "This script must be run by user root"
    exit 1
fi

if [[ "$PWD" != */microservices/ ]] && [[ "$PWD" != */microservices ]]; then
    echo "Please run the following script from the microservices directory"
    exit 1
fi

# Check if user forced the repair process
if [ -n "$1" ]; then
    echo "Debug mode, repairing $1"
    MICSERV="$1"
fi

if [ -z "$MICSERV" ]; then
    echo "Cannot determine the service to repair, \$MICSERV is not set!"
    exit 1
fi

if [ ! -f "$MICSERV/Dockerfile" ]; then
    echo "Cannot repair services that are not based on Docker"
    exit 1
fi

# Do the job
INSTANCE=$(docker ps | grep "$MICSERV-service" | cut -d' ' -f1)
if [ -n "$INSTANCE" ]; then
    echo "Stopping container $INSTANCE..."
    docker kill "$INSTANCE"
    
    if [ $? -eq 0 ]; then
        echo "... Stopped container"
    else
        echo "... Failed to stop container, please do it by yourself and rerun this script"
        exit 2
    fi 
else
    echo "The service is not currently running!"
fi

echo "Restart build and running procedure"
./deploy_service.sh "$MICSERV"
