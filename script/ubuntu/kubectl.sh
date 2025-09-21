#!/bin/bash
set -euo pipefail

log()  { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
die()  { echo "[ERROR] $*" >&2; exit 1; }
trap 'die "failed at line $LINENO"' ERR

# --- Config / Overrides ---
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="kubectl"
OS="linux"
# Allow: KUBECTL_VERSION=v1.31.2 ./install-kubectl.sh
KUBECTL_VERSION="${KUBECTL_VERSION:-}"

fetch_latest_stable_version() {
  local urls=(
    "https://dl.k8s.io/release/stable.txt"
    "https://storage.googleapis.com/kubernetes-release/release/stable.txt"
  )
  local url version

  for url in "${urls[@]}"; do
    if version="$(curl -fsSL --retry 3 --retry-connrefused --retry-delay 2 "$url" 2>/dev/null)"; then
      version="$(printf '%s' "$version" | tr -d '\r\n')"
      if [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$version"
        return 0
      fi
      warn "Unexpected kubectl version string '$version' from $url"
    else
      warn "Failed to query kubectl version from $url"
    fi
  done

  return 1
}

# --- Preflight ---
command -v curl >/dev/null 2>&1 || die "curl is required (apt-get install -y curl)."
command -v sha256sum >/dev/null 2>&1 || die "sha256sum is required (part of coreutils)."
sudo -n true 2>/dev/null || warn "sudo may prompt for your password."

# --- Detect architecture and map to Kubernetes arch tags ---
DEB_ARCH="$(dpkg --print-architecture || echo unknown)"
case "$DEB_ARCH" in
  amd64)   K_arch="amd64" ;;
  arm64)   K_arch="arm64" ;;
  armhf|armel) K_arch="arm" ;;      # 32-bit ARM
  ppc64el) K_arch="ppc64le" ;;
  s390x)   K_arch="s390x" ;;
  riscv64) K_arch="riscv64" ;;      # may not be published for all releases
  *)
    die "Unsupported or unknown architecture: ${DEB_ARCH}"
    ;;
esac

# --- Resolve desired version ---
if [[ -z "$KUBECTL_VERSION" ]]; then
  log "Querying latest stable kubectl version..."
  if ! KUBECTL_VERSION="$(fetch_latest_stable_version)"; then
    die "Unable to fetch stable kubectl version."
  fi
fi
[[ "$KUBECTL_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Invalid version string: '${KUBECTL_VERSION}'"

URL_BASE="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${OS}/${K_arch}"
BIN_URL="${URL_BASE}/${BINARY_NAME}"
SHA_URL="${BIN_URL}.sha256"

# --- Skip if already at target version ---
if command -v "${BINARY_NAME}" >/dev/null 2>&1; then
  CURRENT_VER="$(${BINARY_NAME} version --client 2>/dev/null | sed -n 's/^Client Version: //p' | head -n1 || true)"
  if [[ -n "${CURRENT_VER:-}" && "${CURRENT_VER}" == "${KUBECTL_VERSION}" ]]; then
    log "kubectl ${CURRENT_VER} already installed at $(command -v kubectl); nothing to do."
    exit 0
  else
    log "Installed kubectl version: ${CURRENT_VER:-unknown}, target: ${KUBECTL_VERSION}"
  fi
fi

# --- Work in a temp dir, auto-clean on exit ---
TMPDIR="$(mktemp -d)"; cleanup() { rm -rf "$TMPDIR"; }; trap cleanup EXIT

log "Downloading ${BINARY_NAME} ${KUBECTL_VERSION} for ${OS}/${K_arch}..."
curl -fL --retry 3 -o "${TMPDIR}/${BINARY_NAME}" "${BIN_URL}"

log "Downloading SHA256 and verifying..."
SHA_EXPECTED="$(curl -fL --retry 3 "${SHA_URL}")"
echo "${SHA_EXPECTED}  ${TMPDIR}/${BINARY_NAME}" | sha256sum -c - >/dev/null

log "Installing to ${INSTALL_DIR}/${BINARY_NAME} (requires sudo)..."
sudo install -m 0755 -o root -g root -T "${TMPDIR}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"

# Optional: install bash/zsh completions if available
if command -v "${BINARY_NAME}" >/dev/null 2>&1; then
  if [[ -d /etc/bash_completion.d ]]; then
    log "Installing bash completion to /etc/bash_completion.d/kubectl"
    "${INSTALL_DIR}/${BINARY_NAME}" completion bash | sudo tee /etc/bash_completion.d/kubectl >/dev/null || true
  fi
  if [[ -d /usr/share/zsh/vendor-completions ]]; then
    log "Installing zsh completion to /usr/share/zsh/vendor-completions/_kubectl"
    "${INSTALL_DIR}/${BINARY_NAME}" completion zsh | sudo tee /usr/share/zsh/vendor-completions/_kubectl >/dev/null || true
  fi
fi

log "Verifying installation..."
"${INSTALL_DIR}/${BINARY_NAME}" version --client
log "kubectl ${KUBECTL_VERSION} installed successfully to ${INSTALL_DIR}/${BINARY_NAME}"
