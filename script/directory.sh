#!/bin/bash -eu

echo "[INFO] Starting directory creation"

echo "[INFO] Creating directory structure: /mnt/efs"
mkdir -p /mnt/efs || echo "[ERROR] Failed to create directory /mnt/efs"

echo "[INFO] Directory creation completed successfully!"
