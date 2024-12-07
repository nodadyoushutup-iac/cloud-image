#!/bin/bash -eu

mkdir -p /opt/logger

log_info "Creating permanent logger script"
if [ -f /tmp/logger.sh ]; then
    mv /tmp/logger.sh /opt/logger/logger.sh
else
    echo "Error: /tmp/logger.sh not found."
    exit 1
fi

log_info "Setting logger script permissions"
chmod 755 /tmp/logger.sh

echo "logger.sh has been successfully moved to /opt/logger and permissions set"
