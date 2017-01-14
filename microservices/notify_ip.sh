#!/usr/bin/python

# This script tells the SWIFT container wich IP address is assignated to the
# microservice instance

# Call : notify_ip.py <SERVICE NAME> <IP ADDRESS>

import sys

from lwswift.lwswift import lwswift

service = sys.argv[1]
ip      = sys.argv[2]

lws = lwswift()
lws.register_service(service, ip)
