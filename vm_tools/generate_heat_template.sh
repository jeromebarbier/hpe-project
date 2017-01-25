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
    echo "   - -sf: Safe mode, only if RP is included, force it to wait for all "
    echo "          services to have succeeded to deploy before being deployed"
    echo "   - -gb <NAME>: Force the deployed servers to focus on one single GIT"
    echo "                 branch (master by default)"
    echo ""
    echo "Services:"
    echo "   - Enumerate the services you want to include in the template"
    echo ""
    echo "-nsn:"
    echo "   Inside the enumeration of instances, tells to put the following"
    echo "   microservices into a new subnetwork"
    echo "Notice: You must source your openRC file to use this generator"
    echo ""
    echo "Examples:"
    echo "   - Generate a template with default values for services b, w and i:"
    echo "      $0 -y -s b w i"
    echo "   - Generate a personalized template for services b, w and i:"
    echo "      $0 b w i"
    echo "   - Generates the microservices b and w on 2 different networks:"
    echo "      $0 b -nsn w"
    echo "   - Generates the HPE TP whole configuration:"
    echo "      $0 -ps rp rp b w s p -npn i"
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
RP_SAFE="no"
GIT_BRANCH="master"
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
    elif [ "$1" == "-gb" ]; then
        GIT_BRANCH="$2"
        shift
    elif [ "$1" == "-sf" ]; then
        RP_SAFE="yes"
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
ask_user "External network ID" "0ff834d9-5f65-42bb-b1e9-542526a3c56e" "$ASSUME_YES" "$SILENT" "EXTERNAL_NET_NAME"
ask_user "SSH key to use path" "$HOME/.ssh/id_rsa.pub" "$ASSUME_YES" "$SILENT" "SSH_KEY"


# Generator
DATE=$(date)
HOST=$(hostname)

OUTPUTS=""

SSH_KEY=$(cat "$SSH_KEY")
if [ $? != 0 ]; then
    echo "SSH key cannot be found at $SSH_KEY"
    exit 1
fi

# Pre-analyze

