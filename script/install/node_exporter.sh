#!/bin/bash -eu

source /opt/logger/logger.sh

VERSION="v1.6.1"
ARCH="linux-amd64"
URL="https://github.com/prometheus/node_exporter/releases/download/${VERSION}/node_exporter-${VERSION/v/}.${ARCH}.tar.gz"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="node_exporter"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"
TEMP_SERVICE_FILE="/tmp/node_exporter.service"

log_info "Checking for wget..."
if ! command -v wget &> /dev/null; then
    log_error "wget is required but not installed. Please install it and run the script again."
fi

log_info "Ensuring the node_exporter user exists..."
if ! id "node_exporter" &>/dev/null; then
    sudo useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter || log_error "Failed to create node_exporter user."
fi

log_info "Downloading node_exporter from ${URL}..."
wget -q "${URL}" -O "/tmp/node_exporter.tar.gz" || log_error "Failed to download node_exporter."

log_info "Extracting node_exporter..."
tar -xzf "/tmp/node_exporter.tar.gz" -C "/tmp/" || log_error "Failed to extract node_exporter."

log_info "Installing node_exporter to ${INSTALL_DIR}..."
sudo mv "/tmp/node_exporter-${VERSION/v/}.${ARCH}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}" || log_error "Failed to move node_exporter to ${INSTALL_DIR}."

log_info "Setting permissions for node_exporter..."
sudo chown node_exporter:node_exporter "${INSTALL_DIR}/${BINARY_NAME}" || log_error "Failed to set ownership."
sudo chmod 0755 "${INSTALL_DIR}/${BINARY_NAME}" || log_error "Failed to set permissions."

log_info "Copying service file to systemd directory..."
if [ -f "${TEMP_SERVICE_FILE}" ]; then
    sudo cp "${TEMP_SERVICE_FILE}" "${SERVICE_FILE}" || log_error "Failed to copy service file to ${SERVICE_FILE}."
    sudo chmod 644 "${SERVICE_FILE}" || log_error "Failed to set permissions for the service file."
else
    log_error "Service file ${TEMP_SERVICE_FILE} not found. Ensure the file exists and run the script again."
fi

log_info "Reloading systemd daemon..."
sudo systemctl daemon-reload || log_error "Failed to reload systemd daemon."

log_info "Enabling and starting node_exporter service..."
sudo systemctl enable "${BINARY_NAME}" || log_error "Failed to enable node_exporter service."
sudo systemctl start "${BINARY_NAME}" || log_error "Failed to start node_exporter service."

log_info "Verifying node_exporter installation..."
if systemctl is-active --quiet "${BINARY_NAME}"; then
    
    log_info "node_exporter is running successfully!"
else
    
    log_info "Fetching node_exporter service logs..."
    sudo journalctl -u "${BINARY_NAME}" --no-pager || 
    log_info "No logs available for node_exporter service."
    log_error "node_exporter failed to start."
fi

log_info "Installation complete!"
