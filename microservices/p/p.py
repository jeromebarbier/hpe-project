#!/usr/bin/env python3
# -*- coding: utf-8 -*-


"""Service P tests if the user has a picture or not"""

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
import swiftclient

user = 'account_name:username'
key = 'your_api_key'

conn = swiftclient.Connection(
        user=user,
        key=key,
        authurl='https://objects.dreamhost.com/auth',
)

# Initialise Flask
app = Flask(__name__)
app.debug = True

# Affect app logger to a global variable so logger can be used elsewhere.
config.logger = app.logger


@app.route("/<id>", methods=["GET"])
def api_picture(id):
    """Get the picture for user <id>"""
    config.logger.info("*** Start processing id %s ***", id)

    # Get picture

    # Read the image and encode it to base64
    with open(config.w.conf_file.get_w_tmpfile() + "/" +
              id + "_" + price, mode='rb') as file:

        file_content = file.read()
        img = base64.b64encode(file_content)

    config.logger.debug("Img: %s", img)

    # Add latency on the service to simulate a long process
    time.sleep(int(config.w.conf_file.get_w_tempo()))

    data = {"price": price, "img": img.decode("ascii")}
    resp = jsonify(data)
    resp.status_code = 200
    config.logger.info("*** End processing id %s ***", id)
    add_headers(resp)
    return resp


@app.route("/shutdown", methods=["POST"])
def shutdown():
    """Shutdown server"""
    shutdown_server()
    config.logger.info("Stopping %s...", config.p.NAME)
    return "Server shutting down..."


@app.route("/", methods=["GET"])
def api_root():
    """Root url, provide service name and version"""
    data = {
        "Service": config.p.NAME,
        "Version": config.p.VERSION
    }

    resp = jsonify(data)
    resp.status_code = 200

    resp.headers["AuthorSite"] = "https://github.com/uggla/openstack_lab"

    add_headers(resp)
    return resp


def listprices(path):
    onlyfiles = [f for f in os.listdir(path)
                 if os.path.isfile(os.path.join(path, f))]
    return onlyfiles


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
    if (config.p.conf_file.get_p_debug().title() == 'True'):
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
    app_logfile = "w.log"

    # Change diretory to script one
    try:
        os.chdir(os.path.dirname(sys.argv[0]))
    except FileNotFoundError:
        pass

    # Define a PrettyPrinter for debugging.
    pp = pprint.PrettyPrinter(indent=4)

    # Initialise apps
    config.initialise_w()

    # Configure Flask logger
    configure_logger(app.logger, app_logfile)

    config.logger.info("Starting %s", config.w.NAME)
    app.run(port=int(config.w.conf_file.get_w_port()), host='0.0.0.0')
