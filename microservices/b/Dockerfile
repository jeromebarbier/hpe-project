FROM debian:jessie
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
apt-get install -y python3 python3-flask
RUN apt-get install -y imagemagick
RUN useradd b
COPY config.py b.conf b.py /home/b/
COPY prices /home/b/prices/
RUN chown -R b:b /home/b/
EXPOSE 8090
USER b
WORKDIR /home/b
CMD ["./b.py"]
