# home-assistant-web3-build

This repository contains docker compose file with Home Assistant + ipfs daemon + libp2p proxy + zigbee2mqtt.

## Requirements

First of all you need to install Docker. Find installation instructions on official website:

- [Docker Docs](https://docs.docker.com/engine/install/ubuntu/)

Alternatively, good instructions could be found here:

- [Digital Ocean](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-22-04)

**Docker should run without root.** This is important to provide correct access to directories.

then, install additional packages:

```commandline
sudo apt-get install wget unzip git jq
```

**Insert zigbee coordinator in your PC before start script!**

## Configuration

```commandline
git clone https://github.com/airalab/home-assistant-web3-build
cd home-assistant-web3-build/
```

create `.env` file. Convert it from `template.env` file:

```commandline
cp template.env .env
```

After that, you may open the file and edit default values such as:

- path where to store all configs
- time zone in ["tz database name"](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

## Installation and Run

Run bash script:

```commandline
bash setup.sh
```

After everything started, Home Assistant web interface will be on 8123 port and zigbee2mqtt on 8099 port.

It will stop and delete running docker containers.

## Update

To update version of packages, run `update.sh` script. It will stop running containers, dowload new version of packages and start everything again. This script will save all configurations files.

## Stop

To stop everything run stop script:

```commandline
bash stop.sh
```
