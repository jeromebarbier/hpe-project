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

# Variable that will finally say if all was good
ALL_WAS_GOOD="yes"

# Run deployement script
if [ -f ./Deployscript.sh ]; then
	echo "Running deployement script..."
	chmod +x ./Deployscript.sh

	./Deployscript.sh

	if [ $? != 0 ]; then
	    echo "... Deployement script failed to run! Return code is $?, Docker deployement will not be performed"
	    ALL_WAS_GOOD="no"
	fi
	
	echo "... End running deployement script (ALL_WAS_GOOD=$ALL_WAS_GOOD)"
fi

# If there is a Dockerfile, then run Docker
# Only if precedent deployement process is a success
if [ -f ./Dockerfile ] && [ "$ALL_WAS_GOOD" == "yes" ]; then
    ## Build Docker picture
    echo "Running Dockerfile..."
    echo "  > Creating Docker picture"
    docker build -t $MICROSERVICE-service:latest .

    if [ "$?" != "0" ]; then
        echo "  ... Docker build failed, no image produced (so docker run will not be executed but after code will)"
        ALL_WAS_GOOD="no"
    fi

    if [ "$ALL_WAS_GOOD" == "yes" ]; then
        # Run service
        ## Try to detect internal service port (to bind it to host computer 80)
        PORT=$(cat "$MICROSERVICE.conf" 2> /dev/null | grep "port" | sed 's/port.*=[^0-9]*//')

        echo "  > Service $MICROSERVICE port is $PORT"

        if [ -z "$PORT" ]; then

            echo "    ... Invalid port, don't start Docker instance"
            ALL_WAS_GOOD="no"

        else

            ## Run Docker newly built image and bind it to port 80
            ## (in order to make RP host compatible with it)
            CONVENTIONNAL_PORT=80

            sudo docker run -d \
              -e OS_TENANT_NAME="$OS_TENANT_NAME" \
              -e OS_USERNAME="$OS_USERNAME" \
              -e OS_PASSWORD="$OS_PASSWORD" \
              -e OS_AUTH_URL="$OS_AUTH_URL" \
              -e OS_STACKNAME="$OS_STACKNAME" \
              -e OS_RP_IP="$OS_RP_IP" \
              -e OS_DB_IP="$OS_DB_IP" \
              -p $CONVENTIONNAL_PORT:$PORT "$MICROSERVICE-service"
              
            if [ $? != 0 ]; then
                # Remain there had been an error !
                echo "... Docker run failed"
                ALL_WAS_GOOD="no"
            fi
        fi
    fi

    echo "... Dockerfile building terminated (ALL_WAS_GOOD=$ALL_WAS_GOOD)"
fi

# From now, use the parent folder
cd ..

# Remove libs
echo "  > Removing libs"
rm -rf "$MICROSERVICE/lwswift"


echo "Process ended"

if [ "$ALL_WAS_GOOD" != "yes" ]; then
    exit 4
else
    exit 0
fi
