#!/bin/bash -eu

source /tmp/logger.sh

log_info "Starting directory creation"

log_info "Creating directory structure: /mnt/epool/media"
mkdir -p /mnt/epool/media || log_error "Failed to create directory /mnt/epool/media"

log_info "Creating directory structure: /mnt/epool/config"
mkdir -p /mnt/epool/config || log_error "Failed to create directory /mnt/epool/config"

log_info "Changing ownership of /mnt/epool/media to user 'apps'"
chown apps:apps /mnt/epool/media || log_error "Failed to change ownership of /mnt/epool/media to 'apps'"

log_info "Changing ownership of /mnt/epool/config to user 'apps'"
chown apps:apps /mnt/epool/config || log_error "Failed to change ownership of /mnt/epool/config to 'apps'"

log_info "Directory creation and ownership assignment completed successfully!"
