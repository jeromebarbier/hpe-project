FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get install -y python-heatclient

# Setup a valid Apache config
RUN apt-get -y install apache2
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

# Re-run all
EXPOSE 80
RUN service apache2 restart

WORKDIR /wd

CMD ["bash", "-c", "./generate_virtualhostfile.sh; while true; do spleep(1000); done"]
