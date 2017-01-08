#############################################################
# Generates a HEAT template the includes the given services #
# To quickly generate a script, add the option -y           #
#############################################################

# Functions
function ask_user() {
    # This function asks the user to give a value according to a question
    # And a default value
    # $1 The question
    # $2 The default value
    # $3 Set to "yes" to automatically accept the default value
    # $4 The variable to declare globally with the user's answer as value
    VAL=""
    
    if [ "yes" != "$3" ]; then
        printf "$1 [$2]: "
        read VAL
    fi
    
    if [ -z "$VAL" ]; then
        VAL="$2"
    fi
    
    printf -v "$4" "$VAL"
}

# A bit of configuration
ASSUME_YES="no"
if [ "$1" == "-y" ]; then
    ASSUME_YES="yes"
    shift
fi

ask_user "Private network name" "pnetwork" "$ASSUME_YES" "PRIVATE_NET_NAME"
ask_user "Private network range (CIDR)" "10.0.1.0/24" "$ASSUME_YES" "CIDR"
ask_user "Gateway" "10.0.1.254" "$ASSUME_YES" "GATEWAY"
ask_user "DNS server IP" "10.11.50.1" "$ASSUME_YES" "DNS"
ask_user "Router name" "router1" "$ASSUME_YES" "ROUTER_NAME"
ask_user "Public network name" "" "$ASSUME_YES" "PUBLIC_NET_NAME"

# Generator
DATE=$(date)

OUTPUTS=""

echo "heat_template_version: 2015-10-15
description: This template creates the whole stack, generated on $DATE"

echo ""
echo "ressources:"

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
      network_id: $PRIVATE_NET_NAME
      cidr: $CIDR
      dns: $DNS
      gateway_ip: $GATEWAY

  router:
    type: OS::Neutron::Router
    properties:
      name: $ROUTER_NAME

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
      network: private
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
      parameter: \"MICSERV=$1\"
    networks:
      - port: { get_resource: $1_instance_port }
    description: This instance describes how to deploy the $1 microservice"
    
    OUTPUTS="$OUTPUTS
  $1_instance_ip:
    description: The IP address of the deployed $1 instance
    value: { get_attr: [$1_floating_ip, first_address] }"
    
    shift
done

echo ""
echo "outputs:$OUTPUTS"
