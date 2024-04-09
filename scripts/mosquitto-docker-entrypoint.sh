#!/bin/ash

set -e
# create mosquitto passwordfile
touch /mosquitto/passwd
chmod 0700 /mosquitto/passwd
mosquitto_passwd -b -c /mosquitto/passwd connectivity $MOSQUITTO_PASSWORD
echo $MOSQUITTO_PASSWORD


# Fix write permissions for mosquitto directories
chown --no-dereference --recursive mosquitto:mosquitto /mosquitto/passwd
chown --no-dereference --recursive mosquitto /mosquitto/log
chown --no-dereference --recursive mosquitto /mosquitto/data

mkdir -p /var/run/mosquitto \
  && chown --no-dereference --recursive mosquitto /var/run/mosquitto

exec "$@"