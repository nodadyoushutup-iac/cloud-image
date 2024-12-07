#!/bin/bash -eu

source /tmp/logger.sh

log_info "Starting directory creation"

log_info "Creating directory structure: /mnt/efs"
mkdir -p /mnt/efs || log_error "Failed to create directory /mnt/efs"

log_info "Directory creation completed successfully!"
