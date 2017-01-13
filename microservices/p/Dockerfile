FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get install -y python3\
			python3-flask\
			python3-keystoneclient
RUN apt-get install -y python3-swiftclient
RUN useradd p
COPY config.py p.conf p.py /home/p/p/
COPY lwswift/__init__.py lwswift/lwswift.py /home/p/lwswift/
RUN chown -R p:p /home/p/
EXPOSE 8092
USER p
WORKDIR /home/p/p
CMD ["/usr/bin/python3", "./p.py"]
