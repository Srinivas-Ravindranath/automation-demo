#!/bin/bash

# update and install apache2 on the server
apt-get update
apt-get install apache2 -y

# start the apache2 service
service apache2 start
service apache2 reload
