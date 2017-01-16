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
OUT_FILE=/etc/apache2/sites-available/reverse-list.conf
if [ -n "$1" ]; then
    echo "/!\ Running in debug mode!"
    OUT_FILE="$1"
fi

if [ ! -h lwswift ] && [ ! -d lwswift ]; then
    ln -s ../lwswift lwswift
fi

echo "# Configuration generated on $DATE using $HOST
<VirtualHost *:*>
    ProxyPreserveHost On
    ProxyRequests Off
" >> $OUT_FILE

OUTPUT=$(heat stack-list $OS_STACKNAME 2> /dev/null)
SERVICE=""
IP=""
while read LINE;
do
    if [ $(echo "$LINE" | grep "_instance_internal_ip") ]; then
        SERVICE=$(echo "$LINE" | grep -Po '[a-z]+_instance' | sed 's/_instance//')
    fi
    
    if [ $(echo "$LINE" | grep "output_value") ]; then
        IP=$(echo "$LINE" | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")
    fi
    
    if [ $(echo "$LINE" | grep '{') ]; then
        SERVICE=""
        IP=""
    fi
    
    if [ -n "$IP" ] && [ -n "$SERVICE" ]; then
        echo "    # Redirection for service $SERVICE" >> $OUT_FILE
        echo "    ProxyPass /$SERVICE http://$IP:8090/" >> $OUT_FILE
        echo "    ProxyPassReverse /$SERVICE http://$IP:8090/" >> $OUT_FILE
        echo "" >> $OUT_FILE
        
        SERVICE=""
        IP=""
    fi
done <<< "$OUTPUT"

echo "    <Proxy>
        Order Allow,Deny
        Allow from all
    </Proxy>

    ServerName localhost
</VirtualHost>" >> $OUT_FILE
