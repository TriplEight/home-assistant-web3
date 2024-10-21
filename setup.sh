#!/bin/bash

echo "This script will create all the necessary repositories and start the docker containers"

Z2MENABLE=true

# First we need to check that user insert the zigbee stick
if [ -d /dev/serial/by-id/ ]; then
  # the directory exists
  if [ "$(ls -A /dev/serial/by-id/)" ]; then
    echo "Zigbee coordinator is installed"
    # count how many devices connected
    NUMB=$(ls -1q /dev/serial/by-id/ | wc -l)

    if (($NUMB > 1)); then
      echo "You have more than 1 connected device, which seems to be a Zigbee coordinator. Please choose one:"
      select f in /dev/serial/by-id/*; do
        test -n "$f" && break
        echo ">>> Invalid Selection"
      done
      echo "You select $f"
      Z2MPATH=$f
    else
      Z2MPATH=$(ls /dev/serial/by-id/)
      Z2MPATH="/dev/serial/by-id/"$Z2MPATH
    fi

  else
    echo "Cannot find zigbee coordinator location. Please insert it and run script again."
    echo "Do you want to continue without zigbee coordinator? It will not start Zigbee2MQTT container."
    while true; do
        read -p "Do you want to proceed? (Y/n) " yn
        case $yn in
	          [yY]| "" ) echo ok, we will proceed;
	            Z2MENABLE=false
		          break;;
	          [nN] ) echo exiting...;
		          exit;;
	          * ) echo invalid response;;
        esac
    done
    Z2MPATH="."
  fi
else
    echo "Cannot find Zigbee coordinator location. Please insert it and run script again. The directory "/dev/serial/by-id/" does not exist"
    echo "Do you want to continue without Zigbee coordinator? We will not start Zigbee2MQTT container."
    while true; do
        read -p "Do you want to proceed? (Y/n) " yn
        case $yn in
	          [yY]| "" ) echo Ok, proceeding without Zigbee coordinator;
	            Z2MENABLE=false
		          break;;
	          [nN] ) echo exiting...;
		          exit;;
	          * ) echo invalid response;;
        esac
    done
    Z2MPATH="."
fi
export Z2MPATH

echo "Checking docker installation"
if command -v docker &> /dev/null; then
    echo "Docker installation found"
else
    echo "Docker installation not found. Please install Docker."
    exit 1
fi

# check if user in docker group
if id -nG "$USER" | grep -qw "docker"; then
    echo "$USER user belongs to docker group"
else
    echo "$USER user does not belong to docker group. Please add $USER user to docker group."
    exit 1
fi

# check .env file
if [[ -f .env ]]
then
  echo ".env file exists"
else
  echo "Fatal error: .env file does not exist. Exit"
  exit 1
fi

# grap variables from .env file excluding comments
export $(grep -v '^#' .env | xargs)

# Check the last symbol in path. if it is "/", then delete it.
LAST_SYMBOL=${CONFIG_PATH: -1}
echo "$LAST_SYMBOL"
if [ "$LAST_SYMBOL" = "/" ]; then
  CONFIG_PATH="${CONFIG_PATH%?}"
fi

# grap version of packages
export $(grep -v '^#' scripts/packages.env | xargs)

# save current path to return later
CURRENT_PATH=$(pwd)


if [[ -d $CONFIG_PATH ]]
then
  cd $CONFIG_PATH
  echo "config path - $CONFIG_PATH"
else
  echo "Fatal error: config directory does not exist. Exit"
  exit 1
fi

# create IPFS repositories
if [[ -d ./ipfs/data ]]
then
  echo "IPFS directory already exists"
else
  mkdir -p "ipfs/data"
  mkdir -p "ipfs/staging"
fi

# mqtt broker
if [[ -d ./mosquitto ]]
then
  echo "Mosquitto directory already exists"
  MOSQUITTO_PASSWORD=`cat ./mosquitto/raw.txt`
  export MOSQUITTO_PASSWORD
else
  mkdir -p "mosquitto/config"
  mkdir -p "zigbee2mqtt/data"

  # create password for mqtt. Then save it in mosquitto home directory and provide this data to z2m configuration
  MOSQUITTO_PASSWORD=$(openssl rand -base64 32)
  echo "MOSQUITTO_PASSWORD=$MOSQUITTO_PASSWORD" >> .env

  export MOSQUITTO_PASSWORD

  cp $CURRENT_PATH/scripts/mosquitto.conf  ./mosquitto/config/mosquitto.conf

  #zigbee2mqtt
  cat << EOF > ./zigbee2mqtt/data/configuration.yaml
# Home Assistant integration (MQTT discovery)
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

advanced:
  channel: $ZIGBEE_CHANNEL

frontend:
  # Optional, default 8080
  port: 8099

# Serial settings
serial:
  # Location of CC2531 USB sniffer
  port: $Z2MPATH

# Network settings
# Uncomment and modify if using Zigbee network adapters
# network:
#   panId: 0x1a62
#   extendedPanId: [0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD, 0xDD]

# Add any other desired configuration options here
EOF

fi

if [[ -d ./homeassistant/.storage ]]
then
  echo "homeassistant/.storage directory already exists"
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

# create homeassistant/custom_components repository
if [[ -d ./homeassistant/custom_components ]]
then
  echo "homeassistant/custom_components directory already exists"
else
  mkdir -p "homeassistant/custom_components"
  # download robonomics integration and unpack it
  wget https://github.com/airalab/homeassistant-robonomics-integration/archive/refs/tags/$ROBONOMICS_VERSION.zip &&
  unzip $ROBONOMICS_VERSION.zip &&
  mv homeassistant-robonomics-integration-$ROBONOMICS_VERSION/custom_components/robonomics ./homeassistant/custom_components/ &&
  rm -r homeassistant-robonomics-integration-$ROBONOMICS_VERSION &&
  rm $ROBONOMICS_VERSION.zip
fi

# return to the directory with compose
cd $CURRENT_PATH


if [ "$Z2MENABLE" = "true" ]; then
    echo "Starting containers with Zigbee2mqtt"
    docker compose --profile z2m --env-file .env --env-file scripts/packages.env up -d
else
    echo "Starting docker without Zigbee2mqtt"
    docker compose --env-file .env --env-file scripts/packages.env up -d
fi

# at the end save Z2Mpath to env file for use in the update script
echo "" >> .env
echo "Z2MPATH=$Z2MPATH" >> .env
