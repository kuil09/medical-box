#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 /absolute/path/to/backup-key-directory" >&2
  exit 2
fi

for executable in railway jq base64 tr; do
  if ! command -v "${executable}" >/dev/null 2>&1; then
    echo "Required executable is missing: ${executable}" >&2
    exit 1
  fi
done

key_directory="$1"
if [[ "${key_directory}" != /* ]] || [[ ! -d "${key_directory}" ]]; then
  echo "The key directory must be an existing absolute path." >&2
  exit 2
fi

public_key_file="${key_directory}/backup-public.gpg"
hmac_key_file="${key_directory}/backup-manifest-hmac.key"
fingerprint_file="${key_directory}/backup-recipient-fingerprint.txt"
for required_file in "${public_key_file}" "${hmac_key_file}" "${fingerprint_file}"; do
  if [[ ! -f "${required_file}" ]]; then
    echo "Required key file is missing: ${required_file}" >&2
    exit 1
  fi
done

export RAILWAY_CALLER="${RAILWAY_CALLER:-skill:use-railway@1.3.6}"
export RAILWAY_AGENT_SESSION="${RAILWAY_AGENT_SESSION:-medical-box-backup-activation}"
environment_name="production"
service_name="production-backup"
bucket_name="production-backups"

status_file="$(mktemp)"
credentials_file="$(mktemp)"
cleanup() {
  rm -f "${status_file}" "${credentials_file}"
}
trap cleanup EXIT
chmod 600 "${status_file}" "${credentials_file}"

railway status --json >"${status_file}"
if [[ "$(jq -r '.name' "${status_file}")" != "medical-box" ]] ||
  [[ "$(jq -r '.environments.edges[].node.name' "${status_file}")" != *"production"* ]]; then
  echo "Railway is not linked to medical-box production." >&2
  exit 1
fi
if ! jq -e \
  --arg service "${service_name}" \
  'any(.services.edges[]; .node.name == $service)' \
  "${status_file}" >/dev/null; then
  echo "Railway service does not exist: ${service_name}" >&2
  exit 1
fi
if ! jq -e \
  --arg bucket "${bucket_name}" \
  'any(.buckets.edges[]; .node.name == $bucket)' \
  "${status_file}" >/dev/null; then
  echo "Railway bucket does not exist: ${bucket_name}" >&2
  exit 1
fi

railway bucket credentials \
  --bucket "${bucket_name}" \
  --environment "${environment_name}" \
  --json >"${credentials_file}"

set_literal() {
  local variable_name="$1"
  local value="$2"
  printf '%s' "${value}" |
    railway variable set \
      --service "${service_name}" \
      --environment "${environment_name}" \
      --skip-deploys \
      --stdin \
      "${variable_name}" >/dev/null
}

set_file_base64() {
  local variable_name="$1"
  local source_file="$2"
  base64 <"${source_file}" |
    tr -d '\n' |
    railway variable set \
      --service "${service_name}" \
      --environment "${environment_name}" \
      --skip-deploys \
      --stdin \
      "${variable_name}" >/dev/null
}

set_literal AWS_ENDPOINT_URL "$(jq -r '.endpoint' "${credentials_file}")"
set_literal AWS_ACCESS_KEY_ID "$(jq -r '.accessKeyId' "${credentials_file}")"
set_literal AWS_SECRET_ACCESS_KEY "$(jq -r '.secretAccessKey' "${credentials_file}")"
set_literal AWS_S3_BUCKET_NAME "$(jq -r '.bucketName' "${credentials_file}")"
set_literal AWS_DEFAULT_REGION "$(jq -r '.region' "${credentials_file}")"
set_literal AWS_S3_ADDRESSING_STYLE path
set_file_base64 BACKUP_GPG_PUBLIC_KEY_BASE64 "${public_key_file}"
set_literal BACKUP_GPG_RECIPIENT "$(<"${fingerprint_file}")"
set_file_base64 BACKUP_MANIFEST_HMAC_KEY_BASE64 "${hmac_key_file}"

echo "Production backup secrets were wired without triggering a deployment."
echo "The private decryption key was not sent to Railway."
