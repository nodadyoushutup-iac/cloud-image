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
ROOT="$(cd -P "$(dirname "$SOURCE")" && pwd)"
UBUNTU_DIR="$ROOT/ubuntu"

# Scripts to run (order matters)
SCRIPTS=(apt docker kubectl k9s packer terraform node_exporter ansible yq)

# Allow running a subset: ./run-all.sh docker kubectl
if (( $# )); then
  SCRIPTS=("$@")
fi

# Ensure they’re executable
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

log "all done."
