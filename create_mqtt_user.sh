#!/bin/bash

# This script creates the password file for Mosquitto
# Place this in your scripts directory

# Check if password is provided as argument
if [ -z "$1" ]; then
  echo "Usage: $0 <password>"
  exit 1
fi

PASSWORD=$1
CONFIG_PATH=${2:-./config}

# Ensure the mosquitto config directory exists
mkdir -p ${CONFIG_PATH}/mosquitto/config

# Create the password file
touch ${CONFIG_PATH}/mosquitto/config/password_file

# Add users
docker run --rm -v ${CONFIG_PATH}/mosquitto:/mosquitto eclipse-mosquitto \
  mosquitto_passwd -b /mosquitto/config/password_file connectivity "$PASSWORD"

# Add any other users you need
# docker run --rm -v ${CONFIG_PATH}/mosquitto:/mosquitto eclipse-mosquitto \
#   mosquitto_passwd -b /mosquitto/config/password_file homeassistant "your_ha_password"

echo "MQTT users created successfully."
