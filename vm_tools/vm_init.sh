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

echo "Run IP notifier..." >> $LOG
./vm_tools/init_ip_notifier.sh
