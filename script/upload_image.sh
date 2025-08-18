#!/bin/bash -eu

FILE="$1"
DEST="${2:-$CLOUD_REPOSITORY_URL/upload}"

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  echo "[ERROR] File not found: $FILE" >&2
  exit 1
fi

if [[ -z "${CLOUD_IMAGE_REPOSITORY_APIKEY:-}" ]]; then
  echo "[ERROR] CLOUD_IMAGE_REPOSITORY_APIKEY environment variable not set" >&2
  exit 1
fi

echo "[INFO] Uploading '${FILE}' → ${DEST}" >&2

response="$(curl -sS -H "CLOUD-REPOSITORY-APIKEY: ${CLOUD_IMAGE_REPOSITORY_APIKEY}" \
    -F "file=@${FILE}" \
    -w "\n%{http_code}" \
    "${DEST}" 2>&1)" || {
  echo "[ERROR] curl invocation failed" >&2
  exit 1
}

http_code="${response##*$'\n'}"
body="${response%$'\n'*}"

echo "$body"

if [[ "$http_code" =~ ^2 ]]; then
  echo "[INFO] Upload succeeded (HTTP ${http_code})" >&2
  exit 0
else
  echo "[ERROR] Upload failed (HTTP ${http_code})" >&2
  exit 1
fi

