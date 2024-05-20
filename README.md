# home-assistant-web3-build

This repository contains docker compose file with Home Assistant + ipfs daemon + libp2p proxy + zigbee2mqtt.

## Requirements 

Docker engine + docker compose.

**Docker should start without root preventives.** This is important to provide correct access to directories.

Install additional packages:
```commandline
sudo apt-get install wget unzip git
```

**Insert zigbee coordinator in your PC before start script!** 

## Configuration

First, download the repository and go to it:
```commandline
git clone https://github.com/nakata5321/home-assistant-web3-build.git
cd home-assistant-web3-build/
```

then you have to create `.env` file. Convert it from `template.env` file:
```commandline
mv template.env .env
```
After that,You may open the file and edit default values such as: 
- Versions of packages
- libp2p RELAY_ADDRESS.
- path to repository where will be stored all configurations folders.
- time zone in ["tz database name"](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).



## Installation and Run

Run bash script:
```commandline
bash setup.sh
```

After everything started, Home Assistant web interface will be on 8123 port and zigbee2mqtt on 8099 port.

## Stop

To stop everything use next command:
```commandline
docker compose down
```

After that you delete all config directories. **This will cause you to lose all settings. You will need root accesses**