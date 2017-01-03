#!/usr/bin/bash
LOG="vm_init.log"
FOLDER="~/hpe_project"

DATE=$(date)

echo "$DATE: New execution started" >> $LOG

# If already setup, then don't re-execute
if [ -d "$FOLDER" ]; then
	echo "Already setup, nothing to deploy" >> $LOG
else
	# Create working folder
	echo "Create $FOLDER" >> $LOG
	mkdir "$FOLDER" >> $LOG

	echo "Go to folder..." >> $LOG
	cd "$FOLDER" >> $LOG

	if [ $? != 0 ]; then
		echo " ... Error, stop setup here" >> $LOG
		exit 1
	fi

	echo " ... Current folder is $PWD"

	# Get GIT repo
	echo "Get code from GIT repository" >> $LOG
	git clone https://github.com/jeromebarbier/hpe-project.git . >> $LOG

	DATE=$(date)
	echo "$DATE: Deployment finished with success"
fi

echo "Starting the microservice..." >> $LOG
if [ -z "$MICSERV" ]; then
    echo " ... No microservice to start, variable \$MICSERV not defined"
    exit 1
fi

# Run the builing of the Microservice
cd microservices
chmod +x build_container.sh >> $LOG

echo "Run container building..." >> $LOG
./build_container.sh "$MICSERV" >> $LOG

if [ $? -neq 0 ]; then
    echo " ... Failed to build container"
    exit 2
fi

echo "Run the container..." >> $LOG
sudo docker run -p 8090:8090 "$MICSERV-service" >> $LOG
