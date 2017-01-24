#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

apt-get install -y mysql-server

# Create a new user
USERNAME="admin"
PASSWORD="admin"
DB_NAME="prestashop"
service mysql restart

echo "Creating user $USERNAME"
mysql -uroot -e "CREATE USER '$USERNAME'@'%' IDENTIFIED BY '$PASSWORD'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'%'"

# Update configuration to allow external connections
echo "Rewriting MySQL configuration"
CONFIG_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
CONFIG_FILE_TMP="${CONFIG_FILE}_tmp"

rm $CONFIG_FILE

while read CONF_LINE;
do
    grep 'bind-address' "$CONF_LINE"
    retval=$?
    if [ $? = 0 ]; then
        echo "bind-address            = 0.0.0.0" >> $CONFIG_FILE_TMP
    else
        echo "$CONF_LINE" >> $CONFIG_FILE_TMP
    fi
done < $CONFIG_FILE

mv $CONFIG_FILE_TMP $CONFIG_FILE

service mysql restart

# Set-up the DB
echo "Setting up the DB"
mysql -u$USERNAME -p$PASSWORD -e "CREATE DATABASE $DB_NAME;"
mysql -u$USERNAME -p$PASSWORD --database="$DB_NAME" < prestashop_fullcustomer.dump.sql

exit $?
