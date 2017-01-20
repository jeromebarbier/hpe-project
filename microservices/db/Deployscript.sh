#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

apt-get install -y mysql-server

# Create a new user
USERNAME="admin"
PASSWORD="admin"
service mysql restart
mysql -uroot -e "CREATE USER '$USERNAME'@'%' IDENTIFIED BY '$PASSWORD'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%'"

# Update configuration to allow external connections
CONFIG_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
MYSQL_CONFIG=$(cat $CONFIG_FILE)
echo "$MYSQL_CONFIG" | grep -L "bind-address " > $CONFIG_FILE

service mysql restart

# Set-up the DB
mysql -u$USERNAME -p$PASSWORD < prestashop_fullcustomer.dump.sql

exit $?
