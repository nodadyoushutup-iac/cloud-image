#!/bin/bash -eu

echo "[INFO] Starting user and group creation"

echo "[INFO] Creating group 'apps' with GID 568"
groupadd -g 568 apps || echo "[ERROR] Failed to create group 'apps'"

echo "[INFO] Creating user 'apps' with UID 568 and adding to group 'apps'"
useradd -u 568 -g apps -s /usr/sbin/nologin --no-create-home apps || echo "[ERROR] Failed to create user 'apps'"

echo "[INFO] Adding user 'apps' to the 'sudo' group"
usermod -aG sudo apps || echo "[ERROR] Failed to add user 'apps' to sudo group"

echo "[INFO] Configuring sudoers to allow 'apps' to run commands without a password prompt"
echo "apps ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/apps || echo "[ERROR] Failed to configure sudo privileges for 'apps'"

echo "[INFO] User and group creation completed successfully!"
