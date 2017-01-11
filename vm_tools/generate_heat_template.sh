#############################################################
# Generates a HEAT template the includes the given services #
# To quickly generate a script, add the option -y           #
#############################################################

# Help
if [ "$1" == "help" ]; then
    echo ""
    echo "Usage: $0 [options] <services|-nsn>"
    echo "Options:"
    echo "   - -s: Don't generate other outputs than the HEAT template"
    echo "   - -y: Don't ask for input (use default values for the template)"
    echo "   - -nfip: Generate the script without the floating IP allocation"
    echo "   - -ps <name>: Name of the public server (which will get a floatting IP)"
    echo "Services:"
    echo "   - Enumerate the services you want to include in the template"
    echo "-nsn:"
    echo "   Inside the enumeration of instances, tells to put the following"
    echo "   microservices into a new subnetwork"
    echo "Notice: You must source your openRC file to use this generator"
    echo "Examples:"
    echo "   - Generate a template with default values for services b, w and i:"
    echo "      $0 -y -s b w i"
    echo "   - Generate a personalized template for services b, w and i:"
    echo "      $0 b w i"
    echo "   - Generates the microservices b and w on 2 different networks"
    echo "      $0 b -nsn w"
    echo ""
    exit 0
fi

# Functions

#################
# IP management #
#################
function ip_string2int() {
    # Transform a string IP address to integer representation
    # $1 The IP address (CIDR masks are removed)

    # IP and its Mask
    IP=$(echo "$1" | cut -d'/' -f1)

    # IP to int
    a=$(echo $IP | cut -d'.' -f1)
    b=$(echo $IP | cut -d'.' -f2)
    c=$(echo $IP | cut -d'.' -f3)
    d=$(echo $IP | cut -d'.' -f4)
    IP_AS_INT=$(((((((a << 8) | b) << 8) | c) << 8) | d))

    echo $IP_AS_INT
}

function ip_int_last_of_range() {
    # Last IP of the given range
    # $1 The IP address and its CIDR mask

    CIDR_MASK=$(echo "$1" | cut -d'/' -f2)
    BIT_MASK=0
    NB_BITS_TO_PUT_TO_ONE=$((32-$CIDR_MASK))
    while [ $NB_BITS_TO_PUT_TO_ONE != 0 ];
    do
        BIT_MASK=$(((BIT_MASK << 1) + 1))
        NB_BITS_TO_PUT_TO_ONE=$(($NB_BITS_TO_PUT_TO_ONE - 1))
    done

    IP_AS_INT=$(ip_string2int "$1")
    LAST_IP_AS_INT=$((IP_AS_INT | BIT_MASK))

    echo $LAST_IP_AS_INT
}

function ip_int2string() {
    # Transform a int representation of IP address to string
    # $1 The integer to transform
    NEW_IP=""
    local ui32=$1
    local n
    for n in 1 2 3 4; do
        NEW_IP=$((ui32 & 0xff))${NEW_IP:+.}$NEW_IP
        ui32=$((ui32 >> 8))
    done

    echo $NEW_IP
}

#############################
# Script-oriented functions #
#############################

function ask_user() {
    # This function asks the user to give a value according to a question
    # And a default value
    # $1 The question
    # $2 The default value
    # $3 Set to "yes" to automatically accept the default value
    # $4 Set to "yes" to not generate outputs (but still read inputs)
    # $5 The variable to declare globally with the user's answer as value
    VAL=""
    
    if [ "yes" != "$4" ]; then
        printf "$1 [$2]: "
    fi
    
    if [ "yes" != "$3" ]; then
        read VAL
    else
        if [ "yes" != "$4" ]; then
            # Don't simulate user input if we're not supposed to output stuff!
            echo "$2"
        fi
    fi
    
    if [ -z "$VAL" ]; then
        VAL="$2"
    fi
    
    printf -v "$5" "$VAL"
}

export SUBNET_NR=0
function generate_subnet() {
    # This function generates a new subnetwork

    NEXT_SUBNET_ID=$(($SUBNET_NR + 1))
    printf -v "SUBNET_NR" "$NEXT_SUBNET_ID"

    # Compute new CIDR
    if [ "$SUBNET_NR" != "1" ]; then
        # Compute the first IP address of the next network
        LAST_IP_IN_RANGE=$(ip_int_last_of_range $CIDR)
        NEXT_NETWORK_IP_AS_INT=$(($LAST_IP_IN_RANGE + 1))
        NEXT_NETWORK_IP=$(ip_int2string $NEXT_NETWORK_IP_AS_INT)

        MASK=$(echo $CIDR | cut -d'/' -f2)
        CIDR="$NEXT_NETWORK_IP/$MASK"
    fi

    GATEWAY=$(ip_int2string $(($(ip_int_last_of_range $CIDR) - 1)))

    echo "  # Private subnetwork #$SUBNET_NR, CIDR=$CIDR, gateway=$GATEWAY
  private_subnet$SUBNET_NR:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net }
      cidr: $CIDR
      name: $PRIVATE_SUBNET_NAME$SUBNET_NR
      dns_nameservers: [ $DNS ]
      gateway_ip: $GATEWAY

  router_interface$SUBNET_NR:
    type: OS::Neutron::RouterInterface
    properties:
      router_id: { get_resource: router }
      subnet_id: { get_resource: private_subnet$SUBNET_NR }
"
}

# Check if user sourced its OpenRC
if [ -z "$OS_TENANT_NAME" ]; then
    echo "Please source your openrc file before running this generator"
    exit 1
