#!/bin/bash -eu

echo "[INFO] Starting Docker CE installation..."

echo "[INFO] Updating package lists and installing prerequisites..."
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo "[INFO] Adding Docker's GPG key..."
sudo mkdir -p /etc/apt/keyrings || echo "[ERROR] Failed to create /etc/apt/keyrings directory."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "[INFO] Setting up the Docker repository..."
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[INFO] Installing Docker CE and related components..."
sudo apt-get update
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin

echo "[INFO] Verifying Docker installation..."
if command -v docker &> /dev/null; then
    docker --version
    
    echo "[INFO] Docker installed successfully!"
else
    echo "[ERROR] Docker installation failed."
fi

echo "[INFO] Docker CE installation complete!"
