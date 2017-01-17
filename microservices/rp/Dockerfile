FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get install -y python-heatclient apache2

# Setup a valid Apache config
RUN a2enmod proxy
RUN a2enmod proxy_http
RUN a2enmod rewrite

# Disable default config
RUN a2dissite 000-default

# Add user
RUN mkdir /wd

# Set a new default website... to reverse proxy
COPY generate_virtualhostfile.sh /wd
RUN a2ensite reverse-list

# Expose Apache's port
EXPOSE 80

WORKDIR /wd

CMD ["bash", "-c", "./generate_virtualhostfile.sh; a2ensite reverse-list; service apache2 restart; while true; do spleep(1000); done"]