fi

# A bit of configuration
ASSUME_YES="no"
SILENT="no"
FLOATING_IP="yes"
PUBLIC_SERVER=""
while true ;
do
    if [ "$1" == "-y" ]; then
        ASSUME_YES="yes"
    elif [ "$1" == "-s" ]; then
        SILENT="yes"
    elif [ "$1" == "-nfip" ]; then
        FLOATING_IP="no"
    elif [ "$1" == "-ps" ]; then
        PUBLIC_SERVER="$2"
        shift
    else
        break
    fi
    
    shift
done

ask_user "Private network name" "pnetwork" "$ASSUME_YES" "$SILENT" "PRIVATE_NET_NAME"
ask_user "First private network range (CIDR)" "10.0.2.0/24" "$ASSUME_YES" "$SILENT" "CIDR"
ask_user "Private subnetwork name" "psnetwork" "$ASSUME_YES" "$SILENT" "PRIVATE_SUBNET_NAME"
ask_user "DNS server(s) IP" "10.11.50.1, 8.8.8.8" "$ASSUME_YES" "$SILENT" "DNS"
ask_user "Router name" "router1" "$ASSUME_YES" "$SILENT" "ROUTER_NAME"
ask_user "External network ID" "0ff834d9-5f65-42bb-b1e9-542526a3c56e" "$ASSUME_YES" "$SILENT" "EXTERNAL_NET_NAME" # TODO: Automatically get ID... but need to speak with HPE team, I am unable to list the networks from command line right now (neutron net-list)


# Generator
DATE=$(date)
HOST=$(hostname)

OUTPUTS=""

echo "heat_template_version: 2015-10-15
description: This template creates the whole stack, generated on $DATE using $HOST"

echo ""
echo "resources:"

# Generates the security group, attached to the network
echo "  #Description of the security group
  web_and_ssh_security_group:
    type: OS::Neutron::SecurityGroup
    properties:
      rules:
        - protocol: tcp
          remote_ip_prefix: 0.0.0.0/0
          port_range_min: 80
          port_range_max: 80
        - protocol: tcp
          remote_ip_prefix: 0.0.0.0/0
          port_range_min: 443
          port_range_max: 443
        - protocol: tcp
          remote_ip_prefix: 0.0.0.0/0
          port_range_min: 22
          port_range_max: 22
"

# Generates the network description
echo "  # Description of network capabilities
  private_net:
    type: OS::Neutron::Net
    properties:
      name: $PRIVATE_NET_NAME

  router:
    type: OS::Neutron::Router
    properties:
      name: $ROUTER_NAME
      external_gateway_info:
        network: $EXTERNAL_NET_NAME
"

# Generate the first subnetwork
generate_subnet

# Generates the servers description
while [ -n "$1" ];
do
    if [ "$1" == "-npn" ]; then
        # Asked for a new subnetwork
        generate_subnet
        shift
        continue
    fi

    echo "  # Description of microservice $1
  ## Its port
  $1_instance_port:
    type: OS::Neutron::Port
    properties:
      network_id: { get_resource: private_net }
      security_groups: [ { get_resource: web_and_ssh_security_group } ]
      fixed_ips:
        - subnet_id: { get_resource: private_subnet$SUBNET_NR }
"

    if [ -n "$EXTERNAL_NET_NAME" ] && [ "yes" == "$FLOATING_IP" ] && [ "$PUBLIC_SERVER" == "$1" ]; then
        echo "  # Its floatting IP
  $1_floating_ip:
    type: OS::Neutron::FloatingIP
    properties:
      floating_network_id: $EXTERNAL_NET_NAME
      port_id: { get_resource: $1_instance_port }
"
    OUTPUTS="$OUTPUTS
  # The floating IP address for service $1
  $1_instance_floating_ip:
    description: The floating IP address of the deployed $1 instance
    value: { get_attr: [$1_floating_ip, floating_ip_address] }"
  fi
  
    echo "  ## Its software config
  $1_init:
    type: OS::Heat::SoftwareConfig
    properties:
      group: ungrouped
      config: |
        #!/bin/sh
        echo 'Initialize MICSERV environment variable'
        echo 'export MICSERV=$1' >> /home/ubuntu/.bashrc
        
        echo 'Add some environment variables required to access the Openstack setup'
        echo 'export OS_TENANT_NAME=\"$OS_TENANT_NAME\"' >> /home/ubuntu/.bashrc
        echo 'export OS_USERNAME=\"$OS_USERNAME\"' >> /home/ubuntu/.bashrc
        echo 'export OS_PASSWORD=\"$OS_PASSWORD\"' >> /home/ubuntu/.bashrc
        echo 'export OS_AUTH_URL="$OS_AUTH_URL"' >> /home/ubuntu/.bashrc
"
  
    echo "  ## Its VM
  $1_instance:
    type: OS::Nova::Server
    properties:
      image: ubuntu-deployement-v1
      flavor: m1.small
      networks:
        - port: { get_resource: $1_instance_port }
      user_data:
        get_resource: $1_init
      user_data_format: SOFTWARE_CONFIG
    description: This instance describes how to deploy the $1 microservice
"
    
    OUTPUTS="$OUTPUTS
  # $1 server internal network IP address
  $1_instance_internal_ip:
    description: Fixed ip assigned to the server on private network
    value: { get_attr: [$1_instance, networks, net0, 0]}"
    
    shift
done

if [ -n "$OUTPUTS" ]; then
    echo ""
    echo "outputs:$OUTPUTS"
fi
