#!/usr/bin/env bash

set -euo pipefail

required_variables=(
  APP_ENV
  APP_ROLE
  DATABASE_URL
  BACKUP_STORE
  BACKUP_PREFIX
  BACKUP_DAILY_RETENTION
  BACKUP_WEEKLY_RETENTION
  BACKUP_MONTHLY_RETENTION
  AWS_ENDPOINT_URL
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
  AWS_S3_BUCKET_NAME
  AWS_DEFAULT_REGION
  AWS_S3_ADDRESSING_STYLE
  BACKUP_GPG_PUBLIC_KEY_BASE64
  BACKUP_GPG_RECIPIENT
  BACKUP_MANIFEST_HMAC_KEY_BASE64
)
for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "Required backup variable is missing: ${variable_name}" >&2
    exit 1
  fi
done
if [[ "${APP_ENV}" != "production" ]] || [[ "${APP_ROLE}" != "backup" ]]; then
  echo "This command requires the production backup service environment." >&2
  exit 1
fi

backend_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
docker build \
  --file "${backend_root}/Dockerfile.backup" \
  --tag medical-box-backup:production \
  "${backend_root}"

docker_arguments=(--rm)
for variable_name in "${required_variables[@]}"; do
  docker_arguments+=(--env "${variable_name}")
done

docker run \
  "${docker_arguments[@]}" \
  medical-box-backup:production \
  uv run --no-sync medical-box-backup create
