#!/bin/bash

Z2MPATH="."
export Z2MPATH

docker compose --profile z2m --env-file .env down
