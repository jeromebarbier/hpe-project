#!/bin/bash
#<le fichier "prestashop_fullcustomer.dump.sql" doit etre dans $HOME> <PAS ENCORE TESTE!>
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get -q -y install mysql-server
mysqladmin -u root password 'debian'
sudo mysql -u root --password='debian' --execute='CREATE DATABASE prestashop;'
sudo mysql -u root --password='debian' --database='prestashop' --execute='SOURCE ~/prestashop_fullcustomer.dump.sql'
