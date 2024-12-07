#!/bin/bash -eu

echo "[INFO] Checking for curl..."
if ! command -v curl &> /dev/null; then
    echo "[ERROR] curl is required but not installed. Please install it and run the script again."
fi

echo "[INFO] Adding HashiCorp GPG key..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - || echo "[ERROR] Failed to add HashiCorp GPG key."

echo "[INFO] Adding HashiCorp APT repository..."
sudo apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" || echo "[ERROR] Failed to add HashiCorp APT repository."

echo "[INFO] Updating package list..."
sudo apt-get update || echo "[ERROR] Failed to update package list."

echo "[INFO] Installing Packer..."
sudo apt-get install -y packer || echo "[ERROR] Failed to install Packer."

echo "[INFO] Verifying Packer installation..."
if command -v packer &> /dev/null; then
    packer --version
    
    echo "[INFO] Packer installed successfully!"
else
    echo "[ERROR] Packer installation failed."
fi

echo "[INFO] Installation complete!"
