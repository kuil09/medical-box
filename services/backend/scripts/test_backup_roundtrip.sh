#!/usr/bin/env bash

set -euo pipefail

backend_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(cd "${backend_root}/../.." && pwd)"
run_id="${RANDOM}-$$"
network_name="medical-box-backup-e2e-${run_id}"
source_name="medical-box-backup-source-${run_id}"
restore_name="medical-box-backup-restore-${run_id}"
lock_name="medical-box-backup-lock-${run_id}"
migration_name="medical-box-backup-migrate-${run_id}"
lock_probe_name="medical-box-backup-lock-probe-${run_id}"
released_probe_name="medical-box-backup-released-probe-${run_id}"
create_name="medical-box-backup-create-${run_id}"
verify_name="medical-box-backup-verify-${run_id}"
work_directory="$(mktemp -d)"
database_password="backup-e2e-only"
cleanup_pending=true
container_names=(
  "${source_name}"
  "${restore_name}"
  "${lock_name}"
  "${migration_name}"
  "${lock_probe_name}"
  "${released_probe_name}"
  "${create_name}"
  "${verify_name}"
)

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

  if [[ -e "${work_directory}" ]] &&
    ! rm -rf -- "${work_directory}"; then
    echo "Could not remove backup test work directory: ${work_directory}" >&2
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
  if [[ -e "${work_directory}" ]]; then
    echo "Backup test work directory remains after cleanup: ${work_directory}" >&2
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

wait_for_postgres() {
  local container_name="$1"
  for _ in $(seq 1 60); do
    if docker exec "${container_name}" pg_isready --username postgres >/dev/null 2>&1; then
      return
    fi
    sleep 1
  done
  echo "PostgreSQL did not become ready: ${container_name}" >&2
  exit 1
}

docker build \
  --file "${backend_root}/Dockerfile.backup" \
  --tag medical-box-backup:e2e \
  "${backend_root}"

docker network create "${network_name}" >/dev/null
docker run --detach \
  --name "${source_name}" \
  --network "${network_name}" \
  --env "POSTGRES_PASSWORD=${database_password}" \
  --env POSTGRES_DB=medical_box \
  postgres:18-alpine >/dev/null
wait_for_postgres "${source_name}"

docker run --rm \
  --name "${migration_name}" \
  --network "${network_name}" \
  --env APP_ENV=test \
  --env APP_ROLE=backup \
  --env "DATABASE_URL=postgresql+psycopg://postgres:${database_password}@${source_name}:5432/medical_box" \
  medical-box-backup:e2e \
  uv run --no-sync alembic upgrade head

docker exec "${source_name}" \
  psql --username postgres --dbname medical_box --set ON_ERROR_STOP=1 \
  --command "INSERT INTO source_registry (code, name, portal_url, enabled, updated_at) VALUES ('backup_e2e', 'Backup E2E source', 'https://example.invalid', true, now());" \
  >/dev/null
docker exec "${source_name}" \
  psql --username postgres --dbname medical_box --set ON_ERROR_STOP=1 \
  --command "INSERT INTO drug_products (item_seq, item_name, manufacturer, updated_at) VALUES ('E2E-0001', 'Backup verification product', 'Medical Box', now());" \
  >/dev/null

docker run --detach \
  --name "${lock_name}" \
  --network "${network_name}" \
  --env APP_ENV=test \
  --env "DATABASE_URL=postgresql+psycopg://postgres:${database_password}@${source_name}:5432/medical_box" \
  medical-box-backup:e2e \
  uv run --no-sync python -c \
  '
import time
from pathlib import Path

from sqlalchemy import text

from medical_box_api.catalog.locking import catalog_mutation_lock
from medical_box_api.db import SessionLocal, engine

with SessionLocal() as db:
    with catalog_mutation_lock(db):
        db.execute(text("SELECT 1"))
        db.commit()
        borrowed_connection = engine.connect()
        print("catalog-lock-acquired", flush=True)
        while not Path("/tmp/release-catalog-lock").exists():
            time.sleep(0.1)
    print("catalog-lock-released", flush=True)
    while not Path("/tmp/finish-catalog-lock").exists():
        time.sleep(0.1)
    borrowed_connection.close()
' \
  >/dev/null
for _ in $(seq 1 30); do
  if docker logs "${lock_name}" 2>&1 | grep --quiet catalog-lock-acquired; then
    break
  fi
  sleep 1
done
if ! docker logs "${lock_name}" 2>&1 | grep --quiet catalog-lock-acquired; then
  echo "Catalog lock holder did not become ready." >&2
  exit 1
fi

set +e
lock_probe_output="$(
  docker run --rm \
    --name "${lock_probe_name}" \
    --network "${network_name}" \
    --env "DATABASE_URL=postgresql://postgres:${database_password}@${source_name}:5432/medical_box" \
    medical-box-backup:e2e \
    uv run --no-sync python -c \
    'import os; from medical_box_api.backup.service import backup_advisory_lock; lock=backup_advisory_lock(os.environ["DATABASE_URL"]); lock.__enter__()' \
    2>&1
)"
lock_probe_status=$?
set -e
if [[ "${lock_probe_status}" -eq 0 ]] ||
  [[ "${lock_probe_output}" != *"Catalog synchronization is active"* ]]; then
  echo "Backup did not reject an active catalog mutation." >&2
  exit 1
fi

docker exec "${lock_name}" touch /tmp/release-catalog-lock
for _ in $(seq 1 30); do
  if docker logs "${lock_name}" 2>&1 | grep --quiet catalog-lock-released; then
    break
  fi
  sleep 1
