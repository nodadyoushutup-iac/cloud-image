#!/bin/bash -euo

echo "[INFO] Installing qemu-guest-agent"
sudo apt-get update
sudo apt-get install -y qemu-guest-agent

echo "[INFO] qemu-guest-agent installation complete!"
