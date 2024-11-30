#!/bin/bash -eu

source /tmp/logger.sh
log_info "Starting apt update, upgrade, and package installation..."
log_info "Updating apt cache..."
sudo apt-get update -qq || log_error "Failed to update apt cache."
log_info "Upgrading apt packages..."
sudo apt-get upgrade -y -qq || log_error "Failed to upgrade apt packages."
log_info "Installing apt packages..."
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
    zip || log_error "Failed to install one or more apt packages."
log_info "All tasks completed successfully!"
