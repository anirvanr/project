#!/bin/bash

MYSQL_ROOT_PASSWORD='Password@123'
MYSQL=`which mysql`


dbhost=$(xmllint --xpath "string(//connection/host)" /etc/omnius/ose/conf.d/local.xml)
dbuser=$(xmllint --xpath "string(//connection/username)" /etc/omnius/ose/conf.d/local.xml)
dbpass=$(xmllint --xpath "string(//connection/password)" /etc/omnius/ose/conf.d/local.xml)
dbname=$(xmllint --xpath "string(//connection/dbname)" /etc/omnius/ose/conf.d/local.xml)

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; } # Green

Q1="UNINSTALL PLUGIN validate_password;"
Q2="CREATE DATABASE IF NOT EXISTS $dbname;"
Q3="CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
Q4="GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"
Q5="GRANT ALL PRIVILEGES ON $dbname.* to '$dbuser'@'%' identified by '$dbpass';"
Q6="FLUSH PRIVILEGES;"

SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}"
 
$MYSQL -uroot -p"$MYSQL_ROOT_PASSWORD" -e "$SQL"

ok "Database $dbname and user $dbuser created with a password $dbpass"
