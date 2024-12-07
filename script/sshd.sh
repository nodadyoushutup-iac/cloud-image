#!/bin/bash -eu

echo "[INFO] Configuring SSH"
if [ -f /tmp/sshd_config ]; then
    mv /tmp/sshd_config /etc/ssh/sshd_config
else
    echo "Error: /tmp/sshd_config not found."
    exit 1
fi

echo "[INFO] Restarting SSH"
systemctl restart sshd || echo "[ERROR] Failed to restart SSH"

echo "SSH configuration completed"
