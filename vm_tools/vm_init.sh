#!/bin/bash
# Get environment variables
. /home/ubuntu/.bashrc

LOG=/home/ubuntu/vm_init.log
FOLDER="hpe_project"

DATE=$(date)

echo "$DATE: New execution started" >> $LOG

if [ -z "$MICSERV" ]; then
	echo "No \$MICSERV value, try to determine it from the hostname..." >> $LOG
	# No service name, try to retrieve it by ourselve
	PREC_HN_ELT=""
	for HNE in $(hostname | sed s/-/\\n/g)
	do
		if [ "$HNE" == "instance" ]; then
			MICSERV="$PREC_HN_ELT"
		fi
		PREC_HN_ELT="$HNE"
	done
	echo "... Value determined for \$MICSERV=$MICSERV" >> $LOG
fi

# If already setup, then don't re-execute
if [ -d $FOLDER ]; then
	echo "Already setup, nothing to deploy" >> $LOG
	cd $FOLDER >> $LOG
	
	echo "Updating code base" >> $LOG
	git pull 2>> $LOG >> $LOG
else
	# Create working folder
	echo "Create $FOLDER" >> $LOG
	mkdir $FOLDER >> $LOG

	echo "Go to folder..." >> $LOG
	cd $FOLDER >> $LOG

	if [ $? != 0 ]; then
		echo " ... Error, stop setup here" >> $LOG
		exit 1
	fi

	echo " ... Current folder is $PWD" >> $LOG

	# Get GIT repo
	echo "Get code from GIT repository" >> $LOG
	git clone https://github.com/jeromebarbier/hpe-project.git . 2>> $LOG >> $LOG

	DATE=$(date)
	echo "$DATE: Deployment finished with success" >> $LOG
fi

echo "Starting the microservice..." >> $LOG
if [ -z "$MICSERV" ]; then
    echo " ... No microservice to start, variable \$MICSERV not defined" >> $LOG
    exit 1
fi

# Run the builing of the Microservice
cd microservices
chmod +x build_container.sh >> $LOG

echo "Run container building..." >> $LOG
./build_container.sh "$MICSERV" 2>> $LOG >> $LOG

if [ $? != 0 ]; then
    echo " ... Failed to build container" >> $LOG
    exit 2
fi

echo "Run the container..." >> $LOG
sudo docker run -p 8090:8090 "$MICSERV-service" 2>> $LOG >> $LOG
