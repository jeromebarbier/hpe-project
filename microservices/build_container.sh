#!/bin/bash
# This script build the Docker container, including all libraries

if [ $# == 1 ] && [ "$1" == "help" ]; then
    echo "Usage: $0 <MICROSERVICE NAME>"
    echo "Run this script from the microservices directory"
    exit 0
fi

# We're on the good folder
if [[ "$PWD" != */microservices/ ]] && [[ "$PWD" != */microservices ]]; then
    echo "Please run the following script from the microservices directory"
    exit 1
fi

# A microservice's name had been given
if [ $# != 1 ]; then
    echo "Please provide the microservice's name to build, available microservices are:"
    ls | egrep "^.$"
    exit 2
fi

MICROSERVICE="$1"

# The microservice's name is correct
echo "$MICROSERVICE" | egrep "^.$" > /dev/null 2> /dev/null && ls "$MICROSERVICE" > /dev/null 2> /dev/null
if [ $? != 0 ]; then
    echo "Microservice $MICROSERVICE is not a buildable microservice, available are:"
    ls | egrep "^.$"
    exit 3
fi

echo "Building microservice $MICROSERVICE"

# Copy libs
echo "  > Copying libs..."
cp -rp lwswift "$MICROSERVICE"
if [ $? != 0 ]; then
    echo "  ... Required libs cannot be copied"
    exit 2
fi

# Build Docker picture
echo "  > Creating Docker picture"
sudo docker build -t b-service:latest "$MICROSERVICE"

if [ $? -ne 0 ]; then
    echo "  ... Docker build failed, no image produced"
fi

# Remove libs
echo "  > Removing libs"
rm -rf "$MICROSERVICE/lwswift"

# Notify IP address to SWIFT
IP=$(ifconfig ens3 | grep 'inet ' | cut -d' ' -f12 | sed 's/addr://')
chmod +x notify_ip.sh
./notify_ip.sh "$MICROSERVICE" "$IP"
