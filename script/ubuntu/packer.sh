#!/bin/bash
set -euo pipefail

log()  { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
die()  { echo "[ERROR] $*" >&2; exit 1; }
trap 'die "failed at line $LINENO"' ERR

# --- Config / Overrides ---
INSTALL_DIR="/usr/local/bin"
BIN="packer"
PACKER_VERSION="${PACKER_VERSION:-}"     # e.g. 1.11.2 ; if empty, prefer APT (or latest from releases on fallback)

# --- Non-interactive apt/dpkg ---
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1
APT_OPTS=(-y -q -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold")
PHASE_OPTS=(-o APT::Get::Always-Include-Phased-Updates=true)

# --- Preflight ---
command -v curl >/dev/null 2>&1 || die "curl is required (apt-get install -y curl)."
command -d sha256sum >/dev/null 2>&1 || command -v sha256sum >/dev/null 2>&1 || die "sha256sum (coreutils) required."
command -v unzip >/dev/null 2>&1 || { log "Installing unzip prerequisite..."; sudo apt-get update -y -q; sudo apt-get install "${APT_OPTS[@]}" unzip >/dev/null; }

ARCH_DEB="$(dpkg --print-architecture || echo unknown)"   # amd64, arm64, ...
case "$ARCH_DEB" in
  amd64) REL_ARCH="amd64" ;;
  arm64) REL_ARCH="arm64" ;;
  *)     warn "Unsupported arch for direct releases: ${ARCH_DEB}. APT may still work."; REL_ARCH="" ;;
esac

OS_CODENAME="$(. /etc/os-release 2>/dev/null && echo "${VERSION_CODENAME:-}" || true)"

have_url() { curl -fsSL --retry 3 --max-time 10 -o /dev/null "$1"; }
choose_repo_codename() {
  local c
  for c in "${OS_CODENAME:-}" noble jammy focal; do
    [[ -n "$c" ]] || continue
    have_url "https://apt.releases.hashicorp.com/dists/${c}/Release" && { echo "$c"; return; }
  done
  echo ""   # signal "no apt repo for this codename"
}

install_via_apt() {
  log "Attempting APT install for HashiCorp Packer..."

  # prerequisites for repo
  sudo apt-get update -y -q
  sudo apt-get install "${APT_OPTS[@]}" ca-certificates gnupg lsb-release apt-transport-https >/dev/null

  # keyring
  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/hashicorp.gpg ]]; then
    curl -fsSL --retry 3 https://apt.releases.hashicorp.com/gpg \
      | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
    sudo chmod a+r /etc/apt/keyrings/hashicorp.gpg
  fi

  local CODENAME; CODENAME="$(choose_repo_codename)"
  if [[ -z "$CODENAME" ]]; then
    warn "No suitable HashiCorp APT codename found; will fall back to direct download."
    return 1
  fi

  echo "deb [arch=${ARCH_DEB} signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com ${CODENAME} main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

  sudo apt-get update -y -q
  # If user explicitly asked for a version, prefer direct install path (APT usually offers a single current version)
  if [[ -n "${PACKER_VERSION}" ]]; then
    warn "PACKER_VERSION specified (${PACKER_VERSION}); skipping APT (will install from releases)."
    return 1
  fi

  sudo apt-get install "${APT_OPTS[@]}" "${PHASE_OPTS[@]}" packer && return 0

  warn "APT install failed; will fall back to direct download."
  return 1
}

latest_release_version() {
  # Pull from releases index; prefer jq if present
  local ver
  if command -v jq >/dev/null 2>&1; then
    ver="$(curl -fsSL --retry 3 https://releases.hashicorp.com/packer/index.json | jq -r '.versions | keys | map(select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))) | sort_by(split(".")|map(tonumber)) | last')" || true
  else
    # minimal fallback parse
    ver="$(curl -fsSL --retry 3 https://releases.hashicorp.com/packer/index.json | grep -oE '"[0-9]+\.[0-9]+\.[0-9]+"' | tr -d '"' | sort -V | tail -n1)" || true
  fi
  echo "$ver"
}

install_via_releases() {
  local ver="${PACKER_VERSION:-}"
  if [[ -z "$ver" ]]; then
    log "Discovering latest Packer version from releases…"
    ver="$(latest_release_version)"
    [[ -n "$ver" ]] || die "Could not determine latest Packer version."
  fi

  [[ -n "$REL_ARCH" ]] || die "Direct releases do not support detected arch '${ARCH_DEB}'."

  local base="https://releases.hashicorp.com/packer/${ver}"
  local zip="packer_${ver}_linux_${REL_ARCH}.zip"
  local url="${base}/${zip}"
  local sums="${base}/packer_${ver}_SHA256SUMS"

  # Idempotency: skip if already that version
  if command -v "${BIN}" >/dev/null 2>&1; then
    set +e
    CURRENT="$(${BIN} version 2>/dev/null | head -n1 | tr -d 'v')"
    set -e
    if [[ "${CURRENT}" == "${ver}" ]]; then
      log "Packer ${ver} already installed at $(command -v ${BIN}); nothing to do."
      return 0
    else
      log "Installed Packer: ${CURRENT:-unknown}, target: ${ver}"
    fi
  fi

  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  log "Downloading ${url}…"
  curl -fL --retry 3 -o "${tmp}/${zip}" "${url}"

  log "Verifying SHA256…"
  curl -fL --retry 3 -o "${tmp}/SHA256SUMS" "${sums}"
  local expected
  expected="$(grep " ${zip}\$" "${tmp}/SHA256SUMS" | awk '{print $1}')" || true
  [[ -n "$expected" ]] || die "No checksum entry for ${zip}"
  echo "${expected}  ${tmp}/${zip}" | sha256sum -c - >/dev/null

  log "Extracting and installing to ${INSTALL_DIR}/${BIN}…"
  unzip -q -o "${tmp}/${zip}" -d "${tmp}"
  sudo install -m 0755 -o root -g root -T "${tmp}/${BIN}" "${INSTALL_DIR}/${BIN}"

  log "Installed $( "${INSTALL_DIR}/${BIN}" version )"
}

# --- Try APT first (unless a specific version is requested), else fall back ---
if install_via_apt; then
  log "Packer installed via APT: $(${BIN} --version)"
else
  install_via_releases
fi

log "Done."
