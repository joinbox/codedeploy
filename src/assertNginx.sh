#!/bin/bash

service --status-all | grep nginx > /dev/null
if [ $? -eq 0 ]; then
  echo "nginx is installed"
else
  echo "nginx is not installed, starting installation"
  sudo apt-get update
  sudo apt-get install -y nginx
fi