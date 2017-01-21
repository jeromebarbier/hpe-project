#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

service mysql restart

# Create user
export DB_USERNAME="prestashop"
export DB_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32)
export DB_NAME="prestashop"
export DB_SERVER="localhost"

I_USR_DBVARS="/home/i/.db_vars"

mysql -uroot -e "CREATE USER '$DB_USERNAME'@'%' IDENTIFIED BY '$DB_PASSWORD'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USERNAME'@'%'"

# Create the Database
mysql -u$DB_USERNAME -p$DB_PASSWORD -e "CREATE DATABASE $DB_NAME;"
mysql -u$DB_USERNAME -p$DB_PASSWORD --database="$DB_NAME" < /home/i/prestashop_fullcustomer.dump.sql

RESULT=$?

echo "Created DB $DB_NAME for user $DB_USERNAME with password $DB_PASSWORD (result=$RESULT)"

# Save the env vars into file
echo "export DB_USERNAME=$DB_USERNAME" >> $I_USR_DBVARS
echo "export DB_PASSWORD=$DB_PASSWORD" >> $I_USR_DBVARS
echo "export DB_NAME=$DB_NAME" >> $I_USR_DBVARS
echo "export DB_SERVER=$DB_SERVER" >> $I_USR_DBVARS

chown i:i $I_USR_DBVARS

exit $RESULT
