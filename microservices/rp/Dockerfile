FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update

# Setup a valid Apache config
RUN apt-get -y install apache2
RUN a2enmod proxy
RUN a2enmod proxy_http
RUN a2enmod rewrite

# Disable default config
RUN a2dissite 000-default

# Set a new default website... to reverse proxy
COPY reverse-list.site /etc/apache2/sites-available/reverse-list.conf
RUN a2ensite reverse-list

# Re-run all
RUN service apache2 restart

CMD ["while true; do spleep(1000); done"]
