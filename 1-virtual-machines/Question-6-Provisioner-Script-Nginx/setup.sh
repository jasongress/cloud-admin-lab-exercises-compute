#!/bin/bash
# Update packages and install Nginx
apt-get update -y
apt-get install nginx -y
systemctl enable nginx
systemctl start nginx
