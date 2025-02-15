#!/bin/bash -eu

VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
ARCH="linux/amd64"
URL="https://dl.k8s.io/release/${VERSION}/bin/${ARCH}/kubectl"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="kubectl"

if ! command -v curl &> /dev/null; then
    echo "[ERROR] curl is required but not installed. Please install it and run the script again."
    exit 1
fi

echo "[INFO] Downloading kubectl version ${VERSION} from ${URL}..."
curl -LO "${URL}" || { echo "[ERROR] Failed to download kubectl."; exit 1; }

echo "[INFO] Making kubectl executable..."
chmod +x "${BINARY_NAME}" || { echo "[ERROR] Failed to set executable permission on kubectl."; exit 1; }

echo "[INFO] Installing kubectl to ${INSTALL_DIR}..."
sudo mv "${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}" || { echo "[ERROR] Failed to move kubectl to ${INSTALL_DIR}."; exit 1; }

echo "[INFO] Verifying kubectl installation..."
if command -v kubectl &> /dev/null; then
    kubectl version --client
    echo "[INFO] kubectl installed successfully!"
else
    echo "[ERROR] kubectl installation failed."
    exit 1
fi

echo "[INFO] Installation complete!"
