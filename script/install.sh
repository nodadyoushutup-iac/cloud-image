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
SYSTEM_DIR="$ROOT/system"

run_system_script() {
  local name="$1"
  shift || true
  local path="$SYSTEM_DIR/$name.sh"
  [[ -f "$path" ]] || die "missing script: $path"
  log "running $path ..."
  if (( EUID == 0 )); then
    "$path" "$@"
  else
    sudo "$path" "$@"
  fi
}

PACKAGE_ARGS=("$@")
run_system_script packages "${PACKAGE_ARGS[@]}"
# Run swap_gpio ahead of fstab so user/group IDs are correct before chowning mounts.
run_system_script swap_gpio
run_system_script fstab

log "all done."
