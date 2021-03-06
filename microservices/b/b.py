#!/usr/bin/env python3
# -*- coding: utf-8 -*-


"""Service B gives the button to the customer and lets it play with W"""

import base64
import logging
from logging.handlers import RotatingFileHandler
import pprint
import os
import random
import time
import subprocess
import json
import sys
from flask import Flask
from flask import jsonify
from flask import request
import config

import requests

# Import SWIFT lib
import sys

# Require:
# ln -s ../lwswift lwswift
from lwswift.lwswift import lwswift

# Initialise Flask
app = Flask(__name__)
app.debug = True

# Affect app logger to a global variable so logger can be used elsewhere.
config.logger = app.logger

@app.route("/button/<uid>")
def button(uid):
    config.logger.info("Creating button...")

    data = {
        # The button element
        "html": "<button id=\"elButton\">Jouer !</button>",

        # The associated JS API
        "js": """
        function play() {
            jQuery("#elButton").disable();
	    jQuery("#elButton").addClass("btn-danger");
	    jQuery("#elButton").removeClass("btn-success");
            jQuery.getJSON("/b/click/""" + uid + """", {}, function(r) {
                if(r.ok != undefined) {
                    if(r.ok) {
                        if(jQuery("#elButton").played != undefined) {
                            jQuery("#elButton").played();
                        }
                    } else {
                        jQuery("#elButton").replaceWith(jQuery("<p>" + r.error + "</p>"));
                    }
                }
            }).fail(function() {
                jQuery("#elButton").enable();
	    	jQuery("#elButton").addClass("btn-success");
	    	jQuery("#elButton").removeClass("btn-danger");
                jQuery("#elButton").replaceWith(jQuery("<p>Failed to get an answer from the microservice</p>"));
            });
        }
        
        jQuery("#elButton").on("click", play);
        
        jQuery("#elButton").init.prototype.disable = function() {
            jQuery("#elButton").attr("disabled", true);
        }

        jQuery("#elButton").init.prototype.enable = function() {
            jQuery("#elButton").attr("disabled", false);
        }

        jQuery("#elButton").init.prototype.playedTrigger = function(f) {
            jQuery("#elButton").init.prototype.played = f;
        }

        """
    }

    resp = jsonify(data);

    resp.status_code = 200

    resp.headers["AuthorSite"] = "https://github.com/jeromebarbier/hpe-project"

    add_headers(resp)
    return resp

@app.route("/click/<uid>")
def click(uid):
    config.logger.info("A user asks to play...")
    lwsc = lwswift() # We will have to contact SWIFT
    
    # Well, ask W to define a gift for the user
    # Retrieve W service's IP address
    w_ip = lwsc.get_service("w")
    
    if w_ip is None:
        # Then there is no registered W service
        config.logger.error("No W service registered")
        resp = jsonify({"ok" : False, "error": "Cannot get a W service"});
        resp.status_code = 200
        add_headers(resp)
        return resp
    
    w_answer = requests.get("http://" + w_ip + "/play/" + uid)
    
    # If W had not answered as expected
    if w_answer.status_code != 200:
        # Then W is not able to give a gift
        config.logger.error("W service did not answer as exepected")
        resp = jsonify({"ok" : False, "error": "W service did not answer as expected", "wstatuscode": w_answer.status_code});
        resp.status_code = 200
        add_headers(resp)
        return resp
    
    # W gave an answer!
    # Process save on Swift
    w_answer = w_answer.json()
    print(type(w_answer))
    lwsc.send_picture(uid, w_answer['price'], w_answer['img'])
    
    # Finally say that all is good!
    resp = jsonify({"ok" : True});
    resp.status_code = 200
    add_headers(resp)
    return resp

@app.route("/shutdown", methods=["POST"])
def shutdown():
    """Shutdown server"""
    shutdown_server()
    config.logger.info("Stopping %s...", config.b.NAME)
    return "Server shutting down..."

@app.route("/", methods=["GET"])
def api_root():
    """Root url, provide service name and version"""
    data = {
        "Service": config.b.NAME,
        "Version": config.b.VERSION
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
    if (config.b.conf_file.get_b_debug().title() == 'True'):
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
    app_logfile = "b.log"

    # Change diretory to script one
    try:
        os.chdir(os.path.dirname(sys.argv[0]))
    except FileNotFoundError:
        pass

    # Define a PrettyPrinter for debugging.
    pp = pprint.PrettyPrinter(indent=4)

    # Initialise apps
    config.initialise_b()

    # Configure Flask logger
    configure_logger(app.logger, app_logfile)

    config.logger.info("Starting %s", config.b.NAME)
    app.run(port=int(config.b.conf_file.get_b_port()), host='0.0.0.0')
