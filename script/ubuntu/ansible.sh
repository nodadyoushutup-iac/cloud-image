#!/bin/bash
set -euo pipefail

log()  { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
die()  { echo "[ERROR] $*" >&2; exit 1; }
trap 'die "failed at line $LINENO"' ERR

# ---- Config / overrides -------------------------------------------------------
ANSIBLE_VERSION="${ANSIBLE_VERSION:-}"     # e.g. 9.10.0 (forces pipx path)
WANT_EXTRAS="${WANT_EXTRAS:-true}"         # install sshpass + argcomplete if present

# ---- Non-interactive APT / quieter installs ----------------------------------
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1
APT_OPTS=(-y -q -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold")
PHASE_OPTS=(-o APT::Get::Always-Include-Phased-Updates=true)

OS_CODENAME="$(. /etc/os-release 2>/dev/null && echo "${VERSION_CODENAME:-}" || true)"

have_url() { curl -fsSL --retry 3 --max-time 10 -o /dev/null "$1"; }
have_pkg() { apt-cache show "$1" >/dev/null 2>&1; }

ppa_present() {
  grep -qs "^deb .\+ansible/ansible" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null
}

install_from_ubuntu_repos() {
  log "Attempting install from Ubuntu repositories…"
  sudo apt-get update -y -q
  sudo apt-get install "${APT_OPTS[@]}" "${PHASE_OPTS[@]}" ca-certificates curl software-properties-common >/dev/null

  local pkg=""
  if have_pkg ansible; then
    pkg="ansible"
  elif have_pkg ansible-core; then
    pkg="ansible-core"
  else
    return 1
  fi

  log "Installing package: ${pkg}"
  sudo apt-get install "${APT_OPTS[@]}" "${PHASE_OPTS[@]}" "${pkg}"
  return 0
}

install_from_ppa() {
  log "Attempting install from Ansible PPA…"
  # Only if PPA publishes for this codename
  local rel="https://ppa.launchpadcontent.net/ansible/ansible/ubuntu/dists/${OS_CODENAME}/Release"
  if ! have_url "$rel"; then
    warn "Ansible PPA does not publish for '${OS_CODENAME}'."
    return 1
  fi

  sudo apt-get update -y -q
  sudo apt-get install "${APT_OPTS[@]}" software-properties-common ca-certificates curl >/dev/null

  if ! ppa_present; then
    sudo add-apt-repository --yes --update ppa:ansible/ansible >/dev/null
  else
    log "Ansible PPA already present; updating…"
    sudo apt-get update -y -q
  fi

  local pkg=""
  if have_pkg ansible; then
    pkg="ansible"
  elif have_pkg ansible-core; then
    pkg="ansible-core"
  else
    warn "No Ansible packages found after adding PPA."
    return 1
  fi

  log "Installing package from PPA: ${pkg}"
  sudo apt-get install "${APT_OPTS[@]}" "${PHASE_OPTS[@]}" "${pkg}"
  return 0
}

install_via_pipx() {
  log "Falling back to pipx installation…"
  sudo apt-get update -y -q
  sudo apt-get install "${APT_OPTS[@]}" python3-pip python3-venv pipx >/dev/null || {
    warn "pipx deb not available; installing via pip."
    sudo apt-get install "${APT_OPTS[@]}" python3-pip python3-venv >/dev/null
    python3 -m pip install --user --upgrade pipx
    python3 -m pipx ensurepath || true
  }

  # ensure pipx on PATH for this shell
  command -v pipx >/dev/null 2>&1 || export PATH="$HOME/.local/bin:$PATH"

  local spec="ansible"
  if [[ -n "${ANSIBLE_VERSION}" ]]; then
    spec="ansible==${ANSIBLE_VERSION}"
    log "Installing Ansible via pipx (version ${ANSIBLE_VERSION})…"
  else
    log "Installing Ansible via pipx (latest)…"
  fi

  pipx install --force "${spec}"

  # Optional lint helper (best-effort)
  pipx inject ansible ansible-lint >/dev/null 2>&1 || true
}

install_extras() {
  [[ "${WANT_EXTRAS}" == "true" ]] || return 0
  log "Installing optional extras (sshpass, argcomplete)…"
  sudo apt-get install "${APT_OPTS[@]}" sshpass python3-argcomplete >/dev/null || true
}

already_installed() {
  if command -v ansible >/dev/null 2>&1; then
    log "Ansible already installed: $(ansible --version | head -n1)"
    # If a version pin is requested, we’ll still do pipx install later
    [[ -z "${ANSIBLE_VERSION}" ]] && return 0
  fi
  return 1
}

# --- Main ---------------------------------------------------------------------
command -v curl >/dev/null 2>&1 || die "curl is required (apt-get install -y curl)."

if already_installed; then
  log "Nothing to do."
  exit 0
fi

if [[ -z "${ANSIBLE_VERSION}" ]]; then
  if install_from_ubuntu_repos; then
    :
  elif install_from_ppa; then
    :
  else
    install_via_pipx
  fi
else
  # explicit version requested => pipx path
  install_via_pipx
fi

install_extras

# Verify
if command -v ansible >/dev/null 2>&1; then
  ansible --version
  log "Ansible installation complete."
else
  die "Ansible not found after installation steps."
fi
