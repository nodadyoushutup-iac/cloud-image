#!/bin/bash -eu

source /opt/logger/logger.sh

VERSION="v0.2.69"
ARCH="Linux_x86_64"
URL="https://github.com/nektos/act/releases/download/${VERSION}/act_${ARCH}.tar.gz"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="act"

if ! command -v wget &> /dev/null; then
    log_error "wget is required but not installed. Please install it and run the script again."
fi

log_info "Downloading act from ${URL}..."
wget -q "${URL}" -O "/tmp/act.tar.gz" || log_error "Failed to download act."

log_info "Extracting act..."
tar -xzf "/tmp/act.tar.gz" -C "/tmp/" || log_error "Failed to extract act."

log_info "Installing act to ${INSTALL_DIR}..."
sudo mv "/tmp/act" "${INSTALL_DIR}/${BINARY_NAME}" || log_error "Failed to move act to ${INSTALL_DIR}."

log_info "Making act executable..."
sudo chmod +x "${INSTALL_DIR}/${BINARY_NAME}" || log_error "Failed to make act executable."

log_info "Verifying act installation..."
if command -v act &> /dev/null; then
    act --version
    
    log_info "act installed successfully!"
else
    log_error "act installation failed."
fi

log_info "Installation complete!"
