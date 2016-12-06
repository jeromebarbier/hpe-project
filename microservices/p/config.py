# coding=utf-8

import configparser

# Initialise global variable
logger = None
w = None


def initialise_p():
    """Define p global object so it can be called from anywhere."""
    global p
    p = P()


class W(object):
    def __init__(self):
        self.NAME = "Microservice p"
        self.VERSION = "0.1"
        #
        # Configuration file
        self.conf_file = pConfiguration("p.conf")


class pConfiguration(object):

    def __init__(self, configuration_file):
        self.config = configparser.ConfigParser(allow_no_value=True)
        self.config.read(configuration_file)

    def get_p_port(self):
        return self.config.get("p", "port")

    def get_p_tmpfile(self):
        return self.config.get("p", "tmpfile")

    def get_p_tempo(self):
        return self.config.get("p", "tempo")

    def get_p_debug(self):
        return self.config.get("p", "debug")
