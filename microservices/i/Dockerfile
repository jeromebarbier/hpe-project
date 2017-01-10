FROM debian:jessie
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
apt-get install -y python3 python3-flask
RUN apt-get install -y imagemagick
RUN useradd i
COPY config.py i.conf i.py /home/i/
RUN chown -R i:i /home/i/
EXPOSE 8090
USER i
WORKDIR /home/i
CMD ["./i.py"]
