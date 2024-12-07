#!/bin/bash -eu

if [ -f /tmp/sshd_config ]; then
    mv /tmp/sshd_config /etc/ssh/sshd_config
else
    echo "Error: /tmp/sshd_config not found."
    exit 1
fi

log_info "Restarting SSH"
systemctl restart sshd || log_error "Failed to restart SSH"

echo "SSH configuration completed"
