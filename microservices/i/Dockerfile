FROM debian:jessie
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
apt-get install -y python3 python3-flask python3-pip python3-dev libmysqlclient-dev python3-mysql.connector
RUN useradd i
COPY my.cnf prestashop_fullcustomer.dump.sql create_database.sh config.py i.conf i.py /home/i/
RUN chown -R i:i /home/i/
RUN chmod +x /home/i/create_database.sh
RUN /home/i/create_database.sh
CMD ["cat", "/etc/mysql/my.cnf"]
EXPOSE 8093
USER i
WORKDIR /home/i
CMD ["/usr/bin/python3", "i.py", "root", "debian", "localhost", "prestashop"]
