#!/bin/bash
set -euo pipefail

log()  { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
die()  { echo "[ERROR] $*" >&2; exit 1; }
trap 'die "failed at line $LINENO"' ERR

# --- Config / Overrides ---
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="k9s"
OS="Linux"
K9S_VERSION="${K9S_VERSION:-}"   # e.g. v0.32.5

# --- Preflight ---
command -v curl >/dev/null 2>&1 || die "curl is required (apt-get install -y curl)."
command -v sha256sum >/dev/null 2>&1 || die "sha256sum is required (coreutils)."
sudo -n true 2>/dev/null || warn "sudo may prompt for your password."

# --- Helpers ---
have_url() { curl -fsI --retry 3 --max-time 10 "$1" >/dev/null; }

get_latest_version() {
  # Try GitHub API with jq, else parse JSON manually, else use HTTP redirect
  if command -v jq >/dev/null 2>&1; then
    curl -fsSL --retry 3 "https://api.github.com/repos/derailed/k9s/releases/latest" \
      | jq -r '.tag_name'
    return
  fi
  # crude JSON parse fallback
  curl -fsSL --retry 3 "https://api.github.com/repos/derailed/k9s/releases/latest" \
    | sed -n 's/.*"tag_name":[[:space:]]*"\(v[^"]*\)".*/\1/p' | head -n1 ||
  true
}

# Map dpkg arch to k9s asset arch
DEB_ARCH="$(dpkg --print-architecture || echo unknown)"
case "$DEB_ARCH" in
  amd64)    K_ARCH="amd64" ;;
  arm64)    K_ARCH="arm64" ;;
  armhf|armel) K_ARCH="arm" ;;           # try armv7 as alternate below
  ppc64el)  K_ARCH="ppc64le" ;;
  s390x)    K_ARCH="s390x" ;;
  riscv64)  K_ARCH="riscv64" ;;          # may not be published for all releases
  *)        die "Unsupported or unknown architecture: ${DEB_ARCH}" ;;
esac

# Resolve desired version
if [[ -z "${K9S_VERSION}" ]]; then
  log "Querying latest k9s release version..."
  K9S_VERSION="$(get_latest_version)"
  [[ -n "$K9S_VERSION" ]] || die "Unable to determine latest k9s version."
fi
[[ "$K9S_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Invalid version string: '${K9S_VERSION}'"

OWNER="derailed"
REPO="k9s"
BASE="https://github.com/${OWNER}/${REPO}/releases/download/${K9S_VERSION}"

# Candidate tarball names (some releases use Linux_arm vs Linux_armv7)
CANDIDATES=(
  "k9s_${OS}_${K_ARCH}.tar.gz"
)
if [[ "$K_ARCH" == "arm" ]]; then
  CANDIDATES+=("k9s_${OS}_armv7.tar.gz")
fi

# Pick the first asset that exists
TARBALL=""
for f in "${CANDIDATES[@]}"; do
  if have_url "${BASE}/${f}"; then TARBALL="$f"; break; fi
done
[[ -n "$TARBALL" ]] || die "No suitable k9s asset found for ${OS}/${K_ARCH} at ${K9S_VERSION}."

BIN_URL="${BASE}/${TARBALL}"
CHK_URL_A="${BASE}/checksums.txt"
CHK_URL_B="${BASE}/checksums.txt.asc"   # sometimes signed; we only use the txt if present

# Skip if already at target version
if command -v "${BINARY_NAME}" >/dev/null 2>&1; then
  set +e
  CURRENT_VER="$(${BINARY_NAME} version 2>/dev/null | sed -n 's/^Version:[[:space:]]*\(v\?[0-9.]*\).*/\1/p' | head -n1)"
  set -e
  if [[ -n "${CURRENT_VER:-}" && "${CURRENT_VER#v}" == "${K9S_VERSION#v}" ]]; then
    log "k9s ${CURRENT_VER} already installed at $(command -v k9s); nothing to do."
    exit 0
  else
    log "Installed k9s version: ${CURRENT_VER:-unknown}, target: ${K9S_VERSION}"
  fi
fi

# Work in a temp dir; auto-clean on exit
TMPDIR="$(mktemp -d)"; cleanup() { rm -rf "$TMPDIR"; }; trap cleanup EXIT

log "Downloading ${TARBALL} from ${BIN_URL}..."
curl -fL --retry 3 -o "${TMPDIR}/${TARBALL}" "${BIN_URL}"

# Try checksums verification if checksums.txt exists
if have_url "${CHK_URL_A}"; then
  log "Downloading checksums and verifying..."
  curl -fL --retry 3 -o "${TMPDIR}/checksums.txt" "${CHK_URL_A}"
  # Extract expected sha for the tarball
  SHA_EXPECTED="$(grep " ${TARBALL}\$" "${TMPDIR}/checksums.txt" | awk '{print $1}' || true)"
  if [[ -n "${SHA_EXPECTED}" ]]; then
    echo "${SHA_EXPECTED}  ${TMPDIR}/${TARBALL}" | sha256sum -c - >/dev/null
  else
    warn "checksums.txt present but no entry for ${TARBALL}; skipping verification."
  fi
else
  warn "No checksums.txt found for ${K9S_VERSION}; skipping SHA256 verification."
fi

log "Extracting k9s binary..."
tar -xzf "${TMPDIR}/${TARBALL}" -C "${TMPDIR}" || die "Failed to extract ${TARBALL}"

# Find the k9s binary in the archive (some archives include README/LICENSE)
K9S_PATH="$(find "${TMPDIR}" -maxdepth 1 -type f -name "${BINARY_NAME}" -perm -u+x | head -n1 || true)"
[[ -n "${K9S_PATH}" ]] || die "k9s binary not found in tarball."

log "Installing to ${INSTALL_DIR}/${BINARY_NAME}..."
sudo install -m 0755 -o root -g root -T "${K9S_PATH}" "${INSTALL_DIR}/${BINARY_NAME}"

# Optional: completions (best-effort)
if command -v "${INSTALL_DIR}/${BINARY_NAME}" >/dev/null 2>&1; then
  if [[ -d /etc/bash_completion.d ]]; then
    log "Installing bash completion to /etc/bash_completion.d/k9s"
    "${INSTALL_DIR}/${BINARY_NAME}" completion bash 2>/dev/null | sudo tee /etc/bash_completion.d/k9s >/dev/null || true
  fi
  if [[ -d /usr/share/zsh/vendor-completions ]]; then
    log "Installing zsh completion to /usr/share/zsh/vendor-completions/_k9s"
    "${INSTALL_DIR}/${BINARY_NAME}" completion zsh 2>/dev/null | sudo tee /usr/share/zsh/vendor-completions/_k9s >/dev/null || true
  fi
fi

log "Verifying installation..."
"${INSTALL_DIR}/${BINARY_NAME}" version || true
log "k9s ${K9S_VERSION} installed successfully to ${INSTALL_DIR}/${BINARY_NAME}"
