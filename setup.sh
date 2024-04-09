#!/bin/bash

echo "this script will create all necessary repositories and start docker containers"

# grap variables from .env file excluding comments
export $(grep -v '^#' .env | xargs)

# Check the last symbol in path. if it is "/", then delete it.
LAST_SYMBOL=${CONFIG_PATH: -1}
echo "$LAST_SYMBOL"
if [ "$LAST_SYMBOL" = "/" ]; then
  CONFIG_PATH="${CONFIG_PATH%?}"
fi

if [[ -d $CONFIG_PATH ]]
then
  cd $CONFIG_PATH
  echo "config path - $CONFIG_PATH"
else
  echo "config directory does not exist. Exit"
  exit 1
fi

# create IPFS repositories
if [[ -d ./ipfs/data ]]
then
  echo "IPFS directory already exist"
else
  mkdir -p "ipfs/data"
  mkdir -p "ipfs/staging"
fi

Z2MPATH=$(ls /dev/serial/by-id/)
Z2MPATH="/dev/serial/by-id/"$Z2MPATH
export Z2MPATH

# mqtt broker
if [[ -d ./mosquitto ]]
then
  echo "mosquitto directory already exist"
else
  mkdir -p "mosquitto/config"
  mkdir -p "zigbee2mqtt/data"

  # create password for mqtt. Then  save it in home directory and provide this data to z2m configuration
  MOSQUITTO_PASSWORD=$(openssl rand -hex 10)
  export MOSQUITTO_PASSWORD

  echo "listener 1883
  allow_anonymous false
  password_file /mosquitto/passwd" | tee ./mosquitto/config/mosquitto.conf

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
    password: $MOSQUITTO_PASSWORD

  frontend:
    # Optional, default 8080
    port: 8099

  # Serial settings
  serial:
    # Location of CC2531 USB sniffer
    port: /dev/ttyACM0

  " | tee ./zigbee2mqtt/data/configuration.yaml
fi

if [[ -d ./homeassistant/.storage ]]
then
  echo "homeassistant/.storage directory already exist"
else
  mkdir -p "homeassistant/.storage"

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
            \"password\": \"$MOSQUITTO_PASSWORD\",
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

fi

# create IPFS repositories
if [[ -d ./homeassistant/custom_components ]]
then
  echo "homeassistant/custom_components directory already exist"
else
  mkdir -p "homeassistant/custom_components"

  #download robonomics integration and unpack it
  wget https://github.com/airalab/homeassistant-robonomics-integration/archive/refs/tags/$ROBONOMICS_VERSION.zip &&
  unzip $ROBONOMICS_VERSION.zip &&
  mv homeassistant-robonomics-integration-$ROBONOMICS_VERSION/custom_components/robonomics ./homeassistant/custom_components/ &&
  rm -r homeassistant-robonomics-integration-$ROBONOMICS_VERSION &&
  rm $ROBONOMICS_VERSION.zip
fi

if [[ -d ./libp2p-ws-proxy ]]
then
  echo "libp2p-ws-proxy directory already exist"
else
  #libp2p
  git clone https://github.com/tubleronchik/libp2p-ws-proxy.git
  echo "PEER_ID_CONFIG_PATH="peerIdJson.json"
  RELAY_ADDRESS="$RELAY_ADDRESS"
  SAVED_DATA_DIR_PATH="saved_data"
  " > libp2p-ws-proxy/.env
fi

docker compose up -d