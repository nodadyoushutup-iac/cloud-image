#!/bin/bash -eu

echo "[INFO] Starting apt update, upgrade, and package installation..."

echo "[INFO] Updating apt cache..."
sudo apt-get update -qq || echo "[ERROR] Failed to update apt cache."

echo "[INFO] Upgrading apt packages..."
sudo apt-get upgrade -y -qq || echo "[ERROR] Failed to upgrade apt packages."

echo "[INFO] Installing apt packages..."
sudo apt-get install -y -qq \
    age \
    curl \
    dnsutils \
    git \
    htop \
    ifupdown \
    iptables \
    jq \
    lsof \
    make \
    mysql-client-core-8.0 \
    nano \
    net-tools \
    nfs-common \
    nmap \
    open-iscsi \
    postgresql-client \
    python3 \
    python3-pip \
    qemu-guest-agent \
    qemu-system \
    screen \
    strace \
    tcpdump \
    tmux \
    traceroute \
    unzip \
    vim \
    wget \
    whois \
    xorriso \
    zip || echo "[ERROR] Failed to install one or more apt packages."

echo "[INFO] All tasks completed successfully!"
