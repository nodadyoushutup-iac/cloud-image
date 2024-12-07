#!/bin/bash -eu

source /opt/logger/logger.sh

log_info "Checking for curl..."
if ! command -v curl &> /dev/null; then
    log_error "curl is required but not installed. Please install it and run the script again."
fi

log_info "Adding HashiCorp GPG key..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - || log_error "Failed to add HashiCorp GPG key."

log_info "Adding HashiCorp APT repository..."
sudo apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" || log_error "Failed to add HashiCorp APT repository."

log_info "Updating package list..."
sudo apt-get update || log_error "Failed to update package list."

log_info "Installing Packer..."
sudo apt-get install -y packer || log_error "Failed to install Packer."

log_info "Verifying Packer installation..."
if command -v packer &> /dev/null; then
    packer --version
    
    log_info "Packer installed successfully!"
else
    log_error "Packer installation failed."
fi

log_info "Installation complete!"
