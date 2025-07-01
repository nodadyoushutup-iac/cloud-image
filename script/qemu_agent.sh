#!/bin/bash
set -euo pipefail

echo "[INFO] Installing qemu-guest-agent"
sudo apt-get update -qq
sudo apt-get install -y -qq qemu-guest-agent

echo "[INFO] Enabling qemu-guest-agent service"
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent

echo "[INFO] qemu-guest-agent installation complete!"
