#!/usr/bin/env bash
# swap-gpio-and-usergroup.sh
# Move a user's primary group to GID 1000 and give gpio the user's old GID,
# preserving file group ownerships along the way.

set -euo pipefail

# ---------- Config ----------
TARGET_USER="${1:-${SUDO_USER:-${USER}}}"   # arg1 or sudo invoker or current user
TARGET_GID=1000                             # the destination GID for the user group
DRY_RUN="${DRY_RUN:-0}"                     # set DRY_RUN=1 to preview chgrp changes
# Space-separated mount points to scan for on-disk fixes (defaults to only '/').
# Example: SCAN_MOUNTS="/ /mnt /media"
SCAN_MOUNTS="${SCAN_MOUNTS:-/}"

# Exclusions for virtual/ephemeral trees (pattern for find -path)
PRUNE_PATHS=(
  "/proc/*" "/sys/*" "/run/*" "/dev/*" "/snap/*" "/tmp/*"
)

log() { printf '[%s] %s\n' "$(date +'%F %T')" "$*" >&2; }

need_root() { if [[ "${EUID}" -ne 0 ]]; then log "Please run as root (sudo)."; exit 1; fi; }

backup_group_files() {
  cp -a /etc/group "/etc/group.bak.$(date +%F-%H%M%S)"
  cp -a /etc/gshadow "/etc/gshadow.bak.$(date +%F-%H%M%S)"
  log "Backed up /etc/group and /etc/gshadow."
}

get_group_name_for_user() {
  # Primary group name for the user
  id -gn "$1"
}

get_gid_of_group() {
  local g="$1"
  getent group "$g" | awk -F: '{print $3}'
}

find_free_gid() {
  # Search a high range for a free GID
  local gid
  for gid in $(seq 60000 -1 2000); do
    if ! getent group "$gid" >/dev/null; then
      echo "$gid"
      return 0
    fi
  done
  return 1
}

chgrp_by_gid() {
  local old_gid="$1"
  local new_group="$2"
  local dry="$3"

  # Build -prune expression
  local prune_expr=()
  for p in "${PRUNE_PATHS[@]}"; do
    prune_expr+=( -path "$p" -o )
  done

  for mount in $SCAN_MOUNTS; do
    # -xdev stays on this filesystem; avoids sprawling over NFS/other disks unless user opts-in via SCAN_MOUNTS
    if [[ "$dry" == "1" ]]; then
      log "DRY-RUN: would reassign files on $mount with GID=$old_gid -> group '$new_group'"
      find "$mount" -xdev \( "${prune_expr[@]}" -false \) -prune -o -gid "$old_gid" -print
    else
      log "Reassigning files on $mount with GID=$old_gid -> group '$new_group' (may take a while)…"
      find "$mount" -xdev \( "${prune_expr[@]}" -false \) -prune -o -gid "$old_gid" -exec chgrp -h "$new_group" {} +
    fi
  done
}

reload_udev_gpio() {
  # Refresh device node permissions for gpio things
  udevadm control --reload || true
  udevadm trigger --subsystem-match=gpio || true
}

main() {
  need_root

  # Resolve groups & IDs
  local user_group; user_group="$(get_group_name_for_user "$TARGET_USER")"
  if [[ -z "$user_group" ]]; then
    log "Could not determine primary group for user '$TARGET_USER'."; exit 1;
  fi

  local gid_user gid_gpio
  gid_user="$(get_gid_of_group "$user_group")"
  gid_gpio="$(get_gid_of_group gpio || true)"

  if [[ -z "$gid_user" ]]; then log "Group '$user_group' not found in /etc/group."; exit 1; fi
  if [[ -z "$gid_gpio" ]]; then log "Group 'gpio' not found in /etc/group."; exit 1; fi

  log "User:        $TARGET_USER"
  log "User group:  $user_group (GID $gid_user)"
  log "gpio group:  gpio (GID $gid_gpio)"
  log "Target GID for '$user_group' -> $TARGET_GID"

  # Sanity: if TARGET_GID already belongs to a third group, bail
  local group_at_target; group_at_target="$(getent group "$TARGET_GID" | cut -d: -f1 || true)"
  if [[ -n "$group_at_target" && "$group_at_target" != "$user_group" && "$group_at_target" != "gpio" ]]; then
    log "Refusing: GID $TARGET_GID is used by unrelated group '$group_at_target'. Adjust TARGET_GID or free it first."
    exit 1
  fi

  if [[ "$gid_user" -eq "$TARGET_GID" ]]; then
    log "Nothing to do: '$user_group' already has GID $TARGET_GID."
    exit 0
  fi

  backup_group_files

  # 1) Move gpio to a temp free GID
  local temp_gid; temp_gid="$(find_free_gid)"
  if [[ -z "$temp_gid" ]]; then log "Failed to find a temporary free GID."; exit 1; fi
  log "Using temporary GID $temp_gid for 'gpio'."
  groupmod -g "$temp_gid" gpio

  # 2) Re-own files that still carry the old numeric gpio GID to 'gpio' (now at temp_gid)
  chgrp_by_gid "$gid_gpio" "gpio" "$DRY_RUN"

  # 3) Move the user's primary group to TARGET_GID (1000)
  groupmod -g "$TARGET_GID" "$user_group"

  # 4) Re-own files that still carry the old numeric user-group GID to '$user_group' (now at TARGET_GID)
  chgrp_by_gid "$gid_user" "$user_group" "$DRY_RUN"

  # 5) Assign gpio to the user's *old* GID
  groupmod -g "$gid_user" gpio

  # 6) Refresh udev so GPIO device nodes follow the new gpio GID
  reload_udev_gpio

  log "Done. Current groups:"
  getent group "$user_group" gpio

  log "Tip: open a new shell (or log out/in) so your session picks up the new group IDs."
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY-RUN was enabled. Re-run with DRY_RUN=0 (default) to apply chgrp changes."
  fi
}

main "$@"
