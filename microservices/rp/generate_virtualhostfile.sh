#/bin/bash

# This script generates the Virtualhost file used
# by the reverse proxy to forward resquests

# For that :
#  - It lists all the available microservices
#  - For each of them, it try to retrieve the IP address from SWIFT
#  - If there is an IP address, then put it as a redirection on
#    the Virtualhost file

DATE=$(date)
HOST=$(hostname)

if [ ! -h lwswift ] && [ ! -d lwswift ]; then
    ln -s ../lwswift lwswift
fi

echo "# Configuration generated on $DATE using $HOST
<VirtualHost *:*>
    ProxyPreserveHost On
    ProxyRequests Off
"

for POTENTIAL_PS in ../*
do
    if [ -d "$POTENTIAL_PS" ]; then
        POTENTIAL_PS=$(echo "$POTENTIAL_PS" | sed 's/\.\.\///')

        if [ ${#POTENTIAL_PS} == 1 ]; then
            # This is a valid microservice
            MICROSERVICE_NAME="$POTENTIAL_PS"
            MICROSERVICE_IP=$(./retrieve_ip.sh "$MICROSERVICE_NAME" 2> /dev/null)
            
            if [ -n "$MICROSERVICE_IP" ]; then
                echo "    # Redirection for service $MICROSERVICE_NAME"
                echo "    ProxyPass /$MICROSERVICE_NAME http://$MICROSERVICE_IP:8090/"
                echo "    ProxyPassReverse /$MICROSERVICE_NAME http://$MICROSERVICE_IP:8090/"
                echo ""
            fi
        fi 
    fi
done

echo "    <Proxy>
        Order Allow,Deny
        Allow from all
    </Proxy>

    ServerName localhost
</VirtualHost>"
