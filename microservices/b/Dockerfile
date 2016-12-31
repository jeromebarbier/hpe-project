FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get -y install python3\
                         python3-flask\
                         python3-keystoneclient
RUN apt-get -y install python3-swiftclient
RUN useradd b
COPY config.py b.conf b.py /home/b/b/
COPY lwswift/__init__.py lwswift/lwswift.py /home/b/lwswift/
RUN chown -R b:b /home/b/
EXPOSE 8091
USER b
WORKDIR /home/b/b

CMD ["/usr/bin/python3", "./b.py"]
