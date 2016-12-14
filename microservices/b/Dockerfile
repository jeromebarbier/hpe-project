FROM fedora

RUN dnf clean all
RUN dnf update && dnf clean all
RUN dnf install -y python3 python3-flask python3-keystoneclient && dnf clean all
RUN rpm -i python3-swiftclient.rpm
RUN useradd b
COPY config.py b.conf b.py /home/b/
RUN chown -R b:b /home/b/
EXPOSE 8090
USER b
WORKDIR /home/b

CMD ["/usr/bin/python3", "./b.py"]
