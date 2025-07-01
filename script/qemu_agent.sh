#!/bin/bash
set -euo pipefail

echo "[INFO] Installing qemu-guest-agent"
sudo apt-get update
sudo apt-get install -y qemu-guest-agent

echo "[INFO] qemu-guest-agent installation complete!"
