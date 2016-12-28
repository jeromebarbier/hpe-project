import requests
import swiftclient

class lwswift:
    # Default containers
    container_pictures = "gifts"
    container_pictures_name = "gift-names"
    
    # A bit of configuration
    authurl = "http://10.11.50.26:5000/v2.0"
    tenant  = "groupe6"
    user    = "groupe6"
    password = ""
    
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
    
    def connect(self):
        """
        Creates a new connection to the SWIFT Object manager
        :raise Exception: If a connection is already activated
        """
        if self.connection is None:
            self.connection = swiftclient.client.Connection(authurl=lwswift.authurl, tenant_name=lwswift.tenant, user=lwswift.user, auth_version='2.0', key=lwswift.password, insecure=True)
        
        else:
            raise Exception("lwswift: Cannot connect: a connection is already initialized for this instance")
    
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
    
    def send_picture(self, user_id, picture_name, picture_bytes):
       """
       Sends a picture to SWIFT manager
       :param user_id: An identifier to retrieve the picture, recommended to use the user id
       :param picture_name: The picture's name
       :picture_bytes: The picture's bytes
       """
       
       self.check_connection() # Ensure there is an active connection
       
       self.connection.put_object(lwswift.container_pictures_name, user_id, picture_name)
       self.connection.put_object(lwswift.container_pictures, user_id, picture_bytes)
    
