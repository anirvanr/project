#!/bin/bash

# Download repository
wget http://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm

# Add repository
sudo rpm -Uvh erlang-solutions-1.0-1.noarch.rpm

# Install erlang and dependencies
sudo yum -y install erlang socat logrotate

# Download RabbitMQ package
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.9/rabbitmq-server-3.7.9-1.el7.noarch.rpm

# Add signing key
sudo rpm --import https://www.rabbitmq.com/rabbitmq-signing-key-public.asc

# Install rabbitmq-server
sudo rpm -Uvh rabbitmq-server-3.7.9-1.el7.noarch.rpm

# Start RabbitMQ
sudo systemctl start rabbitmq-server

# Automatically start RabbitMQ at boot time
sudo systemctl enable rabbitmq-server

# Enable RabbitMQ web management console
sudo rabbitmq-plugins enable rabbitmq_management

# Modify file permissions
sudo chown -R rabbitmq:rabbitmq /var/lib/rabbitmq/

# Create an admin user (Change password to a strong password)
sudo rabbitmqctl add_user admin password

# Make admin user and administrator
sudo rabbitmqctl set_user_tags admin administrator

# Set admin user permissions
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

echo ""
echo ""
echo ""
echo "To access the RabbitMQ management web interface dashboard http://Your_Server_IP:15672"
