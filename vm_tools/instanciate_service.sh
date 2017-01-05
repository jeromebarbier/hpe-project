#!/bin/bash

####################################################################
# This script creates a new VM instance, running the asked service #
####################################################################

# Check parameter
if [ $# -lt 1 ] || [ "$1" == "help" ]; then
	echo "Usage: $0 <SERVICE NAME>"
	exit 0
fi

# Check pre-requisites
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
UBUNTU=$(openstack image list | grep ubuntu | cut -d' ' -f 4 | head -n 1)
if [ -z "$UBUNTU" ]; then
	echo "[  ??  ] Cannot auto-find the picture to deploy, wich one should be used?"
	read UBUNTU
fi

echo "[  ??  ] Picture $UBUNTU will be used, is this the good picture to use? [Y/n]"
read YESNO
if [ "$YESNO" != "Y" ] && [ "$YESNO" != "y" ]; then
	openstack image list
	echo "[  ??  ] Wish one do you want to use?"
	read UBUNTU
fi

echo "[  OK  ] Picture $UBUNTU will be used"

