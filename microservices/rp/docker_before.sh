#!/bin/bash
# This script is run right before the Docker container is build
# Its aim is to generate the Virtualhost file for the reverse proxy

# Get filenames
. docker_scripts_constants.sh

echo "Updating execution rights for generating scripts"
chmod +x generate_virtualhostfile.sh

echo "Generate the hostfile"
./generate_virtualhostfile.sh > $VHF_NAME

echo "Generated content is..."
cat $VHF_NAME

echo "Generation done"
