#!/bin/bash

# Source environment variables
# shellcheck source=.env
source .env
source scripts/packages.env

echo "Checking current versions..."
# Get current versions from docker images
IFS='   ' #setting space as delimiter
read -r -a ADDR <<< "$(docker image ls | grep koenkk/zigbee2mqtt)"
Z2M_CUR_VER=${ADDR[1]}

read -r -a ADDR <<< "$(docker image ls | grep ipfs/kubo)"
IPFS_CUR_VER=${ADDR[1]}

read -r -a ADDR <<< "$(docker image ls | grep ghcr.io/pinoutltd/libp2p-ws-proxy)"
LIBP2P_CUR_VER=${ADDR[1]}

read -r -a ADDR <<< "$(docker image ls | grep ghcr.io/home-assistant/home-assistant)"
HA_CUR_VER=${ADDR[1]}

echo "Current versions:"
echo "Zigbee2MQTT: $Z2M_CUR_VER"
echo "IPFS: $IPFS_CUR_VER"
echo "LIBP2P: $LIBP2P_CUR_VER"
echo "Home Assistant: $HA_CUR_VER"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq could not be found, please install it to check versions"
    exit 1
fi

# Check robonomics version
ROBO_CUR_VER="$(jq -r '.version' 'homeassistant/custom_components/robonomics/manifest.json')"
echo "Current Robonomics version: $ROBO_CUR_VER"

if [ "$ROBO_CUR_VER" != "$ROBONOMICS_VERSION" ]; then
    echo "Updating Robonomics integration..."
    docker exec -d homeassistant sh -c "rm -r custom_components/robonomics"
    wget -q https://github.com/airalab/homeassistant-robonomics-integration/archive/refs/tags/"$ROBONOMICS_VERSION".zip
    unzip -q "$ROBONOMICS_VERSION".zip
    mv homeassistant-robonomics-integration-"$ROBONOMICS_VERSION"/custom_components/robonomics "${CONFIG_PATH}/homeassistant/custom_components/"
    rm -r homeassistant-robonomics-integration-"$ROBONOMICS_VERSION" "$ROBONOMICS_VERSION".zip
fi

# Clean up old images
echo "Cleaning up old images..."
[ "$Z2M_CUR_VER" != "$Z2M_VERSION" ] && docker image rm koenkk/zigbee2mqtt:"${Z2M_CUR_VER}"
[ "$IPFS_CUR_VER" != "v${IPFS_VERSION}" ] && docker image rm ipfs/kubo:"${IPFS_CUR_VER}"
[ "$LIBP2P_CUR_VER" != "v.${LIBP2P_VERSION}" ] && docker image rm ghcr.io/pinoutltd/libp2p-ws-proxy:"${LIBP2P_CUR_VER}"
[ "$HA_CUR_VER" != "$HA_VERSION" ] && docker image rm ghcr.io/home-assistant/home-assistant:"${HA_CUR_VER}"

echo "Update complete! Now run ./setup.sh to apply changes."