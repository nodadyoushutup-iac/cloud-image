#!/bin/bash
set -euo pipefail

log()  { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }

ARCH="$(dpkg --print-architecture || echo unknown)"  # amd64, arm64, etc.

# Non-interactive APT env and options
APT_ENV=(
  DEBIAN_FRONTEND=noninteractive
  NEEDRESTART_MODE=a          # auto-restart services
  APT_LISTCHANGES_FRONTEND=none
)
APT_OPTS=(
  -y -q
  -o Dpkg::Options::="--force-confdef"
  -o Dpkg::Options::="--force-confold"
)
# Include phased updates so “deferred due to phasing” doesn’t appear
PHASE_OPTS=(-o APT::Get::Always-Include-Phased-Updates=true)

have_pkg() { apt-cache show "$1" >/dev/null 2>&1; }

add_pkg() {
  local pkg="$1"
  if have_pkg "$pkg"; then PKGS+=("$pkg"); else warn "Skipping missing package: $pkg"; fi
}

add_first_available() {
  for p in "$@"; do
    if have_pkg "$p"; then PKGS+=("$p"); return 0; fi
  done
  warn "None of the alternatives exist: $*"
  return 1
}

log "Starting apt update, upgrade, and package installation..."

log "Updating apt cache..."
sudo "${APT_ENV[@]}" apt-get update -y -q

# Preseed packages that might prompt
if have_pkg iperf3; then
  echo "iperf3 iperf3/start_daemon boolean false" | sudo debconf-set-selections
fi

log "Building package list..."
PKGS=(
  bat
  bridge-utils
  btop
  cpu-checker
  curl
  dnsutils
  duf
  ethtool
  fd-find
  gh
  git
  htop
  ifupdown
  iotop
  iperf3
  iptables
  jq
  libvirt-clients
  libvirt-daemon-system
  lshw
  lsof
  make
  nano
  net-tools
  neovim
  nfs-common
  nmap
  nvtop
  open-iscsi
  parted
  postgresql-client
  python3
  python3-pip
  python3-venv
  qemu-guest-agent
  qemu-system
  ripgrep
  rsync
  screen
  smartmontools
  strace
  tcpdump
  tmux
  traceroute
  tree
  ufw
  unzip
  util-linux
  vim
  virtinst
  wget
  whois
  xorriso
  zip
)

# MySQL client (quietly pick a valid one)
add_first_available mysql-client-core default-mysql-client mariadb-client-core || true

# netcat is virtual; choose an implementation
add_first_available netcat-openbsd netcat-traditional || true

# QEMU/KVM arch specifics
if [[ "$ARCH" == "amd64" ]]; then
  add_pkg qemu-kvm
  add_pkg qemu-system-x86
elif [[ "$ARCH" == "arm64" ]]; then
  add_pkg qemu-system-arm
  add_pkg qemu-system-misc
else
  warn "Unknown architecture '$ARCH'; skipping arch-specific QEMU packages."
fi

log "Installing apt packages..."
sudo "${APT_ENV[@]}" apt-get install "${APT_OPTS[@]}" "${PHASE_OPTS[@]}" "${PKGS[@]}"

log "Upgrading packages (non-interactive, include phased updates)..."
sudo "${APT_ENV[@]}" apt-get full-upgrade "${APT_OPTS[@]}" "${PHASE_OPTS[@]}"

log "Cleaning up..."
sudo "${APT_ENV[@]}" apt-get autoremove --purge -y -q
sudo "${APT_ENV[@]}" apt-get autoclean -y -q

log "All tasks completed successfully!"
