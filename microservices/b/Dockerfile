FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get -y install python3\
                         python3-flask\
                         python3-keystoneclient
RUN apt-get -y install python3-swiftclient
RUN useradd b
COPY config.py b.conf b.py /home/b/
RUN chown -R b:b /home/b/
EXPOSE 8090
USER b
WORKDIR /home/b

CMD ["/usr/bin/python3", "./b.py"]
