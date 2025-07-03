#!/bin/bash -eu

echo "[INFO] Starting apt update, upgrade, and package installation..."

echo "[INFO] Updating apt cache..."
sudo apt-get update

echo "[INFO] Installing apt packages..."
sudo apt-get install -y -qq \
    age \
    bat \
    bridge-utils \
    btop \
    cpu-checker \
    curl \
    dnsutils \
    duf \
    ethtool \
    fd-find \
    gh \
    git \
    htop \
    ifupdown \
    iotop \
    iperf3 \
    iptables \
    jq \
    libvirt-clients \
    libvirt-daemon-system \
    lshw \
    lsof \
    make \
    mysql-client-core-8.0 \
    nano \
    net-tools \
    netcat \
    neovim \
    nfs-common \
    nmap \
    nvtop \
    open-iscsi \
    parted \
    postgresql-client \
    python3 \
    python3-pip \
    python3-venv \
    qemu-guest-agent \
    qemu-kvm \
    qemu-system \
    qemu-system-x86 \
    ripgrep \
    rsync \
    screen \
    smartmontools \
    strace \
    tcpdump \
    tmux \
    traceroute \
    tree \
    ufw \
    unzip \
    vim \
    virtinst \
    wget \
    whois \
    xorriso \
    zip || echo "[ERROR] Failed to install one or more apt packages."


echo "[INFO] Upgrading apt packages..."
sudo apt-get upgrade -y

echo "[INFO] All tasks completed successfully!"
