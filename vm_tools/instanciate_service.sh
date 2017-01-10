#!/bin/bash

####################################################################
# This script creates a new VM instance, running the asked service #
####################################################################

# Check parameter
if [ $# -lt 1 ] || [ "$1" == "help" ]; then
	echo "Usage: $0 <SERVICE NAME> [<PICTURE NAME> <NETWORK NAME> [<YES>]]"
	echo "       If <PICTURE NAME> and <NETWORK NAME> are defined, <YES> parameter disable all user-prompts"
	exit 0
fi

SERVICE="$1" # Micro-service name
UBUNTU="$2"
NETWORK="$3"
YES="$4"

# Check pre-requisites
echo "[DOING ] Checking openstack platform"

## Openstack command is ready to use
openstack help > /dev/null 2> /dev/null
if [ $? != 0 ]; then
	echo "[ FAIL ] Cannot use openstack command interpreter"
	exit 1
fi

## The flavor availability
openstack flavor list | grep "m1.small" > /dev/null
if [ $? != 0 ]; then
	echo "[ FAIL ] Flavor m1.small not available"
	exit 1
else
	echo "[  OK  ] Flavor m1.small available"
fi

## The system picture
if [ -z "$UBUNTU" ]; then
	# Don't overwrite user choice
	UBUNTU=$(openstack image list | grep ubuntu | cut -d' ' -f 4 | head -n 1) # Ubuntu image to use
fi

if [ -z "$UBUNTU" ]; then
	echo "[  ??  ] Cannot auto-find the picture to deploy, which one should be used?"
	printf "       > "
	read UBUNTU
fi

if [ -z "$YES" ]; then
	# If the user asked to NOT validate picture name... then don't validate it
	echo "[  ??  ] Picture $UBUNTU will be used, is this the good picture to use? [Y/n]"
	printf "       > "
	read YESNO
	if [ "$YESNO" != "Y" ] && [ "$YESNO" != "y" ] && [ -n "$YESNO" ]; then
		echo "[ INFO ] Available pictures:"
		openstack image list
		echo "[  ??  ] Wish one do you want to use?"
		printf "       > "
		read UBUNTU
	fi
fi

## The network
if [ -z "$NETWORK" ]; then
	echo "[ INFO ] Available networks:"
	openstack network list
	echo "[  ??  ] Which one do you want to use?"
	printf "       > "
	read NETWORK
fi

echo "[  OK  ] Picture $UBUNTU will be used"
echo "[ DONE ] Checking openstack platform"

echo "[ INFO ] Configuration to be deployed:"
echo "[ INFO ] Service=$SERVICE, image=$UBUNTU, network=$NETWORK"
if [ -z "$YES" ]; then
	echo "[  ??  ] Is it what you need? [Y/n]"
	printf "       > "
	read YESNO
	if [ "$YESNO" != "Y" ] && [ "$YESNO" != "y" ] && [ -n "$YESNO" ]; then
		echo "[  NO  ] Restart the script ;)"
		exit 0
	fi
fi

# Creating the instance
echo "[DOING ] Booting the VM"
openstack server create --flavor m1.small --image "$UBUNTU" --nic net-id="$NETWORK" --security-group default "$SERVICE-service"
echo "[ DONE ] Booting the VM"
