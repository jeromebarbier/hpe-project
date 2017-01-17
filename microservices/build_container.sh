#!/bin/bash

# This script build the Docker image, including all libraries
# It also run the built Docker image

# This script aim is to be run at each update in the given service

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
# echo "$MICROSERVICE" | egrep "^.$" > /dev/null 2> /dev/null && ls "$MICROSERVICE" > /dev/null 2> /dev/null
if [ ! -d "$MICROSERVICE" ]; then
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

# From now, only play with the service's folder
cd $MICROSERVICE

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
sudo docker build -t $MICROSERVICE-service:latest .

DOCKER_OK="$?"
if [ "$DOCKER_OK" != "0" ]; then
    echo "  ... Docker build failed, no image produced (so docker run will not be executed but after code will)"
    DOCKER_OK="nok"
else
    DOCKER_OK="ok"
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

# From now, use the parent folder
cd ..

# Remove libs
echo "  > Removing libs"
rm -rf "$MICROSERVICE/lwswift"

if [ "$DOCKER_OK" == "ok" ]; then
    # Run service
    ## Try to detect proper port
    PORT=$(cat "$MICROSERVICE/$MICROSERVICE.conf" 2> /dev/null | grep "port" | sed 's/port.*=[^0-9]*//')
    echo "Service $MICROSERVICE port is $PORT"
    
    if [ -z "$PORT" ]; then
    
        echo "... Invalid port, don't start Docker instance"
        DOCKER_OK="nok"
    
    else

        ## Run Docker newly built image and bind it to port 8090
        ## ... unless this is RP because RP needs to be binded on port 80
        CONVENTIONNAL_PORT=80
        if [ "$MICROSERVICE" == "rp" ]; then
            CONVENTIONNAL_PORT=8090 # Make RP NOT public
        fi

        sudo docker run -d \
          -e OS_TENANT_NAME="$OS_TENANT_NAME" \
          -e OS_USERNAME="$OS_USERNAME" \
          -e OS_PASSWORD="$OS_PASSWORD" \
          -e OS_AUTH_URL="$OS_AUTH_URL" \
          -e OS_STACKNAME="$OS_STACKNAME" \
          -e OS_RP_IP="$OS_RP_IP" \
          -p $CONVENTIONNAL_PORT:$PORT "$MICROSERVICE-service"
          
        if [ $? != 0 ]; then
            # Remain there had been an error !
            DOCKER_OK="nok"
        fi
    fi
fi

echo "Process ended"

if [ "$DOCKER_OK" != "ok" ]; then
    exit 4
else
    exit 0
fi
