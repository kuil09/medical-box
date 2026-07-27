#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 /absolute/path/to/backup-key-directory" >&2
  exit 2
fi

key_directory="$1"
if [[ "${key_directory}" != /* ]] || [[ ! -d "${key_directory}" ]]; then
  echo "The key directory must be an existing absolute path." >&2
  exit 2
fi

private_key_file="${key_directory}/backup-private.gpg"
passphrase_file="${key_directory}/backup-passphrase.txt"
for required_file in "${private_key_file}" "${passphrase_file}"; do
  if [[ ! -f "${required_file}" ]]; then
    echo "Required key file is missing: ${required_file}" >&2
    exit 1
  fi
done

required_variables=(
  BACKUP_STORE
  BACKUP_PREFIX
  AWS_ENDPOINT_URL
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
  AWS_S3_BUCKET_NAME
  AWS_DEFAULT_REGION
  AWS_S3_ADDRESSING_STYLE
  BACKUP_MANIFEST_HMAC_KEY_BASE64
)
for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "Required backup variable is missing: ${variable_name}" >&2
    exit 1
  fi
done

backend_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
run_id="${RANDOM}-$$"
network_name="medical-box-production-restore-${run_id}"
restore_name="medical-box-production-restore-db-${run_id}"
database_password="restore-verification-only"

cleanup() {
  docker rm --force "${restore_name}" >/dev/null 2>&1 || true
  docker network rm "${network_name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker build \
  --file "${backend_root}/Dockerfile.backup" \
  --tag medical-box-backup:production \
  "${backend_root}"
docker network create "${network_name}" >/dev/null
docker run --detach \
  --name "${restore_name}" \
  --network "${network_name}" \
  --env "POSTGRES_PASSWORD=${database_password}" \
  --env POSTGRES_DB=medical_box \
  postgres:18-alpine >/dev/null

for _ in $(seq 1 60); do
  if docker exec "${restore_name}" pg_isready --username postgres >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
if ! docker exec "${restore_name}" pg_isready --username postgres >/dev/null 2>&1; then
  echo "Disposable PostgreSQL restore target did not become ready." >&2
  exit 1
fi

export APP_ENV=test
export APP_ROLE=backup_verify
export DATABASE_URL=postgresql://backup:unused@production.invalid:5432/medical_box
export BACKUP_GPG_PRIVATE_KEY_BASE64="$(
  base64 <"${private_key_file}" | tr -d '\n'
)"
export BACKUP_GPG_PASSPHRASE="$(<"${passphrase_file}")"
export BACKUP_RESTORE_DATABASE_URL="postgresql+psycopg://postgres:${database_password}@${restore_name}:5432/medical_box"
export BACKUP_RESTORE_CONFIRMATION=restore-disposable-database

docker_arguments=(--rm --network "${network_name}")
for variable_name in \
  APP_ENV \
  APP_ROLE \
  DATABASE_URL \
  BACKUP_STORE \
  BACKUP_PREFIX \
  AWS_ENDPOINT_URL \
  AWS_ACCESS_KEY_ID \
  AWS_SECRET_ACCESS_KEY \
  AWS_S3_BUCKET_NAME \
  AWS_DEFAULT_REGION \
  AWS_S3_ADDRESSING_STYLE \
  BACKUP_MANIFEST_HMAC_KEY_BASE64 \
  BACKUP_GPG_PRIVATE_KEY_BASE64 \
  BACKUP_GPG_PASSPHRASE \
  BACKUP_RESTORE_DATABASE_URL \
  BACKUP_RESTORE_CONFIRMATION; do
  docker_arguments+=(--env "${variable_name}")
done

docker run \
  "${docker_arguments[@]}" \
  medical-box-backup:production \
  uv run --no-sync medical-box-backup verify --restore
