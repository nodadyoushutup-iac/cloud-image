#!/bin/bash -eu

echo "[INFO] Starting script_dir..."

echo "[INFO] Creating /script dir..."
sudo mkdir -p /script

echo "[INFO] Setting /script permissions..."
sudo chmod -R 775 /script

echo "[INFO] Moving scripts from /tmp..."
sudo mv /tmp/register_github_public_key.sh /script/register_github_public_key.sh

echo "[INFO] Setting /script permissions..."
sudo chmod -R 775 /script