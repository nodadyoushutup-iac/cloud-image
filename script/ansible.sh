#!/bin/bash -eu

echo "[INFO] Starting Ansible installation..."
echo "[INFO] Updating package lists..."
sudo apt-get update

echo "[INFO] Installing prerequisites..."
sudo apt-get install -y software-properties-common

echo "[INFO] Adding Ansible PPA repository..."
sudo add-apt-repository --yes --update ppa:ansible/ansible

echo "[INFO] Installing Ansible..."
sudo apt-get install -y ansible

echo "[INFO] Verifying Ansible installation..."
if command -v ansible &> /dev/null; then
    ansible --version
    echo "[INFO] Ansible installed successfully!"
else
    echo "[ERROR] Ansible installation failed."
fi

echo "[INFO] Ansible installation complete!"
