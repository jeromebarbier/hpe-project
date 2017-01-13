FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get -y install python3\
                         python3-flask\
                         python3-keystoneclient
RUN apt-get -y install python3-swiftclient
RUN useradd s
COPY config.py s.conf s.py /home/s/s/
COPY lwswift/__init__.py lwswift/lwswift.py /home/s/lwswift/
RUN chown -R s:s /home/s/
EXPOSE 8094
USER s
WORKDIR /home/s/s

CMD ["/usr/bin/python3", "./s.py"]
