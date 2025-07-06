#!/bin/bash -eu

# Get GitHub PAT from first argument or environment
GITHUB_PAT="${1:-${GITHUB_PAT:-}}"

# SSH directory defaults to ~/.ssh or second argument
SSH_DIR="${2:-$HOME/.ssh}"

# Validate PAT
if [[ -z "$GITHUB_PAT" ]]; then
  echo "Usage: $0 <github_pat> [ssh_dir]"
  exit 1
fi

# Ensure uuidgen is available for unique filenames
if ! command -v uuidgen &> /dev/null; then
  echo "Error: uuidgen not found. Install with: sudo apt update && sudo apt install -y uuid-runtime"
  exit 1
fi

# Determine local Linux username and hostname
LOCAL_USER="$(id -un)"
HOSTNAME="$(hostname)"

# Pre-generate suffixes for naming consistency
DATE_SUFFIX="$(date +%Y-%m-%d)"
UUID_SUFFIX="$(uuidgen)"

# Ensure SSH directory exists with proper permissions
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Locate or generate SSH public key
if [[ -f "$SSH_DIR/id_ed25519.pub" ]]; then
  PUB_KEY_FILE="$SSH_DIR/id_ed25519.pub"
elif [[ -f "$SSH_DIR/id_rsa.pub" ]]; then
  PUB_KEY_FILE="$SSH_DIR/id_rsa.pub"
else
  KEY_NAME="${LOCAL_USER}@${HOSTNAME}-${DATE_SUFFIX}-${UUID_SUFFIX}"
  ssh-keygen -t ed25519 -f "$SSH_DIR/$KEY_NAME" -N "" -q
  PUB_KEY_FILE="$SSH_DIR/$KEY_NAME.pub"
  echo "Generated new SSH key at $SSH_DIR/$KEY_NAME"
fi

# Read the public key content
PUB_KEY_CONTENT=$(<"$PUB_KEY_FILE")

# Fetch existing GitHub SSH keys
echo "Fetching existing SSH keys from GitHub..."
EXISTING_KEYS=$(curl -s -H "Authorization: token $GITHUB_PAT" \
  https://api.github.com/user/keys)

# Check if key already exists on GitHub
if echo "$EXISTING_KEYS" | grep -Fq "$PUB_KEY_CONTENT"; then
  echo "This SSH key is already registered on GitHub."
  exit 0
fi

# Prepare payload for new key, including your local user@hostname in the title
TITLE="${LOCAL_USER}@${HOSTNAME}-${DATE_SUFFIX}-${UUID_SUFFIX}"
DATA=$(printf '{"title":"%s","key":"%s"}' "$TITLE" "$PUB_KEY_CONTENT")

# Add the new SSH key via GitHub API
echo "Adding new SSH key to GitHub with title '$TITLE'..."
RESPONSE=$(curl -s -H "Authorization: token $GITHUB_PAT" \
  -H "Content-Type: application/json" \
  -d "$DATA" \
  https://api.github.com/user/keys)

# Verify success
if echo "$RESPONSE" | grep -Fq '"id":'; then
  echo "SSH key successfully added to GitHub."
else
  echo "Failed to add SSH key. GitHub response:"
  echo "$RESPONSE"
  exit 1
fi