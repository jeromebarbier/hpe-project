#!/bin/bash
# This script is run right after the Docker container is build
# Its aim is to delete the Virtualhost file for the reverse proxy

. docker_scripts_constants.sh
rm $VHF_NAME
