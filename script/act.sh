#!/bin/bash -eu

VERSION="v0.2.69"
ARCH="Linux_x86_64"
URL="https://github.com/nektos/act/releases/download/${VERSION}/act_${ARCH}.tar.gz"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="act"

if ! command -v wget &> /dev/null; then
    echo "[ERROR] wget is required but not installed. Please install it and run the script again."
fi

echo "[INFO] Downloading act from ${URL}..."
wget -q "${URL}" -O "/tmp/act.tar.gz" || echo "[ERROR] Failed to download act."

echo "[INFO] Extracting act..."
tar -xzf "/tmp/act.tar.gz" -C "/tmp/" || echo "[ERROR] Failed to extract act."

echo "[INFO] Installing act to ${INSTALL_DIR}..."
sudo mv "/tmp/act" "${INSTALL_DIR}/${BINARY_NAME}" || echo "[ERROR] Failed to move act to ${INSTALL_DIR}."

echo "[INFO] Making act executable..."
sudo chmod +x "${INSTALL_DIR}/${BINARY_NAME}" || echo "[ERROR] Failed to make act executable."

echo "[INFO] Verifying act installation..."
if command -v act &> /dev/null; then
    act --version
    
    echo "[INFO] act installed successfully!"
else
    echo "[ERROR] act installation failed."
fi

echo "[INFO] Installation complete!"
