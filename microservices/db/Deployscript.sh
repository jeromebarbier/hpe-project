#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

apt-get install -y mysql-server

# Create a new user
USERNAME="admin"
PASSWORD="admin"
service mysql restart
mysql -uroot -e "CREATE USER '$USERNAME'@'%' IDENTIFIED BY '$PASSWORD'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'%'"

# Update configuration to allow external connections
CONFIG_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
MYSQL_CONFIG=""
while read CONF_LINE;
do
    echo "$CONF_LINE" | grep "bind-address " > /dev/null
    if [  ]; then
        MYSQL_CONFIG="$MYSQL_CONFIG\nbind-address            = 0.0.0.0"
    else
        MYSQL_CONFIG="$MYSQL_CONFIG\n$CONF_LINE"
    fi
done < $CONFIG_FILE

echo "$MYSQL_CONFIG" > $CONFIG_FILE

service mysql restart

# Set-up the DB
mysql -u$USERNAME -p$PASSWORD < prestashop_fullcustomer.dump.sql

exit $?
