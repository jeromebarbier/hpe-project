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
echo "$MICROSERVICE" | egrep "^..?$" > /dev/null 2> /dev/null && ls "$MICROSERVICE" > /dev/null 2> /dev/null
if [ $? != 0 ]; then
    echo "Microservice $MICROSERVICE is not a buildable microservice, available are:"
    ls | egrep "^..?$"
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

# Run before code
if [ -f ./docker_before.sh ]; then
	echo "Running before code..."
	chmod +x ./docker_before.sh
	./docker_before.sh
	
	if [ $? != 0 ]; then
	    echo "... Before code failed to run! Return code is $?... Execution interrupted"
	    exit 1
	fi
	
	echo "... End code before"
fi

# Build Docker picture
echo "  > Creating Docker picture"
sudo docker build -t $MICROSERVICE-service:latest "$MICROSERVICE"

DOCKER_OK="ok"
if [ $? -ne 0 ]; then
    echo "  ... Docker build failed, no image produced"
    DOCKER_OK="nok"
fi

# Run after code
if [ -f ./docker_after.sh ]; then
	echo "Running after code..."
	chmod +x ./docker_after.sh
	./docker_after.sh
	
	if [ $? != 0 ]; then
	    echo "... After code failed to run! Return code is $?... Execution NOT interrupted"
    else
	    echo "... End code after"
	fi

fi

# Remove libs
echo "  > Removing libs"
rm -rf "$MICROSERVICE/lwswift"

if [ "$DOCKER_OK" == "ok" ]; then
    # Notify IP address to SWIFT
    if [ "$MICROSERVICE" != "rp" ]; then
    
        echo "Send IP notification to SWIFT"
        IP=$(/sbin/ifconfig ens3 | grep 'inet ' | cut -d' ' -f12 | sed 's/addr://')
        chmod +x notify_ip.sh
        ./notify_ip.sh "$MICROSERVICE" "$IP"
    
    else
        # Reverse proxy do not have to be registered !
        echo "Microservice is rp... don't notify SWIFT for its IP address"
    fi
    
    # Run service
    ## Try to detect proper port
    PORT=(cat $MICROSERVICE/$MICROSERVICE.conf | grep "port" | sed 's/port.*=[^0-9]*//')
    echo "Service $MICROSERVICE port is $PORT"
    sudo docker run -p $PORT:$PORT $MICROSERVICE
fi

echo "Process ended"
