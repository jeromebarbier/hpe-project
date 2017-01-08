#############################################################
# Generates a HEAT template the includes the given services #
# To quickly generate a script, add the option -y           #
#############################################################

# Help
if [ "$1" == "help" ]; then
    echo ""
    echo "Usage: $0 [options] <services>"
    echo "Options:"
    echo "   - -s: Don't generate other outputs than the HEAT template"
    echo "   - -y: Don't ask for input (use default values for the template)"
    echo "Services:"
    echo "   - Enumerate the services you want to include in the template"
    echo "Examples:"
    echo "   - Generate a template with default values for services b, w and i:"
    echo "      $0 -y -s b w i"
    echo "   - Generate a personalized template for services b, w and i:"
    echo "      $0 b w i"
    echo ""
    exit 0
fi

# Functions
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

# A bit of configuration
ASSUME_YES="no"
SILENT="no"
while true ;
do
    if [ "$1" == "-y" ]; then
        ASSUME_YES="yes"
    elif [ "$1" == "-s" ]; then
        SILENT="yes"
    else
        break
    fi
    
    shift
done

ask_user "Private network name" "pnetwork" "$ASSUME_YES" "$SILENT" "PRIVATE_NET_NAME"
ask_user "Private network range (CIDR)" "10.0.2.0/24" "$ASSUME_YES" "$SILENT" "CIDR"
ask_user "Private subnetwork name" "psnetwork" "$ASSUME_YES" "$SILENT" "PRIVATE_SUBNET_NAME"
ask_user "Gateway" "10.0.2.254" "$ASSUME_YES" "$SILENT" "GATEWAY"
ask_user "DNS server(s) IP" "10.11.50.1, 8.8.8.8" "$ASSUME_YES" "$SILENT" "DNS"
ask_user "Router name" "router1" "$ASSUME_YES" "$SILENT" "ROUTER_NAME"
ask_user "Public network name" "" "$ASSUME_YES" "$SILENT" "PUBLIC_NET_NAME" # TODO: use this for IP allocation
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

  private_subnet:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: private_net }
      cidr: $CIDR
      name: $PRIVATE_SUBNET_NAME
      dns_nameservers: [ $DNS ]
      gateway_ip: $GATEWAY

  router:
    type: OS::Neutron::Router
    properties:
      name: $ROUTER_NAME
      external_gateway_info:
        network: $EXTERNAL_NET_NAME

  router_interface:
    type: OS::Neutron::RouterInterface
    properties:
      router_id: { get_resource: router }
      subnet_id: { get_resource: private_subnet }
"

# Generates the servers description
while [ -n "$1" ];
do
    echo "  # Description of microservice $1
  ## Its port
  $1_instance_port:
    type: OS::Neutron::Port
    properties:
      network_id: { get_resource: private_net }
      security_groups: [ { get_resource: web_and_ssh_security_group } ]
      fixed_ips:
        - subnet_id: { get_resource: private_subnet }
"

    if [ -n "$PUBLIC_NET_NAME" ]; then
        echo "  # Its floatting IP
  $1_floating_ip:
    type: OS::Neutron::FloatingIP
      properties:
        floating_network_id: { get_param: public_net }
        port_id: { get_resource: $1_instance_port }
"

    OUTPUTS="$OUTPUTS
  $1_instance_ip:
    description: The IP address of the deployed $1 instance
    value: { get_attr: [$1_floating_ip, first_address] }"
  else
    echo "  ## No public network given, service $1 will not be accessible publicly
"
  fi
  
    echo "  ## Its VM
  $1_instance:
    type: OS::Nova::Server
    properties:
      image: ubuntu-deployement-v1
      flavor: m1.small
      networks:
        - port: { get_resource: $1_instance_port }
      user_data: |
        #!/bin/bash
        echo 'export MICSERV=$1' >> /home/ubuntu/.bashrc
    description: This instance describes how to deploy the $1 microservice"
    
    # OUTPUTS="$OUTPUTS"
    
    shift
done

if [ -n "$OUTPUTS" ]; then
    echo ""
    echo "outputs:$OUTPUTS"
fi
