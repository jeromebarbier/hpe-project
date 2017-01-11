#!/usr/bin/python3

# This script try to retrieve an IP address based on the microservice
# name

# Call : retrieve_ip.py <SERVICE NAME>

import sys

from lwswift.lwswift import lwswift

service = sys.argv[1]

lws = lwswift()

try:
    ip = lws.get_service(service)
    if (ip != None):
        print(ip)
except Exception:
    pass
