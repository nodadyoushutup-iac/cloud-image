#!/bin/bash -eu

source /tmp/logger.sh

log_info "Starting directory creation"

log_info "Creating directory structure: /mnt/media"
mkdir -p /mnt/media || log_error "Failed to create directory /mnt/media"

log_info "Creating directory structure: /mnt/config"
mkdir -p /mnt/config || log_error "Failed to create directory /mnt/config"

log_info "Changing ownership of /mnt/media to user 'apps'"
chown apps:apps /mnt/media || log_error "Failed to change ownership of /mnt/media to 'apps'"

log_info "Changing ownership of /mnt/config to user 'apps'"
chown apps:apps /mnt/config || log_error "Failed to change ownership of /mnt/config to 'apps'"

log_info "Directory creation and ownership assignment completed successfully!"
