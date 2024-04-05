# home-assistant-web3-build

This repository contains docker compose file with Home Assistant + ipfs daemon + libp2p proxy + zigbee2mqtt

## Requirements 

Docker engine + docker compose

## Configuration
You can provide path to repository where will be stored all configurations folders.
Also, you can provide your time zone in ["tz database name"](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

Edit this parameters in `.env` file.
```
# provide the path to the repository where docker will store all configuration
CONFIG_PATH=<PATH_TO_YOUR_CONFIG>
# provide your time zone in tz database name, like TZ=America/Los_Angeles
TZ=<YOUR_TIME_ZONE>
...
```

## Installation

Run bash script:
```commandline
bash setup.sh
```

