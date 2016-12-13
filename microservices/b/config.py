# coding=utf-8

import configparser

# Initialise global variable
logger = None
b = None


def initialise_b():
    """Define b global object so it can be called from anywhere."""
    global b
    b = B()


class B(object):
    def __init__(self):
        self.NAME = "Microservice b"
        self.VERSION = "0.1"
        #
        # Configuration file
        self.conf_file = bConfiguration("b.conf")


class bConfiguration(object):

    def __init__(self, configuration_file):
        self.config = configparser.ConfigParser(allow_no_value=True)
        self.config.read(configuration_file)

    def get_b_port(self):
        return self.config.get("b", "port")

    def get_b_tmpfile(self):
        return self.config.get("b", "tmpfile")

    def get_b_tempo(self):
        return self.config.get("b", "tempo")

    def get_b_debug(self):
        return self.config.get("b", "debug")
