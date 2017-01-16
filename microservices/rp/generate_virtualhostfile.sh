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
if [ -z "$1" ]; then
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

OUTPUT=$(heat stack-list $OS_STACKNAME)
SERVICE=""
IP=""
while read LINE;
do
    if [ grep "_instance_internal_ip" "$LINE" ]; then
        SERVICE=$(echo "$LINE" | grep -Po '[a-z]+_instance' | sed 's/_instance//')
    fi
    
    if [ grep "output_value" "$LINE" ]; then
        IP=$()
    fi
    
    if [ grep '{' "$LINE" ]; then
        SERVICE=""
        IP=""
    fi
    
    if [ -n "$IP" ] && [ -n "$SERVICE" ]; then
        echo "    # Redirection for service $SERVICE" >> $OUT_FILE
        echo "    ProxyPass /$SERVICE http://$IP:8090/" >> $OUT_FILE
        echo "    ProxyPassReverse /$SERVICE http://$IP:8090/" >> $OUT_FILE
        echo "" >> $OUTPUT
        
        SERVICE=""
        IP=""
    fi
done

echo "    <Proxy>
        Order Allow,Deny
        Allow from all
    </Proxy>

    ServerName localhost
</VirtualHost>" >> $OUT_FILE
