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
CONFIG_FILE_INITIAL_CONTENT=$(cat $CONFIG_FILE)

rm $CONFIG_FILE

while read CONF_LINE;
do
    echo "$CONF_LINE" | grep "bind-address " > /dev/null
    if [  ]; then
        echo "bind-address            = 0.0.0.0" >> $CONFIG_FILE
    else
        echo "$CONF_LINE" >> $CONFIG_FILE
    fi
done <<< "$CONFIG_FILE_INITIAL_CONTENT"

service mysql restart

# Set-up the DB
mysql -u$USERNAME -p$PASSWORD < prestashop_fullcustomer.dump.sql

exit $?
