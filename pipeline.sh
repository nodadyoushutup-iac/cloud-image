#!/usr/bin/env bash
set -euo pipefail

# Load environment variables from .env if present
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
else
  echo "[ERROR] .env file not found" >&2
  exit 1
fi

# Version is provided as the first argument
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi
VERSION="$1"

# Required parameters from environment
: "${CLOUD_IMAGE_REPOSITORY_URL:?CLOUD_IMAGE_REPOSITORY_URL environment variable is required}"

# Defaults
BASE_FILE_NAME="${FILE_NAME:-jammy-cloud-image-amd64}"
FILE_NAME="${BASE_FILE_NAME}-${VERSION}"
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)/output}"
RETAIN_ARTIFACTS="${RETAIN_ARTIFACTS:-false}"
export PACKER_LOG="${PACKER_LOG:-1}"

cleanup() {
  local exit_code="$1"
  echo "Post-build cleanup starting (ephemeral workspace)."
  set +e
  if [[ "${RETAIN_ARTIFACTS}" != "true" ]]; then
    rm -rf "${OUTPUT_DIR}" || true
  fi
  find "$(pwd)" -maxdepth 1 -type d -name 'packer_*' -exec rm -rf {} + 2>/dev/null || true
  if command -v find >/dev/null 2>&1; then
    find /tmp -maxdepth 1 -type d -name 'packer*' -mmin +10 -exec rm -rf {} + 2>/dev/null || true
  fi
  echo "Post-build cleanup complete."
  if [[ "$exit_code" -ne 0 ]]; then
    echo "Build failed."
  fi
  exit "$exit_code"
}
trap 'cleanup $?' EXIT

# Clean output directory
rm -rf "${OUTPUT_DIR}"

# Show build variables
echo "Building version: ${VERSION}"
echo "Final FILE_NAME: ${FILE_NAME}"
echo "OUTPUT_DIR: ${OUTPUT_DIR}"

# Packer stages
packer init cloud_image.pkr.hcl
packer validate cloud_image.pkr.hcl

mkdir -p "${OUTPUT_DIR}"
packer build \
  -force \
  -var="output_dir=${OUTPUT_DIR}" \
  -var="file_name=${FILE_NAME}" \
  cloud_image.pkr.hcl

sha256sum "${OUTPUT_DIR}/${FILE_NAME}.img" > "${OUTPUT_DIR}/${FILE_NAME}.img.sha256"

# Upload image to cloud repository
response=$(./script/upload_image.sh "${OUTPUT_DIR}/${FILE_NAME}.img" "${CLOUD_IMAGE_REPOSITORY_URL}/upload")
IMAGE_PATH=$(echo "$response" | jq -r '.path')
SHA256_PATH=$(echo "$response" | jq -r '.sha256_file')
IMAGE_SHA=$(echo "$response" | jq -r '.sha256')
echo "Image URL: ${CLOUD_IMAGE_REPOSITORY_URL}/${IMAGE_PATH}"
echo "Checksum URL: ${CLOUD_IMAGE_REPOSITORY_URL}/${SHA256_PATH}"
echo "SHA256: ${IMAGE_SHA}"

if [[ "${RETAIN_ARTIFACTS}" == "true" ]]; then
  echo "Artifacts retained in ${OUTPUT_DIR}"
fi
