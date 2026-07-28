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
verify_name="medical-box-production-restore-verify-${run_id}"
database_password="restore-verification-only"
cleanup_pending=true
container_names=("${restore_name}" "${verify_name}")

docker_container_exists() {
  local expected_name="$1"
  local names
  if ! names="$(docker container ls --all --format '{{.Names}}')"; then
    echo "Could not enumerate Docker containers during cleanup verification." >&2
    return 2
  fi
  while IFS= read -r actual_name; do
    if [[ "${actual_name}" == "${expected_name}" ]]; then
      return 0
    fi
  done <<<"${names}"
  return 1
}

docker_network_exists() {
  local expected_name="$1"
  local names
  if ! names="$(docker network ls --format '{{.Name}}')"; then
    echo "Could not enumerate Docker networks during cleanup verification." >&2
    return 2
  fi
  while IFS= read -r actual_name; do
    if [[ "${actual_name}" == "${expected_name}" ]]; then
      return 0
    fi
  done <<<"${names}"
  return 1
}

cleanup_resources() {
  local cleanup_status=0
  local resource_name
  local state_status

  for resource_name in "${container_names[@]}"; do
    if docker_container_exists "${resource_name}"; then
      state_status=0
    else
      state_status=$?
    fi
    if [[ "${state_status}" -eq 0 ]]; then
      if ! docker rm --force "${resource_name}" >/dev/null; then
        echo "Could not remove Docker container: ${resource_name}" >&2
        cleanup_status=1
      fi
    elif [[ "${state_status}" -ne 1 ]]; then
      cleanup_status=1
    fi
  done

  if docker_network_exists "${network_name}"; then
    state_status=0
  else
    state_status=$?
  fi
  if [[ "${state_status}" -eq 0 ]]; then
    if ! docker network rm "${network_name}" >/dev/null; then
      echo "Could not remove Docker network: ${network_name}" >&2
      cleanup_status=1
    fi
  elif [[ "${state_status}" -ne 1 ]]; then
    cleanup_status=1
  fi

  for resource_name in "${container_names[@]}"; do
    if docker_container_exists "${resource_name}"; then
      state_status=0
    else
      state_status=$?
    fi
    if [[ "${state_status}" -eq 0 ]]; then
      echo "Docker container remains after cleanup: ${resource_name}" >&2
      cleanup_status=1
    elif [[ "${state_status}" -ne 1 ]]; then
      cleanup_status=1
    fi
  done

  if docker_network_exists "${network_name}"; then
    state_status=0
  else
    state_status=$?
  fi
  if [[ "${state_status}" -eq 0 ]]; then
    echo "Docker network remains after cleanup: ${network_name}" >&2
    cleanup_status=1
  elif [[ "${state_status}" -ne 1 ]]; then
    cleanup_status=1
  fi

  return "${cleanup_status}"
}

cleanup_on_exit() {
  local original_status=$?
  local cleanup_status=0
  trap - EXIT
  if [[ "${cleanup_pending}" == true ]]; then
    if cleanup_resources; then
      cleanup_status=0
    else
      cleanup_status=$?
    fi
  fi
  if [[ "${original_status}" -ne 0 ]]; then
    exit "${original_status}"
  fi
  exit "${cleanup_status}"
}
trap cleanup_on_exit EXIT

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

docker_arguments=(--rm --name "${verify_name}" --network "${network_name}")
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

if ! cleanup_resources; then
  echo "Production restore verification succeeded, but deterministic cleanup verification failed." >&2
  exit 1
fi
cleanup_pending=false
trap - EXIT
printf 'cleanup_verified=true\n'
