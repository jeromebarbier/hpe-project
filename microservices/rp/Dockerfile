FROM ubuntu:14.04
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get install -y apache2

# Add user
# Expose Apache's port
EXPOSE 80

CMD ["bash", "-c", "while true; do sleep 1; done"]
