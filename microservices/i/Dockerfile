FROM debian:jessie
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
apt-get install -y python3 python3-flask python3-mysql.connector mysql-server

RUN useradd i
COPY prestashop_fullcustomer.dump.sql create_database.sh config.py i.conf i.py /home/i/
COPY my.cnf /etc/mysql/my.cnf

RUN chown -R i:i /home/i/
RUN chmod +x /home/i/create_database.sh
RUN /home/i/create_database.sh

EXPOSE 8093
WORKDIR /home/i

CMD ["bash", "-c", "service mysql start && source .db_vars && /usr/bin/python3 i.py"]
