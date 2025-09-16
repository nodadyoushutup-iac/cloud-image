#!/bin/bash
set -euo pipefail

sudo mkdir -p /mnt/eapp
sudo mkdir -p /mnt/eapp/code
sudo mkdir -p /mnt/eapp/skel
sudo mkdir -p /mnt/eapp/skel/.ssh
sudo mkdir -p /mnt/eapp/skel/.kube
sudo mkdir -p /mnt/eapp/skel/.tfvars
sudo mkdir -p /mnt/eapp/skel/.home
sudo mkdir -p /mnt/eapp/skel/.jenkins

read -r -d '' FSTAB_ENTRIES <<'EOF'
192.168.1.100:/mnt/epool/media   /media   nfs   defaults,_netdev   0 0
192.168.1.100:/mnt/eapp/code   /mnt/eapp/code   nfs   defaults,_netdev   0 0
192.168.1.100:/mnt/eapp/skel/.ssh   /mnt/eapp/skel/.ssh   nfs   defaults,_netdev   0 0
192.168.1.100:/mnt/eapp/skel/.kube   /mnt/eapp/skel/.kube   nfs   defaults,_netdev   0 0
192.168.1.100:/mnt/eapp/skel/.tfvars   /mnt/eapp/skel/.tfvars   nfs   defaults,_netdev   0 0
192.168.1.100:/mnt/eapp/skel/.home   /mnt/eapp/skel/.home   nfs   defaults,_netdev   0 0
192.168.1.100:/mnt/eapp/skel/.jenkins   /mnt/eapp/skel/.jenkins   nfs   defaults,_netdev   0 0
EOF

# Backup fstab first
sudo cp /etc/fstab /etc/fstab.bak.$(date +%F_%T)

# Append each line if it’s not already present
while IFS= read -r line; do
    if ! grep -Fxq "$line" /etc/fstab; then
        echo "$line" | sudo tee -a /etc/fstab > /dev/null
        echo "Added: $line"
    else
        echo "Already exists: $line"
    fi
done <<< "$FSTAB_ENTRIES"

echo "Done. A backup was saved to /etc/fstab.bak.$(date +%F_%T)"

sudo mount -a