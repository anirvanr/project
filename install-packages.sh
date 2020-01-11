#!/bin/bash

ok() { echo -e '\e[32m'$1'\e[m'; } # Green

if [[ -e /etc/redhat-release ]]; then
    RELEASE_RPM=$(rpm -qf /etc/centos-release)
    RELEASE=$(rpm -q --qf '%{VERSION}' ${RELEASE_RPM})
    if [ ${RELEASE} != "7" ]; then
        echo "Not CentOS release 7."
        exit 1
    fi
else
    echo "Not CentOS system."
    exit 1
fi

ok "Installing packages..."

sudo yum -y update
sudo yum install -y epel-release
sudo yum install -y nginx curl wget vim redis varnish haproxy unzip expect libxml2
sudo yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum-config-manager --enable remi-php71
sudo yum install -y php php-common php php-mysql php-fpm php-intl php-mbstring php-soap php-zip php-bcmath

if [ $? != 0 ]; then exit 1; fi
