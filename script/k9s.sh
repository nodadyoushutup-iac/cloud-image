#!/bin/bash -eu

VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r '.tag_name')
ARCH="Linux_amd64"
TARBALL="k9s_${ARCH}.tar.gz"
URL="https://github.com/derailed/k9s/releases/download/${VERSION}/${TARBALL}"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="k9s"

if ! command -v curl &> /dev/null; then
    echo "[ERROR] curl is required but not installed. Please install it and run the script again."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "[ERROR] jq is required but not installed. Please install it and run the script again."
    exit 1
fi

echo "[INFO] Downloading k9s version ${VERSION} from ${URL}..."
curl -L -o "${TARBALL}" "${URL}" || { echo "[ERROR] Failed to download k9s."; exit 1; }

echo "[INFO] Extracting k9s binary..."
tar -xzf "${TARBALL}" "${BINARY_NAME}" || { echo "[ERROR] Failed to extract k9s."; exit 1; }

rm -f "${TARBALL}"

echo "[INFO] Installing k9s to ${INSTALL_DIR}..."
sudo mv "${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}" || { echo "[ERROR] Failed to move k9s to ${INSTALL_DIR}."; exit 1; }

sudo chmod +x "${INSTALL_DIR}/${BINARY_NAME}"

echo "[INFO] Verifying k9s installation..."
if command -v k9s &> /dev/null; then
    k9s version || true
    echo "[INFO] k9s installed successfully!"
else
    echo "[ERROR] k9s installation failed."
    exit 1
fi

echo "[INFO] Installation complete!"
