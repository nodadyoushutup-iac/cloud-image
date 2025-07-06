#!/bin/bash -eu

echo "[INFO] Starting script_dir..."

echo "[INFO] Creating /script dir..."
sudo mkdir -p /script
sudo ls -la / | grep script

echo "[INFO] Setting /script permissions..."
sudo chmod -R 777 /script
sudo ls -la / | grep script

echo "[INFO] Moving scripts from /tmp..."
sudo mv /tmp/register_github_public_key.sh /script/register_github_public_key.sh

echo "[INFO] Setting /script permissions..."
sudo chmod -R 660 /script
sudo chmod +x /script/**
sudo ls -la / | grep script
sudo ls -la /script | grep script