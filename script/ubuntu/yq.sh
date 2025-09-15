#!/bin/bash
set -euo pipefail

log()  { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
die()  { echo "[ERROR] $*" >&2; exit 1; }
trap 'die "failed at line $LINENO"' ERR

INSTALL_DIR="/usr/local/bin"
BIN="yq"
YQ_VERSION="${YQ_VERSION:-}"     # e.g. v4.44.3 (default: latest)
OWNER="mikefarah"
REPO="yq"

command -v curl >/dev/null 2>&1 || die "curl is required (apt-get install -y curl)."
command -v sha256sum >/dev/null 2>&1 || die "sha256sum (coreutils) required."
sudo -n true 2>/dev/null || warn "sudo may prompt for your password."

# Map dpkg arch -> yq asset suffix
DEB_ARCH="$(dpkg --print-architecture || echo unknown)"
case "$DEB_ARCH" in
  amd64)    YQ_ARCH="amd64" ;;
  arm64)    YQ_ARCH="arm64" ;;
  armhf|armel) YQ_ARCH="arm" ;;        # 32-bit ARM
  ppc64el)  YQ_ARCH="ppc64le" ;;
  s390x)    YQ_ARCH="s390x" ;;
  i386)     YQ_ARCH="386" ;;
  *)        die "Unsupported or unknown architecture: ${DEB_ARCH}" ;;
esac

# Resolve target version
get_latest_tag() {
  if command -v jq >/dev/null 2>&1; then
    curl -fsSL --retry 3 "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest" | jq -r '.tag_name'
  else
    curl -fsSL --retry 3 "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest" \
      | sed -n 's/.*"tag_name":[[:space:]]*"\(v[^"]*\)".*/\1/p' | head -n1
  fi
}
if [[ -z "${YQ_VERSION}" ]]; then
  log "Discovering latest ${REPO} version…"
  YQ_VERSION="$(get_latest_tag)"
  [[ -n "$YQ_VERSION" ]] || die "Could not determine latest version."
fi
[[ "$YQ_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Invalid version: ${YQ_VERSION}"

ASSET="yq_linux_${YQ_ARCH}"
BASE="https://github.com/${OWNER}/${REPO}/releases/download/${YQ_VERSION}"
BIN_URL="${BASE}/${ASSET}"
SUMS_URL="${BASE}/checksums"

# Skip if already at target version
if command -v "${BIN}" >/dev/null 2>&1; then
  set +e
  CURRENT="$(${BIN} --version 2>/dev/null | sed -n 's/.*version[[:space:]]*\([0-9.]\+\).*/\1/p' | head -n1)"
  set -e
  TARGET="${YQ_VERSION#v}"
  if [[ -n "${CURRENT:-}" && "${CURRENT}" == "${TARGET}" ]]; then
    log "yq v${CURRENT} already installed at $(command -v ${BIN}); nothing to do."
    exit 0
  else
    log "Installed yq: v${CURRENT:-unknown}, target: v${TARGET}"
  fi
fi

TMP="$(mktemp -d)"; cleanup(){ rm -rf "$TMP"; }; trap cleanup EXIT

log "Downloading ${BIN_URL}…"
curl -fL --retry 3 -o "${TMP}/${BIN}" "${BIN_URL}"

# Verify checksum if available
if curl -fsSL --retry 3 -o "${TMP}/checksums" "${SUMS_URL}"; then
  log "Verifying SHA256 checksum…"
  EXPECTED="$(grep " ${ASSET}\$" "${TMP}/checksums" | awk '{print $1}')" || true
  if [[ -n "${EXPECTED}" ]]; then
    echo "${EXPECTED}  ${TMP}/${BIN}" | sha256sum -c - >/dev/null
  else
    warn "checksums present but no entry for ${ASSET}; skipping verification."
  fi
else
  warn "No checksums file found for ${YQ_VERSION}; skipping SHA256 verification."
fi

log "Installing to ${INSTALL_DIR}/${BIN}…"
sudo install -m 0755 -o root -g root -T "${TMP}/${BIN}" "${INSTALL_DIR}/${BIN}"

# Optional shell completions (best-effort)
if command -v "${INSTALL_DIR}/${BIN}" >/dev/null 2>&1; then
  if [[ -d /etc/bash_completion.d ]]; then
    log "Installing bash completion to /etc/bash_completion.d/yq"
    "${INSTALL_DIR}/${BIN}" shell-completion bash | sudo tee /etc/bash_completion.d/yq >/dev/null || true
  fi
  if [[ -d /usr/share/zsh/vendor-completions ]]; then
    log "Installing zsh completion to /usr/share/zsh/vendor-completions/_yq"
    "${INSTALL_DIR}/${BIN}" shell-completion zsh | sudo tee /usr/share/zsh/vendor-completions/_yq >/dev/null || true
  fi
fi

log "Verifying installation…"
"${INSTALL_DIR}/${BIN}" --version
log "yq ${YQ_VERSION} installed successfully."
