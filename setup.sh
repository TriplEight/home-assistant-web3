#!/bin/bash

echo "this script will create all necessary repositories and start docker containers"

# grap variables from .env file excluding comments
export $(grep -v '^#' .env | xargs)

##TODO
# проверка последнего символа в пути. если это "/", то удалить его

cd $CONFIG_PATH
echo "config path - $CONFIG_PATH"

##TODO
# проверка папок на существование. Если есть, то не нужно их пересоздавать. И заново не нужно скачивать робономику

# create repositories
mkdir "mosquitto"
mkdir -p "zigbee2mqtt/data"
mkdir -p "ipfs/staging"
mkdir -p "ipfs/data"
mkdir -p "homeassistant/custom_components"
mkdir -p "homeassistant/.storage"

# find path to the zigbee adapter and save it in configuration
Z2MPATH=$(ls /dev/serial/by-id/)
Z2MPATH="/dev/serial/by-id/"$Z2MPATH
export Z2MPATH

# create password for mqtt. Then  save it in home directory and provide this data to z2m configuration

# mqtt broker
PASSWD=$(openssl rand -hex 10)
mosquitto_passwd -b -c ./mosquitto/passwd connectivity $PASSWD

echo "listener 1883
allow_anonymous false
password_file /mosquitto/passwd" | tee ./mosquitto/mosquitto.conf

#zigbee2mqtt
echo "# Home Assistant integration (MQTT discovery)
homeassistant: true

# allow new devices to join
permit_join: false

# MQTT settings
mqtt:
  # MQTT base topic for zigbee2mqtt MQTT messages
  base_topic: zigbee2mqtt
  # MQTT server URL
  server: 'mqtt://localhost'
  # MQTT server authentication, uncomment if required:
  user: connectivity
  password: $PASSWD

frontend:
  # Optional, default 8080
  port: 8099

# Serial settings
serial:
  # Location of CC2531 USB sniffer
  port: /dev/ttyACM0

" | tee ./zigbee2mqtt/data/configuration.yaml

# mqtt integration
echo "{
  \"version\": 1,
  \"minor_version\": 1,
  \"key\": \"core.config_entries\",
  \"data\": {
    \"entries\": [
      {
        \"entry_id\": \"92c28c246bb8163e5cc9e6dc5b5d8606\",
        \"version\": 1,
        \"domain\": \"mqtt\",
        \"title\": \"localhost\",
        \"data\": {
          \"broker\": \"localhost\",
          \"port\": 1883,
          \"username\": \"connectivity\",
          \"password\": \"$PASSWD\",
          \"discovery\": true,
          \"discovery_prefix\": \"homeassistant\"
        },
        \"options\": {},
        \"pref_disable_new_entities\": false,
        \"pref_disable_polling\": false,
        \"source\": \"user\",
        \"unique_id\": null,
        \"disabled_by\": null
      }
    ]
  }
}
" | tee ./homeassistant/.storage/core.config_entries

#download robonomics integration and unpack it
wget https://github.com/airalab/homeassistant-robonomics-integration/archive/refs/tags/$ROBONOMICS_VERSION.zip &&
unzip $ROBONOMICS_VERSION.zip &&
mv homeassistant-robonomics-integration-$ROBONOMICS_VERSION/custom_components/robonomics ./homeassistant/custom_components/ &&
rm -r homeassistant-robonomics-integration-$ROBONOMICS_VERSION &&
rm $ROBONOMICS_VERSION.zip

docker compose up -d