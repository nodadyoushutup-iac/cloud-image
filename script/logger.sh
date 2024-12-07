#!/bin/bash -eu

mkdir -p /opt/logger

if [ -f /tmp/logger.sh ]; then
    mv /tmp/logger.sh /tmp/logger.sh
else
    echo "Error: /tmp/logger.sh not found."
    exit 1
fi

chmod 755 /tmp/logger.sh

echo "logger.sh has been successfully moved to /opt/logger and permissions set"