# Generate RP dependancies, check if there is a DB
RP_WAIT_COUNT=0 # Safe mode
RP_WAIT_CONDS="" # Non-safe mode
BUILDING_WITH_RP="no"
BUILDING_WITH_DB="no"
for SERV in "$@"
do
    if [ "$SERV" != "rp" ] && [ "$SERV" != "-npn" ]; then
        # Safe mode
        RP_WAIT_COUNT=$((RP_WAIT_COUNT + 1))
        
        # Non-safe mode
        if [ ${#RP_WAIT_CONDS} != 0 ]; then
            RP_WAIT_CONDS="$RP_WAIT_CONDS,"
        fi
        RP_WAIT_CONDS="$RP_WAIT_CONDS ${SERV}_instance"
    fi
    
    if [ "$SERV" == "rp" ]; then
        BUILDING_WITH_RP="yes"
    fi
    
    if [ "$SERV" == "db" ]; then
        BUILDING_WITH_DB="yes"
        ALEATORY_DB_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32)
    fi

    if [ "$SERV" == "bd" ]; then
        # Special Jerome !
        echo "WARNING: Asked for service BD, current mispelling of DB" >&2
    fi
done

# The generation

echo "heat_template_version: 2015-10-15
description: This template creates the whole stack, generated on $DATE using $HOST"

echo ""
echo "resources:"

# Generates the security group, attached to the network
echo "  #Description of the security group for SSH
  ssh_security_group:
    type: OS::Neutron::SecurityGroup
    properties:
      rules:
        - protocol: tcp
          remote_ip_prefix: 0.0.0.0/0
          port_range_min: 22
          port_range_max: 22
"

echo "  #Description of the security group for Web server
  web_security_group:
    type: OS::Neutron::SecurityGroup
    properties:
      rules:
        - protocol: tcp
          remote_ip_prefix: 0.0.0.0/0
          port_range_min: 80
          port_range_max: 80
"

if [ "$BUILDING_WITH_DB" == "yes" ]; then
    echo "  #Description of the security group for MySQL server
  mysql_security_group:
    type: OS::Neutron::SecurityGroup
    properties:
      rules:
        - protocol: tcp
          remote_ip_prefix: 0.0.0.0/0
          port_range_min: 3306
          port_range_max: 3306
"
fi

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

    # Send some warning
    if [ "$1" == "b" ] && [ "$BUILDING_WITH_RP" == "no" ]; then
        # B uses RP to contact W so emits a warning if B is built without RP
        echo "WARNING: Building B without RP" >&2
    fi
    if [ "$BUILDING_WITH_DB" == "no" ]; then
        if [ "$1" == "b" ]; then
            # B uses DB (according to specs) to find the admins that should get an email
            echo "WARNING: Building B without DB" >&2
        fi

        if [ "$1" == "i" ]; then
            # B uses DB to authenticate users
            echo "WARNING: Building I without DB" >&2
        fi
    fi

    # Generate code !

    SEC_GROUPS="{ get_resource: web_security_group }, { get_resource: ssh_security_group }"
    if [ "$1" == "db" ]; then
        SEC_GROUPS="$SEC_GROUPS, { get_resource: mysql_security_group }"
    fi

    echo "  # Description of microservice $1
  ## Its port
  $1_instance_port:
    type: OS::Neutron::Port
    properties:
      network_id: { get_resource: private_net }
      security_groups: [ $SEC_GROUPS ]
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

    # First boot executed script

    VMU="ubuntu"
    VMU_HOME="/home/$VMU/"
    VMU_HPE_PROJECT="${VMU_HOME}hpe-project/"
    VMU_PROJECT_CONF_FILE_NAME="dynamite"
    VMU_PROJECT_CONF_FILE="$VMU_HOME.$VMU_PROJECT_CONF_FILE_NAME"

    echo "  ## Its software config
  $1_init:
    type: OS::Heat::SoftwareConfig
    properties:
      group: ungrouped"

    echo "      config:
        str_replace:
          template: |"

    echo "            #!/bin/sh
            echo '***************************************'
            echo '* Start to prepare the VM for service *'
            echo '***************************************'

            echo '** Initialize MICSERV environment variable to value $1 **'
            echo 'export MICSERV=\"$1\"' >> $VMU_PROJECT_CONF_FILE

            echo '** Add some environment variables required to access the Openstack setup **'
            echo 'export OS_AUTH_URL="$OS_AUTH_URL"' >> $VMU_PROJECT_CONF_FILE
            echo 'export OS_TENANT_NAME=\"$OS_TENANT_NAME\"' >> $VMU_PROJECT_CONF_FILE
            echo 'export OS_USERNAME=\"$OS_USERNAME\"' >> $VMU_PROJECT_CONF_FILE
            echo 'export OS_PASSWORD=\"$OS_PASSWORD\"' >> $VMU_PROJECT_CONF_FILE
            echo 'export OS_STACKNAME=\"THE_STACK_NAME\"' >> $VMU_PROJECT_CONF_FILE"

    if [ "$BUILDING_WITH_RP" == "yes" ] && [ "$1" != "rp" ]; then
        # If RP is buit, then other services MUST know its IP address
        # to be able to contact others services
        echo "            echo 'export OS_RP_IP=\"THE_RP_SERV_IP\"' >> $VMU_PROJECT_CONF_FILE"
    fi

    if [ "$BUILDING_WITH_DB" == "yes" ]; then
        # If DB is buit, then other services MUST know its IP address
        if [ "$1" != "db" ]; then
            echo "            echo 'export OS_DB_IP=\"THE_DB_SERV_IP\"' >> $VMU_PROJECT_CONF_FILE"
        fi
        echo "            echo 'export OS_DB_USERNAME=\"prestashop\"' >> $VMU_PROJECT_CONF_FILE"
        echo "            echo 'export OS_DB_PASSWORD=\"$ALEATORY_DB_PASSWORD\"' >> $VMU_PROJECT_CONF_FILE"
        echo "            echo 'export OS_DB_DBNAME=\"prestashop\"' >> $VMU_PROJECT_CONF_FILE"
    fi

    echo "            echo 'source $VMU_PROJECT_CONF_FILE' >> $VMU_HOME.bashrc

            echo '** Authorize user to log via its SSH Key **'
            echo '$SSH_KEY' >> $VMU_HOME.ssh/authorized_keys

            echo '** Make sure that the system packet index is up to date **'
            apt-get update

            echo '** Make sure GIT is available **'
            apt-get -y install git

            echo '** Get service code from GIT repository **'
            mkdir $VMU_HPE_PROJECT
            git clone -b $GIT_BRANCH --single-branch https://github.com/jeromebarbier/hpe-project.git $VMU_HPE_PROJECT

            echo '** Start service deployement **'
            chmod +x ${VMU_HPE_PROJECT}microservices/deploy_service.sh

            # Directly use bash to be able to handle an environment
            /bin/bash -c 'source $VMU_PROJECT_CONF_FILE
                          cd ${VMU_HPE_PROJECT}microservices
                          ./deploy_service.sh \$MICSERV
                          DEPLOYEMENT_STATE=\$?
                          echo \"** Service deployement script executed, DEPLOYEMENT_STATE=\$DEPLOYEMENT_STATE (should be 0 to be ok) **\"
                          # Propagate result
                          exit \$DEPLOYEMENT_STATE'"

    if [ "$BUILDING_WITH_RP" == "yes" ] && [ "$1" != "rp" ] && [ "$RP_SAFE" == "yes" ]; then
        # Add RP notifiers (safe mode: build only when services are successfully deployed)
        echo "
            # Receive result from subprocess
            DEPLOYEMENT_STATE=\$?
            echo \"** Send a signal to rp (DEPLOYEMENT_STATE=\$DEPLOYEMENT_STATE) **\"
            if [ \$DEPLOYEMENT_STATE -eq 0 ]; then
                echo \"** Deployement succeeds, send a notification of success to HEAT\"
                wc_notify --data-binary '{\"status\": \"SUCCESS\"}'
            else
                echo \"** Deployement failed, send a notification of failure to HEAT\"
                wc_notify --data-binary '{\"status\": \"FAILURE\"}'
            fi"
    fi

    echo "
            echo '******************************************'
            echo '* Finished to prepare the VM for service *'
            echo '******************************************'"

    echo "          params:
            # Get whole stack name
            THE_STACK_NAME: { get_param: 'OS::stack_id' }"

    if [ "$BUILDING_WITH_RP" == "yes" ] && [ "$1" != "rp" ]; then
        if [ "$RP_SAFE" == "yes" ]; then
            # Add the ressource "wc_notify" to be able to notify RP
            echo "            # Notification builder for RP
            wc_notify: { get_attr: [rp_wait_handle, curl_cli] }"
        fi

        echo "            # Give RP's address to other services
            THE_RP_SERV_IP: { get_attr: [ rp_instance_port, fixed_ips, 0, ip_address ] }"

    fi

    if [ "$BUILDING_WITH_DB" == "yes" ] && [ "$1" != "db" ]; then
        echo "            # Give DB's address to other services
            THE_DB_SERV_IP: { get_attr: [ db_instance_port, fixed_ips, 0, ip_address ] }"
    fi

    echo "
  ## Its VM
  $1_instance:
    type: OS::Nova::Server
    properties:
      image: ubuntu1604
      flavor: m1.small
      networks:
        - port: { get_resource: $1_instance_port }
      user_data:
        get_resource: $1_init
      user_data_format: SOFTWARE_CONFIG
    description: This instance describes how to deploy the $1 microservice"

    if [ "$1" == "rp" ]; then
        if [ "$RP_SAFE" == "yes" ]; then
            # Safe mode: Wait conditions to ensure that all services are registered and ready
            echo "    depends_on: rp_wait_condition
"

            echo "  ## Its wait condition (RP waits for all services to be deployed before being able to be itself deployed)
  rp_wait_handle:
    type: OS::Heat::WaitConditionHandle

  rp_wait_condition:
    type: OS::Heat::WaitCondition
    properties:
      handle: {get_resource: rp_wait_handle}
      count: $RP_WAIT_COUNT
      timeout: 1200 # Suppose that services runs in less than 20 minutes
"
        else
            # Pseudo-safe mode: RP is waiting for the stack to be in "CREATED" state only
            echo "    depends_on: [ $RP_WAIT_CONDS ]
"
            
        fi
    fi

    OUTPUTS="$OUTPUTS
  # $1 server internal network IP address
  $1_instance_internal_ip:
    description: Fixed ip assigned to the server on private network
    value: { get_attr: [ $1_instance, first_address ] }"

    shift
done

if [ -n "$OUTPUTS" ]; then
    echo "outputs:$OUTPUTS"
fi
