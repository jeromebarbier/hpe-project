# coding=utf-8

import configparser

# Initialise global variable
logger = None
s = None


def initialise_s():
    """Define s global object so it can be called from anywhere."""
    global s
    s = S()


class S(object):
    def __init__(self):
        self.NAME = "Microservice s"
        self.VERSION = "0.1"
        #
        # Configuration file
        self.conf_file = sConfiguration("s.conf")


class sConfiguration(object):

    def __init__(self, configuration_file):
        self.config = configparser.ConfigParser(allow_no_value=True)
        self.config.read(configuration_file)

    def get_s_port(self):
        return self.config.get("s", "port")

    def get_s_tmpfile(self):
        return self.config.get("s", "tmpfile")

    def get_s_tempo(self):
        return self.config.get("s", "tempo")

    def get_s_debug(self):
        return self.config.get("s", "debug")
