#!/bin/bash


# check parameters
if [ -z "$1" ]; then
    echo "parameter 1 to the the install command must be the environemnt this server is used in [staging/testing/production]! change it in /etc/deployr/deployr.conf"
    exit 1;
fi

mkdir -p /etc/deployr/
printf "[generic]\nenv = $1\n" > /etc/deployr/deployr.conf


cp "./src/deployr" /usr/bin/deployr
chmod +x /usr/bin/deployr