#!/usr/bin/env bash

set -euo pipefail

backend_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_root="$(cd "${backend_root}/../.." && pwd)"
run_id="${RANDOM}-$$"
network_name="medical-box-backup-e2e-${run_id}"
source_name="medical-box-backup-source-${run_id}"
restore_name="medical-box-backup-restore-${run_id}"
lock_name="medical-box-backup-lock-${run_id}"
work_directory="$(mktemp -d)"
database_password="backup-e2e-only"

cleanup() {
  docker rm --force "${source_name}" "${restore_name}" "${lock_name}" >/dev/null 2>&1 || true
  docker network rm "${network_name}" >/dev/null 2>&1 || true
  rm -rf "${work_directory}"
}
trap cleanup EXIT

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
  --env "DATABASE_URL=postgresql://postgres:${database_password}@${source_name}:5432/medical_box" \
  medical-box-backup:e2e \
  uv run --no-sync python -c \
  'import os,time; import psycopg; from medical_box_api.catalog.locking import CATALOG_MUTATION_LOCK_KEY; connection=psycopg.connect(os.environ["DATABASE_URL"], autocommit=True); connection.execute("SELECT pg_advisory_lock(%s)", (CATALOG_MUTATION_LOCK_KEY,)); print("catalog-lock-acquired", flush=True); time.sleep(30)' \
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
docker rm --force "${lock_name}" >/dev/null

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
  --user "$(id -u):$(id -g)" \
  --network "${network_name}" \
  --volume "${work_directory}/store:/backups" \
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
  --user "$(id -u):$(id -g)" \
  --network "${network_name}" \
  --volume "${work_directory}/store:/backups:ro" \
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

printf '{"status":"succeeded","restored_product_count":%s,"repository":"%s"}\n' \
  "${restored_product_count}" \
  "${repository_root}"
