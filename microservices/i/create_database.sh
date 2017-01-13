#!/bin/bash
#<le fichier "prestashop_fullcustomer.dump.sql" doit etre dans $HOME> <PAS ENCORE TESTE!>
export DEBIAN_FRONTEND=noninteractive
apt-get -q -y install mysql-server
cp /home/i/my.cnf /etc/mysql/my.cnf
/etc/init.d/mysql start
#mysqld --bind-address=0.0.0.0
mysqladmin -u root password 'debian'
mysql -u root --password='debian' --execute='CREATE DATABASE prestashop;'
mysql -u root --password='debian' --database='prestashop' --execute='SOURCE /home/i/prestashop_fullcustomer.dump.sql'
cat /etc/mysql/my.cnf
