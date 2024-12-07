#!/bin/bash -eu

source /opt/logger/logger.sh

log_info "Starting Docker CE installation..."

log_info "Updating package lists and installing prerequisites..."
sudo apt-get update -qq || log_error "Failed to update package lists."
sudo apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release || log_error "Failed to install prerequisites."

log_info "Adding Docker's GPG key..."
sudo mkdir -p /etc/apt/keyrings || log_error "Failed to create /etc/apt/keyrings directory."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || log_error "Failed to add Docker's GPG key."

log_info "Setting up the Docker repository..."
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || log_error "Failed to set up the Docker repository."

log_info "Installing Docker CE and related components..."
sudo apt-get update -qq || log_error "Failed to update package lists after adding Docker repository."
sudo apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin || log_error "Failed to install Docker CE and related components."

log_info "Verifying Docker installation..."
if command -v docker &> /dev/null; then
    docker --version
    
    log_info "Docker installed successfully!"
else
    log_error "Docker installation failed."
fi

log_info "Docker CE installation complete!"
