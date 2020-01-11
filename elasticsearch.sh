#!/bin/bash

# Pre-requisite
yum -y install curl wget

# Check Java
java -version
if [ $? -ne 0 ]
    then
        #Installing Java if it's not installed
        sudo yum install jre-1.8.0-openjdk -y
        # Checking if java installed is less than version 7. If yes, installing Java 8. As Elasticsearch require Java 7 or later.
    elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.8 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
        then
            sudo yum install jre-1.8.0-openjdk -y
fi

# Download packages and Install
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.16.rpm
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
rpm --install elasticsearch-5.6.16.rpm

# Starting Elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

# Verifying if Elasticsearch is running
sleep 10
curl -X GET 'http://localhost:9200'
