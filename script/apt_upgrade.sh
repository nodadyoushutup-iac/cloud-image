#!/bin/bash

echo "[INFO] Upgrading apt packages"
sudo apt-get update
sudo apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo apt-get upgrade -y

echo "[INFO] apt packages upgraded!"
