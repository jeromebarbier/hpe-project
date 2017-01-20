#!/bin/bash

apt-get install -y mysql

service mysql restart
mysql -uroot -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'admin'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%'"
