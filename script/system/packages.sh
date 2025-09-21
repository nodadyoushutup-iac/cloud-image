#!/usr/bin/env bash
set -euo pipefail

log() { echo "[INFO] $*"; }
die() { echo "[ERROR] $*" >&2; exit 1; }
trap 'die "failed at line $LINENO"' ERR

# Resolve this script's directory (follow symlinks)
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SYSTEM_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
ROOT_DIR="$(cd -P "$SYSTEM_DIR/.." && pwd)"
UBUNTU_DIR="$ROOT_DIR/ubuntu"

SCRIPTS=(apt docker kubectl k9s packer terraform node_exporter ansible yq)

# Allow running a subset of package scripts: packages.sh docker kubectl
if (( $# )); then
  SCRIPTS=("$@")
fi

# Ensure the ubuntu scripts are executable
chmod +x "$UBUNTU_DIR"/*.sh

run_step() {
  local name="$1"
  local path="$UBUNTU_DIR/$name.sh"
  [[ -f "$path" ]] || die "missing script: $path"
  log "running $path ..."
  if (( EUID == 0 )); then
    "$path"
  else
    sudo "$path"
  fi
}

for s in "${SCRIPTS[@]}"; do
  run_step "$s"
done

log "package installation complete."
