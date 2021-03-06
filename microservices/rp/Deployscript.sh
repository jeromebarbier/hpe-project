#!/bin/bash

apt-get install -y python-heatclient apache2

# Configuring the Apache server
a2enmod proxy
a2enmod proxy_http
a2enmod rewrite
a2dissite 000-default

# Generate the site configuration
chmod +x generate_virtualhostfile.sh
./generate_virtualhostfile.sh
a2ensite reverse-list

# TODO: Maxime
mv index.html /var/www/html/index.html
mv stylesheet.css /var/www/html/stylesheet.css

# And finally, take all of that in consideration
service apache2 restart
