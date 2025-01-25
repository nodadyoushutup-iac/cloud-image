#!/bin/bash -eu

# Logging setup for Terraform installation
LOG_INFO="[INFO]"
LOG_ERROR="[ERROR]"

# Step 1: Update package lists and install prerequisites
echo "$LOG_INFO Starting Terraform installation..."
echo "$LOG_INFO Updating package lists and installing prerequisites..."
sudo apt-get update -qq || echo "$LOG_ERROR Failed to update package lists."
sudo apt-get install -y -qq gnupg software-properties-common || echo "$LOG_ERROR Failed to install prerequisites."

if ! command -v wget &> /dev/null; then
    echo "[ERROR] wget is required but not installed. Please install it and run the script again."
fi

# Step 2: Add HashiCorp GPG key
echo "$LOG_INFO Adding HashiCorp GPG key..."
wget -qO- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null || echo "$LOG_ERROR Failed to add HashiCorp GPG key."

echo "$LOG_INFO Verifying HashiCorp GPG key fingerprint..."
gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint || echo "$LOG_ERROR Failed to verify HashiCorp GPG key fingerprint."

# Step 3: Add HashiCorp repository
echo "$LOG_INFO Adding HashiCorp repository..."
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null || echo "$LOG_ERROR Failed to add HashiCorp repository."

# Step 4: Update package lists after adding repository
echo "$LOG_INFO Updating package lists after adding HashiCorp repository..."
sudo apt-get update -qq || echo "$LOG_ERROR Failed to update package lists after adding repository."

# Step 5: Install Terraform
echo "$LOG_INFO Installing Terraform..."
sudo apt-get install -y -qq terraform || echo "$LOG_ERROR Failed to install Terraform."

# Step 6: Verify Terraform installation
echo "$LOG_INFO Verifying Terraform installation..."
if command -v terraform &> /dev/null; then
    terraform --version
    echo "$LOG_INFO Terraform installed successfully!"
else
    echo "$LOG_ERROR Terraform installation failed."
fi

echo "$LOG_INFO Terraform installation complete!"
