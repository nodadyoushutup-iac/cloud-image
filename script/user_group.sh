#!/bin/bash -eu

source /opt/logger/logger.sh

log_info "Starting user and group creation"

log_info "Creating group 'apps' with GID 568"
groupadd -g 568 apps || log_error "Failed to create group 'apps'"

log_info "Creating user 'apps' with UID 568 and adding to group 'apps'"
useradd -u 568 -g apps -s /usr/sbin/nologin --no-create-home apps || log_error "Failed to create user 'apps'"

log_info "Adding user 'apps' to the 'sudo' group"
usermod -aG sudo apps || log_error "Failed to add user 'apps' to sudo group"

log_info "Configuring sudoers to allow 'apps' to run commands without a password prompt"
echo "apps ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/apps || log_error "Failed to configure sudo privileges for 'apps'"

log_info "User and group creation completed successfully!"
