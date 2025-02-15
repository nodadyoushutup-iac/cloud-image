#!/bin/bash -eu

VERSION="v1.6.1"
ARCH="linux-amd64"
URL="https://github.com/prometheus/node_exporter/releases/download/${VERSION}/node_exporter-${VERSION/v/}.${ARCH}.tar.gz"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="node_exporter"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"
TEMP_SERVICE_FILE="/tmp/node_exporter.service"

echo "[INFO] Checking for wget..."
if ! command -v wget &> /dev/null; then
    echo "[ERROR] wget is required but not installed. Please install it and run the script again."
fi

echo "[INFO] Ensuring the node_exporter user exists..."
if ! id "node_exporter" &>/dev/null; then
    sudo useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter || echo "[ERROR] Failed to create node_exporter user."
fi

if ! command -v wget &> /dev/null; then
    echo "[ERROR] wget is required but not installed. Please install it and run the script again."
fi

echo "[INFO] Downloading node_exporter from ${URL}..."
wget -q "${URL}" -O "/tmp/node_exporter.tar.gz" || echo "[ERROR] Failed to download node_exporter."

echo "[INFO] Extracting node_exporter..."
tar -xzf "/tmp/node_exporter.tar.gz" -C "/tmp/" || echo "[ERROR] Failed to extract node_exporter."

echo "[INFO] Installing node_exporter to ${INSTALL_DIR}..."
sudo mv "/tmp/node_exporter-${VERSION/v/}.${ARCH}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}" || echo "[ERROR] Failed to move node_exporter to ${INSTALL_DIR}."

echo "[INFO] Setting permissions for node_exporter..."
sudo chown node_exporter:node_exporter "${INSTALL_DIR}/${BINARY_NAME}" || echo "[ERROR] Failed to set ownership."
sudo chmod 0755 "${INSTALL_DIR}/${BINARY_NAME}" || echo "[ERROR] Failed to set permissions."

echo "[INFO] Copying service file to systemd directory..."
if [ -f "${TEMP_SERVICE_FILE}" ]; then
    sudo cp "${TEMP_SERVICE_FILE}" "${SERVICE_FILE}" || echo "[ERROR] Failed to copy service file to ${SERVICE_FILE}."
    sudo chmod 644 "${SERVICE_FILE}" || echo "[ERROR] Failed to set permissions for the service file."
else
    echo "[ERROR] Service file ${TEMP_SERVICE_FILE} not found. Ensure the file exists and run the script again."
fi

echo "[INFO] Reloading systemd daemon..."
sudo systemctl daemon-reload || echo "[ERROR] Failed to reload systemd daemon."

echo "[INFO] Enabling and starting node_exporter service..."
sudo systemctl enable "${BINARY_NAME}" || echo "[ERROR] Failed to enable node_exporter service."
sudo systemctl start "${BINARY_NAME}" || echo "[ERROR] Failed to start node_exporter service."

echo "[INFO] Verifying node_exporter installation..."
if systemctl is-active --quiet "${BINARY_NAME}"; then
    
    echo "[INFO] node_exporter is running successfully!"
else
    
    echo "[INFO] Fetching node_exporter service logs..."
    sudo journalctl -u "${BINARY_NAME}" --no-pager || 
    echo "[INFO] No logs available for node_exporter service."
    echo "[ERROR] node_exporter failed to start."
fi

echo "[INFO] Installation complete!"
