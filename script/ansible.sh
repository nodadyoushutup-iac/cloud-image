#!/bin/bash -eu

# Logging setup for Ansible installation
LOG_INFO="[INFO]"
LOG_ERROR="[ERROR]"

# Step 1: Update package lists
echo "$LOG_INFO Starting Ansible installation..."
echo "$LOG_INFO Updating package lists..."
sudo apt-get update -qq || echo "$LOG_ERROR Failed to update package lists."

# Step 2: Install prerequisites
echo "$LOG_INFO Installing prerequisites..."
sudo apt-get install -y -qq software-properties-common || echo "$LOG_ERROR Failed to install prerequisites."

# Step 3: Add Ansible PPA repository
echo "$LOG_INFO Adding Ansible PPA repository..."
sudo add-apt-repository --yes --update ppa:ansible/ansible || echo "$LOG_ERROR Failed to add Ansible PPA repository."

# Step 4: Install Ansible
echo "$LOG_INFO Installing Ansible..."
sudo apt-get install -y -qq ansible || echo "$LOG_ERROR Failed to install Ansible."

# Step 5: Verify Ansible installation
echo "$LOG_INFO Verifying Ansible installation..."
if command -v ansible &> /dev/null; then
    ansible --version
    echo "$LOG_INFO Ansible installed successfully!"
else
    echo "$LOG_ERROR Ansible installation failed."
fi

echo "$LOG_INFO Ansible installation complete!"
