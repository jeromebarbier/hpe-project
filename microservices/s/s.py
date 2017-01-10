#!/usr/bin/env python3
# -*- coding: utf-8 -*-


"""Service S tells if a player has already played"""

import base64
import logging
from logging.handlers import RotatingFileHandler
import pprint
import os
import random
import time
import subprocess
import sys
from flask import Flask
from flask import jsonify
from flask import request
import config

import requests

# Import SWIFT lib
import sys
sys.path.append('..') # Your path should contain the path to the folder "microservices"
from lwswift.lwswift import lwswift

# Initialise Flask
app = Flask(__name__)
app.debug = True

# Affect app logger to a global variable so logger can be used elsewhere.
config.logger = app.logger

@app.route("/checkPlayed/<uid>")
def click(uid):
    config.logger.info("Checking if a player has played...")
    lwsc = lwswift() # We will have to contact SWIFT
    
    # Process save on Swift
    price = lwsc.get_object(lwswift.container_pictures_name, uid)
    if price is None:
        data = {
        "html": "<p>User " + uid + " has not played yet.</p>"
    }
    else:
        data = {
        "html": "<p>User " + uid + " has already played.</p>"
    }

    resp = jsonify(data);

    resp.status_code = 200

    resp.headers["AuthorSite"] = "https://github.com/jeromebarbier/hpe-project"

    add_headers(resp)
    return resp


@app.route("/shutdown", methods=["POST"])
def shutdown():
    """Shutdown server"""
    shutdown_server()
    config.logger.info("Stopping %s...", config.s.NAME)
    return "Server shutting down..."

@app.route("/", methods=["GET"])
def api_root():
    """Root url, provide service name and version"""
    data = {
        "Service": config.s.NAME,
        "Version": config.s.VERSION
    }

    resp = jsonify(data)
    resp.status_code = 200

    resp.headers["AuthorSite"] = "https://github.com/jeromebarbier/hpe-project"

    add_headers(resp)
    return resp


def shutdown_server():
    """shutdown server"""
    func = request.environ.get("werkzeug.server.shutdown")
    if func is None:
        raise RuntimeError("Not running with the Werkzeug Server")
    func()


def configure_logger(logger, logfile):
    """Configure logger"""
    formatter = logging.Formatter(
        "%(asctime)s :: %(levelname)s :: %(message)s")
    file_handler = RotatingFileHandler(logfile, "a", 1000000, 1)

    # Add logger to file
    if (config.s.conf_file.get_s_debug().title() == 'True'):
        logger.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)


def add_headers(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers',
                         'Content-Type,Authorization')


if __name__ == "__main__":
    # Vars
    app_logfile = "s.log"

    # Change diretory to script one
    try:
        os.chdir(os.path.dirname(sys.argv[0]))
    except FileNotFoundError:
        pass

    # Define a PrettyPrinter for debugging.
    pp = pprint.PrettyPrinter(indent=4)

    # Initialise apps
    config.initialise_s()

    # Configure Flask logger
    configure_logger(app.logger, app_logfile)

    config.logger.info("Starting %s", config.s.NAME)
    app.run(port=int(config.s.conf_file.get_s_port()), host='0.0.0.0')
