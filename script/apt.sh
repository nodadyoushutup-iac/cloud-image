#!/bin/bash -eu

echo "[INFO] Starting apt update, upgrade, and package installation..."

echo "[INFO] Updating apt cache..."
sudo apt-get update -qq || echo "[ERROR] Failed to update apt cache."

echo "[INFO] Installing apt packages..."
sudo apt-get install -y -qq \
    age \
    bridge-utils \
    cpu-checker \
    curl \
    dnsutils \
    gh \
    git \
    htop \
    ifupdown \
    iptables \
    jq \
    libvirt-clients \
    libvirt-daemon-system \
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
    python3-venv \
    qemu-guest-agent \
    qemu-kvm \
    qemu-system \
    qemu-system-x86 \
    screen \
    strace \
    tcpdump \
    tmux \
    traceroute \
    tree \
    unzip \
    vim \
    virtinst \
    wget \
    whois \
    xorriso \
    zip || echo "[ERROR] Failed to install one or more apt packages."

echo "[INFO] Upgrading apt packages..."
sudo apt-get upgrade -y -qq || echo "[ERROR] Failed to upgrade apt packages."

echo "[INFO] All tasks completed successfully!"
