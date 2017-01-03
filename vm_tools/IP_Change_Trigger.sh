#!/usr/bin/bash

########################################################################
#                                                                      #
# This script listens to any IP4 changes on a given interface and then #
# triggers user-defined scripts to react to the change                 #
#                                                                      #
# Type "help" to get help                                              #
#                                                                      #
# (cc BY-SA) 2016 Jerome Barbier                                       #
#   Version 2                                                          #
#                                                                      #
########################################################################
if [ $# -lt 2 ] || [ "$1" == "help" ]; then
    echo "Usage: $0 <INTERFACE> <SCRIPT TO TRIGGER ON NEW IP> [<SCRIPT TO TRIGGER ON IP LOOSE>]"
    exit 0
fi

# Get user's values
INTERFACE="$1"
NEW_IP_SH="$2"
DLT_IP_SH="$3"

# Useful function
function trigger() {
    ####################################################
    # Define the action to perform according to the IP #
    # state, and to the availability of the scripts to #
    # trigger                                          #
    ####################################################
    if [ "$1" == "Deleted" ]; then
        if [ -n "$4" ]; then # IP is deleted and there is a script to trigger
            echo "  > Triggers deletion script \"$4\""
            ./$4
        fi
    else
        # IP is newly aquired (script name is required to run the present script)
        echo "  > Triggers procurement script \"$3\" with IP address $2"
        ./$3 "$2"
    fi
}

# First detection of IP address if there is (and check the validity of the interface name)
IFCONFIG=$(ifconfig "$INTERFACE" 2> /dev/null)
if [ $? != 0 ]; then
    echo "Error: Unknown interface $INTERFACE"
    exit 1
fi

echo "Detecting the current IP address on interface $INTERFACE"
IP_ADDR=$(echo "$IFCONFIG" | grep "inet " | cut -d' ' -f10)
TYPE="Deleted"
if [ -n "$IP_ADDR" ]; then
    TYPE="local"
fi

trigger "$TYPE" "$IP_ADDR" "$NEW_IP_SH" "$DLT_IP_SH"

# Change listenning system
echo "Listening for changes on interface $INTERFACE"
while read LINE
do
    # Just look at messages saying that we get or loose an IP address on the interface
    RELEVANT_LINE=$(echo "$LINE" | grep "$INTERFACE  table local  proto kernel  scope host  src")
    
    if [ -z "$RELEVANT_LINE" ]; then
        continue
    fi
    
    # Retrieve the IP address and the message type
    IP_ADDR=$(echo "$RELEVANT_LINE" | rev | cut -d' ' -f1 | rev)
    TYPE=$(echo "$RELEVANT_LINE" | cut -d' ' -f1) # Contains "Deleted" or "local"
    
    # Triggers what need to be triggered
    trigger "$TYPE" "$IP_ADDR" "$NEW_IP_SH" "$DLT_IP_SH"
    
done < <(ip monitor)
