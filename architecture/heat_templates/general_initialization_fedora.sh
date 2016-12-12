#!/bin/bash
# Install required softwares
sudo dnf install -y docker python3 python3-flask ImageMagick git
if [ "$?" != "0" ]; then
	echo "Error while setting up the required softwares"
	return 1
fi

# Create project's arborescence
mkdir -p ~/dynamite-git
cd ~/dynamite-git

# Get project code
git clone https://github.com/jeromebarbier/hpe-project.git .
