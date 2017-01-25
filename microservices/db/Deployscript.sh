#!/bin/bash
source /home/ubuntu/.dynamite
echo "Database Authentication: $OS_DB_USERNAME, $OS_DB_PASSWORD, $OS_DB_NAME"
CONFIGURATION="/etc/mysql/mysql.conf.d/mysqld.cnf"

export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< "mysql-server mysql-server/root_password password $OS_DB_PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $OS_DB_PASSWORD"
apt-get update
apt-get install -y mysql-server mysql-client

mysql -u root --password=$OS_DB_PASSWORD -e "CREATE DATABASE $OS_DB_NAME"
mysql -u root --password=$OS_DB_PASSWORD -e "CREATE USER '$OS_DB_USERNAME'@'%' IDENTIFIED BY '$OS_DB_PASSWORD'"
mysql -u root --password=$OS_DB_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '$OS_DB_USERNAME'@'%'"
mysql -u root --password=$OS_DB_PASSWORD -e "FLUSH PRIVILEGES"
mysql -u $OS_DB_USERNAME --password=$OS_DB_PASSWORD $OS_DB_NAME -e 'source prestashop_fullcustomer.dump.sql'

# Update configuration to allow external connections
echo "Rewriting MySQL configuration"
echo "[mysqld]\nbind-address = 0.0.0.0" > $CONFIGURATION
service mysql restart

exit $?
