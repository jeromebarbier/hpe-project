FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y python3 python3-flask python3-mysql.connector

RUN useradd i
COPY  config.py i.conf i.py /home/i/

RUN chown -R i:i /home/i/

EXPOSE 8093

USER i
WORKDIR /home/i

CMD ["/usr/bin/python3", "./i.py"]