done
if ! docker logs "${lock_name}" 2>&1 | grep --quiet catalog-lock-released; then
  echo "Catalog lock holder did not release its dedicated connection." >&2
  exit 1
fi

set +e
released_probe_output="$(
  docker run --rm \
    --name "${released_probe_name}" \
    --network "${network_name}" \
    --env "DATABASE_URL=postgresql://postgres:${database_password}@${source_name}:5432/medical_box" \
    medical-box-backup:e2e \
    uv run --no-sync python -c \
    'import os; from medical_box_api.backup.service import backup_advisory_lock; lock=backup_advisory_lock(os.environ["DATABASE_URL"]); lock.__enter__()' \
    2>&1
)"
released_probe_status=$?
set -e
if [[ "${released_probe_status}" -ne 0 ]]; then
  echo "Catalog mutation lock remained active after its context exited." >&2
  echo "${released_probe_output}" >&2
  exit 1
fi

docker exec "${lock_name}" touch /tmp/finish-catalog-lock
lock_exit_status="$(docker wait "${lock_name}")"
if [[ "${lock_exit_status}" != "0" ]]; then
  docker logs "${lock_name}" >&2
  echo "Catalog lock holder exited with status ${lock_exit_status}." >&2
  exit 1
fi
docker rm "${lock_name}" >/dev/null

key_directory="${work_directory}/key-material"
"${backend_root}/scripts/prepare_backup_key_material.sh" "${key_directory}"
fingerprint="$(<"${key_directory}/backup-recipient-fingerprint.txt")"
public_key_base64="$(
  base64 <"${key_directory}/backup-public.gpg" | tr -d '\n'
)"
private_key_base64="$(
  base64 <"${key_directory}/backup-private.gpg" | tr -d '\n'
)"
private_key_passphrase="$(<"${key_directory}/backup-passphrase.txt")"
manifest_hmac_key_base64="$(
  base64 <"${key_directory}/backup-manifest-hmac.key" | tr -d '\n'
)"
mkdir -m 700 "${work_directory}/store"

docker run --rm \
  --name "${create_name}" \
  --user "$(id -u):$(id -g)" \
  --network "${network_name}" \
  --volume "${work_directory}/store:/backups" \
  --env HOME=/tmp \
  --env UV_CACHE_DIR=/tmp/uv-cache \
  --env APP_ENV=test \
  --env APP_ROLE=backup \
  --env "DATABASE_URL=postgresql+psycopg://postgres:${database_password}@${source_name}:5432/medical_box" \
  --env BACKUP_STORE=local \
  --env BACKUP_LOCAL_DIRECTORY=/backups \
  --env BACKUP_PREFIX=medical-box/e2e \
  --env "BACKUP_GPG_PUBLIC_KEY_BASE64=${public_key_base64}" \
  --env "BACKUP_GPG_RECIPIENT=${fingerprint}" \
  --env "BACKUP_MANIFEST_HMAC_KEY_BASE64=${manifest_hmac_key_base64}" \
  medical-box-backup:e2e \
  uv run --no-sync medical-box-backup create

docker run --detach \
  --name "${restore_name}" \
  --network "${network_name}" \
  --env "POSTGRES_PASSWORD=${database_password}" \
  --env POSTGRES_DB=medical_box \
  postgres:18-alpine >/dev/null
wait_for_postgres "${restore_name}"

docker run --rm \
  --name "${verify_name}" \
  --user "$(id -u):$(id -g)" \
  --network "${network_name}" \
  --volume "${work_directory}/store:/backups:ro" \
  --env HOME=/tmp \
  --env UV_CACHE_DIR=/tmp/uv-cache \
  --env APP_ENV=test \
  --env APP_ROLE=backup_verify \
  --env "DATABASE_URL=postgresql+psycopg://postgres:${database_password}@${source_name}:5432/medical_box" \
  --env BACKUP_STORE=local \
  --env BACKUP_LOCAL_DIRECTORY=/backups \
  --env BACKUP_PREFIX=medical-box/e2e \
  --env "BACKUP_GPG_PRIVATE_KEY_BASE64=${private_key_base64}" \
  --env "BACKUP_GPG_PASSPHRASE=${private_key_passphrase}" \
  --env "BACKUP_MANIFEST_HMAC_KEY_BASE64=${manifest_hmac_key_base64}" \
  --env "BACKUP_RESTORE_DATABASE_URL=postgresql+psycopg://postgres:${database_password}@${restore_name}:5432/medical_box" \
  --env BACKUP_RESTORE_CONFIRMATION=restore-disposable-database \
  medical-box-backup:e2e \
  uv run --no-sync medical-box-backup verify --restore

restored_product_count="$(
  docker exec "${restore_name}" \
    psql --username postgres --dbname medical_box --tuples-only --no-align \
    --command "SELECT count(*) FROM drug_products WHERE item_seq = 'E2E-0001';"
)"
if [[ "${restored_product_count}" != "1" ]]; then
  echo "Restored product count is ${restored_product_count}, expected 1." >&2
  exit 1
fi

if ! cleanup_resources; then
  echo "Backup roundtrip succeeded, but deterministic cleanup verification failed." >&2
  exit 1
fi
cleanup_pending=false
trap - EXIT

printf '{"status":"succeeded","restored_product_count":%s,"repository":"%s","cleanup_verified":true}\n' \
  "${restored_product_count}" \
  "${repository_root}"
printf 'cleanup_verified=true\n'
