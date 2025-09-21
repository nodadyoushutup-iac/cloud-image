#!/bin/bash
# --- USER SYNC (idempotent) ---

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(eval echo "~$TARGET_USER")"
TARGET_GROUP="$(id -gn "$TARGET_USER")"

if [[ -z "$TARGET_GROUP" ]]; then
  echo "Unable to determine primary group for $TARGET_USER" >&2
  exit 1
fi

SRC_SSH="/mnt/eapp/skel/.ssh"
SRC_KUBE="/mnt/eapp/skel/.kube"
SRC_TFVARS="/mnt/eapp/skel/.tfvars"
SRC_JENKINS="/mnt/eapp/skel/.jenkins"
SRC_GITCONFIG="/mnt/eapp/skel/.home/.gitconfig"

# Ensure backing directories exist (avoids failing on first run)
ensure_src_dir() {
  local dir="$1" perm="$2"
  if [[ -e "$dir" && ! -d "$dir" ]]; then
    echo "Expected directory at $dir but found a file" >&2
    exit 1
  fi
  if [[ ! -d "$dir" ]]; then
    install -d -m "$perm" -o "$TARGET_USER" -g "$TARGET_GROUP" "$dir"
  fi
  chown "$TARGET_USER:$TARGET_GROUP" "$dir"
  chmod "$perm" "$dir"
}

ensure_src_dir "$SRC_SSH" 700
ensure_src_dir "$SRC_KUBE" 755
ensure_src_dir "$SRC_TFVARS" 755
ensure_src_dir "$SRC_JENKINS" 755
ensure_src_dir "$(dirname "$SRC_GITCONFIG")" 755

# Basic exists checks (also triggers automounts)
for p in "$SRC_SSH" "$SRC_KUBE" "$SRC_TFVARS" "$SRC_JENKINS"; do
  [[ -d "$p" ]] || { echo "Missing: $p"; exit 1; }
done

mkdir -p "$TARGET_HOME/.ssh"
chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.ssh"
chmod 700 "$TARGET_HOME/.ssh"

# Prefer rsync for a clean sync without xattrs/ACLs; fallback to cp
if command -v rsync >/dev/null 2>&1; then
  # -rlt: recurse, preserve symlinks/modtimes (not owner/group/perms)
  # --no-perms --no-owner --no-group to avoid "Operation not supported"
  rsync -rlt --no-perms --no-owner --no-group \
        "${SRC_SSH}/" "$TARGET_HOME/.ssh/"
else
  # cp fallback: overwrite files, don't preserve perms/owner/timestamps
  cp -rf --no-preserve=mode,ownership,timestamps "${SRC_SSH}/." "$TARGET_HOME/.ssh/"
fi

# Fix SSH ownership & perms (self-corrects each run)
chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.ssh"
# dirs 700
find "$TARGET_HOME/.ssh" -type d -exec chmod 700 {} +
# public/known_hosts 644; everything else 600
find "$TARGET_HOME/.ssh" -maxdepth 1 -type f -name "*.pub" -exec chmod 644 {} +
[[ -f "$TARGET_HOME/.ssh/known_hosts" ]] && chmod 644 "$TARGET_HOME/.ssh/known_hosts"
find "$TARGET_HOME/.ssh" -type f ! -name "*.pub" ! -name "known_hosts" -exec chmod 600 {} +

# Helper to make/repair symlink (backs up non-link targets)
ensure_symlink() {
  local src="$1" dest="$2"
  if [[ -L "$dest" ]]; then
    # already a symlink — check target
    if [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
      return 0
    else
      rm -f "$dest"
    fi
  elif [[ -e "$dest" ]]; then
    mv -T "$dest" "${dest}.bak.$(date +%F_%H-%M-%S)"
  fi
  ln -s -T "$src" "$dest"
}

# Create/repair symlinks in $HOME
ensure_symlink "$SRC_KUBE"   "$TARGET_HOME/.kube"
ensure_symlink "$SRC_TFVARS" "$TARGET_HOME/.tfvars"
ensure_symlink "$SRC_JENKINS" "$TARGET_HOME/.jenkins"
# Make sure the links themselves are owned by the user
chown -h "$TARGET_USER:$TARGET_USER" \
  "$TARGET_HOME/.kube" "$TARGET_HOME/.tfvars" "$TARGET_HOME/.jenkins" || true

# Kubernetes likes strict perms on config
[[ -f "$TARGET_HOME/.kube/config" || -L "$TARGET_HOME/.kube/config" ]] && chmod 600 "$TARGET_HOME/.kube/config" || true

# Install/repair .gitconfig (back up if content differs)
if [[ -f "$SRC_GITCONFIG" ]]; then
  DEST_GIT="$TARGET_HOME/.gitconfig"
  if [[ -f "$DEST_GIT" ]] && ! cmp -s "$SRC_GITCONFIG" "$DEST_GIT"; then
    mv -T "$DEST_GIT" "${DEST_GIT}.bak.$(date +%F_%H-%M-%S)"
  fi
  install -m 600 -o "$TARGET_USER" -g "$TARGET_USER" "$SRC_GITCONFIG" "$DEST_GIT"
fi

echo "User sync complete for $TARGET_USER"
