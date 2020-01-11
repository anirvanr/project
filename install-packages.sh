#!/bin/bash

sudo yum -y update
sudo yum install -y epel-release
sudo yum install -y nginx curl wget vim redis varnish haproxy unzip expect libxml2
sudo yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum-config-manager --enable remi-php71
sudo yum install -y php php-common php php-mysql php-fpm php-intl php-mbstring php-soap php-zip php-bcmath
