import requests
import swiftclient

import os

class lwswift:
    """
    This class provides a very high-level access to SWIFT's objects containers
    """
    # Default containers
    container_pictures              = "gifts"
    container_pictures_name         = "gifts-names"
    container_services_directory    = "services-directory"
    
    # A bit of configuration
    authurl  = os.getenv("OS_AUTH_URL")
    tenant   = os.getenv("OS_TENANT_NAME")
    user     = os.getenv("OS_USERNAME")
    password = os.getenv("OS_PASSWORD")
    
    def __init__(self):
        """
        Initialize a new SWIFT client
        :raise Exception: If the password to connect to the SWIFT manager is not set
        """
        if lwswift.password == "":
            raise Exception("lwswift: No password providen to connect user " + lwswift.user + " to SWIFT object manager")
        self.connection = None
    
    def __del__(self):
        """
        Destroy the instance, if a connection is running, then close it
        """
        self.close()
    
    
    #########################
    # Connection management #
    #########################
    
    def connect(self):
        """
        Creates a new connection to the SWIFT Object manager
        :raise Exception: If a connection is already activated
        """
        if self.connection is None:
            self.connection = swiftclient.client.Connection(authurl=lwswift.authurl, tenant_name=lwswift.tenant, user=lwswift.user, auth_version='2.0', key=lwswift.password, insecure=True)
        
        else:
            raise Exception("lwswift.connect: Cannot connect: a connection is already initialized for this instance")
    
    def close(self):
        """
        Closes a connection
        """
        if self.connection != None:
            self.connection.close()
            self.connection = None
    
    def check_connection(self):
        """
        Check if a connection is initialized and if not, then initialize one
        """
        if self.connection is None:
            self.connect()
    
    
    ######################
    # Objects management #
    ######################
    
    def put_object(self, container, name, value):
        """
        Puts an object in the given container
        :param container: The SWIFT container's name
        :param name: The object's name (the key to retrieve it)
        :param value: The object's content
        """
        self.check_connection() # Ensure there is an active connection
        self.connection.put_object(container, name, value)
        
    def get_object(self, container, name):
        """
        Retrieve an object in the given container
        :param container: The SWIFT container's name
        :param name: The object's name (the SWIFT's key)
        :return: The object's value or None if the Object is not readable
        """
        self.check_connection() # Ensure we get a connection
        obj = None
        try:
            r, obj = self.connection.get_object(container, name)
            obj = obj.decode('utf-8')
        except Exception as e:
            # print(e)
            pass # The return value for "error" is None
        return obj
    
    
    #########################
    # High-level procedures #
    #########################
    
    def send_picture(self, user_id, picture_name, picture_bytes):
       """
       Sends a picture to SWIFT manager
       :param user_id: An identifier to retrieve the picture, recommended to use the user id
       :param picture_name: The picture's name
       :picture_bytes: The picture's bytes
       """
       self.put_object(lwswift.container_pictures_name, user_id, picture_name)
       self.put_object(lwswift.container_pictures, user_id, picture_bytes)
    
    def get_service(self, name):
        """
        Try to retrieve a micro-service's IP address using SWIFT
        :param name: The microservice's name (in ["b", "i", "p", "w", "s"])
        :raise Exception: When the requested Microservice name is not valid
        :return: The requested IP address or None if there is no such service registered
        """
        if name in ["b", "i", "p", "w", "s"]:
            return self.get_object(lwswift.container_services_directory, name)
        else:
            raise Exception("lwsift.get_service: Micro-service " + name + " is not a valid service")
    
    def register_service(self, name, ip):
        """
        Registers a new microservice's IP address into the directory
        :param name: The microservice's name (in ["b", "i", "p", "w", "s"])
        :param ip: The microservice's IP address
        :raise Exception: When the requested Microservice name is not valid
        """
        if name in ["b", "i", "p", "w", "s"]:
            self.put_object(lwswift.container_services_directory, name, ip)
        else:
            raise Exception("lwsift.get_service: Micro-service " + name + " is not a valid service")
