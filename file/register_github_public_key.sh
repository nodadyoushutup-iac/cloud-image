#!/bin/bash -eu

# Get GitHub PAT from first argument or environment
GITHUB_PAT="${1:-${GITHUB_PAT:-}}"

# SSH directory defaults to ~/.ssh or second argument
SSH_DIR="${2:-$HOME/.shh}"

# Validate PAT
if [[ -z "$GITHUB_PAT" ]]; then
  echo "Usage: $0 <github_pat> [ssh_dir]"
  exit 1
fi

# Determine local Linux username and hostname
LOCAL_USER="$(id -un)"
HOSTNAME="$(hostname)"

# Retrieve SMBIOS UUID for consistent unique suffix
if [[ -r /sys/class/dmi/id/product_uuid ]]; then
  UUID_SUFFIX="$(< /sys/class/dmi/id/product_uuid)"
elif command -v dmidecode &> /dev/null; then
  UUID_SUFFIX="$(sudo dmidecode -s system-uuid)"
else
  echo "Error: Unable to retrieve SMBIOS UUID. Ensure /sys/class/dmi/id/product_uuid is readable or install dmidecode."
  exit 1
fi

# Pre-generate date and title for key
DATE_SUFFIX="$(date +%Y-%m-%d)"
TITLE="${LOCAL_USER}@${HOSTNAME}-${DATE_SUFFIX}-${UUID_SUFFIX}"
KEY_NAME="$TITLE"

# Ensure SSH directory exists with proper permissions
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Locate or generate SSH public key
if [[ -f "$SSH_DIR/id_ed25519.pub" ]]; then
  PUB_KEY_FILE="$SSH_DIR/id_ed25519.pub"
elif [[ -f "$SSH_DIR/id_rsa.pub" ]]; then
  PUB_KEY_FILE="$SSH_DIR/id_rsa.pub"
elif [[ -f "$SSH_DIR/$KEY_NAME.pub" ]]; then
  PUB_KEY_FILE="$SSH_DIR/$KEY_NAME.pub"
else
  ssh-keygen -t ed25519 -f "$SSH_DIR/$KEY_NAME" -N "" -q
  PUB_KEY_FILE="$SSH_DIR/$KEY_NAME.pub"
  echo "Generated new SSH key at $SSH_DIR/$KEY_NAME"
fi

# Read public key and extract base64 part
PUB_KEY_CONTENT=$(<"$PUB_KEY_FILE")
PUB_KEY_B64=$(awk '{print $2}' <"$PUB_KEY_FILE")

# Fetch existing GitHub SSH keys
echo "Fetching existing SSH keys from GitHub..."
EXISTING_KEYS=$(curl -s \
  -H "Authorization: token $GITHUB_PAT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/keys)

# Skip if already registered
if echo "$EXISTING_KEYS" | grep -Fq "$PUB_KEY_B64"; then
  echo "This SSH key is already registered on GitHub. Nothing to do."
  exit 0
fi

# Prepare payload and add new SSH key
data=$(printf '{"title":"%s","key":"%s"}' "$TITLE" "$PUB_KEY_CONTENT")
echo "Adding new SSH key to GitHub with title '$TITLE'..."
RESPONSE=$(curl -s \
  -H "Authorization: token $GITHUB_PAT" \
  -H "Content-Type: application/json" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "$data" \
  https://api.github.com/user/keys)

# Verify success
if echo "$RESPONSE" | grep -Fq '"id":'; then
  echo "SSH key successfully added to GitHub."
else
  echo "Failed to add SSH key. GitHub response:"
  echo "$RESPONSE"
  exit 1
fi