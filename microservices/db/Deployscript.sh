#!/bin/bash
USERNAME="admin"
PASSWORD="admin"
DATABASE="prestashop"
CONFIGURATION="/etc/mysql/mysql.conf.d/mysqld.cnf"

export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
apt-get update
apt-get install -y mysql-server

mysql -u root --password=$PASSWORD -e "CREATE DATABASE $DATABASE"
mysql -u root --password=$PASSWORD -e "CREATE USER '$USERNAME'@'%' IDENTIFIED BY '$PASSWORD'"
mysql -u root --password=$PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'%'"
mysql -u root --password=$PASSWORD -e "FLUSH PRIVILEGES"
mysql -u $USERNAME --password=$PASSWORD $DATABASE -e 'source prestashop_fullcustomer.dump.sql'

# Update configuration to allow external connections
echo "Rewriting MySQL configuration"
echo "[mysqld]\nbind-address = 0.0.0.0" > $CONFIGURATION
service mysql restart

exit $?
