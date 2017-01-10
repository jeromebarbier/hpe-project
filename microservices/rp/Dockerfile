FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get -y install apache2
RUN a2enmod proxy_http



RUN service apache2 restart
