#!/bin/bash
set -euo pipefail

log()  { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
die()  { echo "[ERROR] $*" >&2; exit 1; }
trap 'die "failed at line $LINENO"' ERR

# --- Config / Overrides ---
INSTALL_DIR="/usr/local/bin"
BIN="node_exporter"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"
NODE_EXPORTER_VERSION="${NODE_EXPORTER_VERSION:-}"   # e.g. v1.8.2; empty = latest

# --- Preflight ---
command -v curl >/dev/null 2>&1 || die "curl is required (apt-get install -y curl)."
command -v tar  >/dev/null 2>&1 || die "tar is required (apt-get install -y tar)."
command -v sha256sum >/dev/null 2>&1 || die "sha256sum (coreutils) required."
sudo -n true 2>/dev/null || warn "sudo may prompt for your password."

# --- Arch mapping to upstream asset names ---
DEB_ARCH="$(dpkg --print-architecture || echo unknown)"
case "$DEB_ARCH" in
  amd64)   ASSET_ARCH="linux-amd64" ;;
  arm64)   ASSET_ARCH="linux-arm64" ;;
  armhf)   ASSET_ARCH="linux-armv7" ;;   # best match for 32-bit ARM
  *)       die "Unsupported or unknown architecture: ${DEB_ARCH}" ;;
esac

# --- Resolve version (latest if not pinned) ---
get_latest_tag() {
  # Try GitHub API with jq if present; fall back to minimal parsing
  if command -v jq >/dev/null 2>&1; then
    curl -fsSL --retry 3 "https://api.github.com/repos/prometheus/node_exporter/releases/latest" | jq -r '.tag_name'
  else
    curl -fsSL --retry 3 "https://api.github.com/repos/prometheus/node_exporter/releases/latest" \
      | sed -n 's/.*"tag_name":[[:space:]]*"\(v[^"]*\)".*/\1/p' | head -n1
  fi
}
if [[ -z "${NODE_EXPORTER_VERSION}" ]]; then
  log "Discovering latest node_exporter version…"
  NODE_EXPORTER_VERSION="$(get_latest_tag)"
  [[ -n "$NODE_EXPORTER_VERSION" ]] || die "Could not determine latest version."
fi
[[ "$NODE_EXPORTER_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Invalid version: ${NODE_EXPORTER_VERSION}"

VER_NO_V="${NODE_EXPORTER_VERSION#v}"
TARBALL="node_exporter-${VER_NO_V}.${ASSET_ARCH}.tar.gz"
BASE="https://github.com/prometheus/node_exporter/releases/download/${NODE_EXPORTER_VERSION}"
URL="${BASE}/${TARBALL}"
SUMS_URL="${BASE}/sha256sums.txt"

# --- Idempotency: skip if already at target version ---
if command -v "${BIN}" >/dev/null 2>&1; then
  set +e
  CURRENT="$(${BIN} --version 2>/dev/null | sed -n 's/.*version \([0-9.]\+\).*/\1/p' | head -n1)"
  set -e
  if [[ -n "${CURRENT:-}" && "${CURRENT}" == "${VER_NO_V}" ]]; then
    log "node_exporter v${CURRENT} already installed at $(command -v ${BIN}); nothing to do."
    exit 0
  else
    log "Installed version: ${CURRENT:-unknown}, target: v${VER_NO_V}"
  fi
fi

# --- Create system user (no login, no home) ---
if ! id -u node_exporter >/dev/null 2>&1; then
  log "Creating system user 'node_exporter'…"
  sudo useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter
fi

# --- Work in a temp dir; auto-clean on exit ---
TMP="$(mktemp -d)"; cleanup(){ rm -rf "$TMP"; }; trap cleanup EXIT

log "Downloading ${TARBALL} from ${URL}…"
curl -fL --retry 3 -o "${TMP}/${TARBALL}" "${URL}"

log "Verifying SHA256…"
curl -fL --retry 3 -o "${TMP}/sha256sums.txt" "${SUMS_URL}"
EXPECTED="$(grep " ${TARBALL}\$" "${TMP}/sha256sums.txt" | awk '{print $1}')" || true
[[ -n "$EXPECTED" ]] || die "No checksum entry for ${TARBALL}"
echo "${EXPECTED}  ${TMP}/${TARBALL}" | sha256sum -c - >/dev/null

log "Extracting…"
tar -xzf "${TMP}/${TARBALL}" -C "${TMP}"

SRC_BIN="${TMP}/node_exporter-${VER_NO_V}.${ASSET_ARCH}/${BIN}"
[[ -x "${SRC_BIN}" ]] || die "Binary not found in tarball: ${SRC_BIN}"

log "Installing to ${INSTALL_DIR}/${BIN}…"
sudo install -m 0755 -o root -g root -T "${SRC_BIN}" "${INSTALL_DIR}/${BIN}"

# --- Systemd service (hardened, minimal) ---
log "Writing systemd service to ${SERVICE_FILE}…"
sudo tee "${SERVICE_FILE}" >/dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=${INSTALL_DIR}/${BIN}
Restart=on-failure
RestartSec=5s

# Hardening (best effort)
NoNewPrivileges=true
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
ProtectKernelTunables=true
ProtectControlGroups=true
ProtectKernelModules=true
LockPersonality=true
MemoryDenyWriteExecute=true
ReadWritePaths=/var/lib/node_exporter

[Install]
WantedBy=multi-user.target
EOF
sudo chmod 0644 "${SERVICE_FILE}"

log "Reloading systemd and starting service…"
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

# --- Verify ---
if systemctl is-active --quiet node_exporter; then
  log "node_exporter is running."
  # Show version and default listen address
  "${INSTALL_DIR}/${BIN}" --version || true
  log "Default listen: http://<host>:9100/metrics"
else
  warn "node_exporter failed to start; showing recent logs:"
  sudo journalctl -u node_exporter -n 50 --no-pager || true
  die "Service not active."
fi

log "Installation complete."
