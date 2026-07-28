#!/usr/bin/env bash

set -euo pipefail

# Railway applies variable changes one request at a time. A network interruption
# can therefore leave a partial, still-dormant configuration. Every value below
# is deterministic and uses --skip-deploys, so rerunning this script is safe.

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 /absolute/path/to/backup-key-directory" >&2
  exit 2
fi

for executable in railway jq base64 tr wc cmp mktemp chmod rm rmdir; do
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

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repository_root="$(cd "${script_directory}/../../.." && pwd -P)"
key_directory="$(cd "${key_directory}" && pwd -P)"
case "${key_directory}/" in
  "${repository_root}/"*)
    echo "The key directory must be outside the repository." >&2
    exit 2
    ;;
esac

public_key_file="${key_directory}/backup-public.gpg"
hmac_key_file="${key_directory}/backup-manifest-hmac.key"
fingerprint_file="${key_directory}/backup-recipient-fingerprint.txt"

is_literal_null() {
  local source_file="$1"

  LC_ALL=C tr -d '[:space:]' <"${source_file}" |
    LC_ALL=C tr '[:upper:]' '[:lower:]' |
    cmp -s - <(printf 'null')
}

for required_file in "${public_key_file}" "${hmac_key_file}" "${fingerprint_file}"; do
  if [[ ! -f "${required_file}" ]] || [[ ! -s "${required_file}" ]]; then
    echo "Required public backup material is missing or empty: ${required_file}" >&2
    exit 1
  fi
  if is_literal_null "${required_file}"; then
    echo "Required public backup material cannot be null: ${required_file}" >&2
    exit 1
  fi
done

if [[ "$(wc -c <"${hmac_key_file}" | tr -d '[:space:]')" != "32" ]]; then
  echo "The backup manifest HMAC key must contain exactly 32 bytes." >&2
  exit 1
fi

recipient_fingerprint="$(tr -d '[:space:]' <"${fingerprint_file}")"
if [[ ! "${recipient_fingerprint}" =~ ^[[:xdigit:]]{40}$ ]]; then
  echo "The backup recipient fingerprint must be exactly 40 hexadecimal characters." >&2
  exit 1
fi
recipient_fingerprint="$(printf '%s' "${recipient_fingerprint}" | tr '[:lower:]' '[:upper:]')"

export RAILWAY_CALLER="${RAILWAY_CALLER:-skill:use-railway@1.3.6}"
export RAILWAY_AGENT_SESSION="${RAILWAY_AGENT_SESSION:-medical-box-backup-activation}"
readonly environment_name="production"
readonly service_name="production-backup"
readonly bucket_name="production-backups"

temporary_directory="$(mktemp -d)"
chmod 700 "${temporary_directory}"
status_file="${temporary_directory}/railway-status.json"
credentials_file="${temporary_directory}/bucket-credentials.json"
: >"${status_file}"
: >"${credentials_file}"
chmod 600 "${status_file}" "${credentials_file}"

cleanup() {
  local cleanup_failed=0

  rm -f "${temporary_directory}"/* || cleanup_failed=1
  rmdir "${temporary_directory}" || cleanup_failed=1
  if [[ "${cleanup_failed}" -ne 0 ]]; then
    echo "Temporary backup-secret material cleanup failed." >&2
    return 1
  fi
}

on_exit() {
  local exit_status="$?"

  trap - EXIT
  if ! cleanup; then
    exit 1
  fi
  exit "${exit_status}"
}
trap on_exit EXIT

# Complete all key, Railway identity, and credential validation before the first
# Railway variable mutation below.
railway status --json >"${status_file}"
if ! jq -e '
  .name == "medical-box" and
  ([.environments.edges[].node.name] == ["production"]) and
  ([.services.edges[] | select(.node.name == "production-backup")] | length == 1) and
  ([.buckets.edges[] | select(.node.name == "production-backups")] | length == 1)
' "${status_file}" >/dev/null; then
  echo "Railway must be linked to exactly medical-box production with the production backup service and bucket." >&2
  exit 1
fi

railway bucket credentials \
  --bucket "${bucket_name}" \
  --environment "${environment_name}" \
  --json >"${credentials_file}"

credential_value() {
  local field_name="$1"

  jq -er --arg field_name "${field_name}" '
    .[$field_name] |
    if type == "string" then
      gsub("^[[:space:]]+|[[:space:]]+$"; "") as $value |
      if ($value | length) > 0 and ($value | ascii_downcase) != "null" then
        $value
      else
        error("missing credential")
      end
    else
      error("missing credential")
    end
  ' "${credentials_file}"
}

aws_endpoint_url="$(credential_value endpoint)"
aws_access_key_id="$(credential_value accessKeyId)"
aws_secret_access_key="$(credential_value secretAccessKey)"
aws_s3_bucket_name="$(credential_value bucketName)"
aws_default_region="$(credential_value region)"
aws_s3_addressing_style="$(credential_value urlStyle)"
case "${aws_s3_addressing_style}" in
  auto|path|virtual) ;;
  *)
    echo "The bucket URL style must be one of: auto, path, virtual." >&2
    exit 1
    ;;
esac

write_value_file() {
  local variable_name="$1"
  local value="$2"
  local value_file="${temporary_directory}/${variable_name}"

  printf '%s' "${value}" >"${value_file}"
  chmod 600 "${value_file}"
}

write_value_file AWS_ENDPOINT_URL "${aws_endpoint_url}"
write_value_file AWS_ACCESS_KEY_ID "${aws_access_key_id}"
write_value_file AWS_SECRET_ACCESS_KEY "${aws_secret_access_key}"
write_value_file AWS_S3_BUCKET_NAME "${aws_s3_bucket_name}"
write_value_file AWS_DEFAULT_REGION "${aws_default_region}"
write_value_file AWS_S3_ADDRESSING_STYLE "${aws_s3_addressing_style}"
write_value_file BACKUP_GPG_RECIPIENT "${recipient_fingerprint}"
base64 <"${public_key_file}" | tr -d '\n' >"${temporary_directory}/BACKUP_GPG_PUBLIC_KEY_BASE64"
base64 <"${hmac_key_file}" | tr -d '\n' >"${temporary_directory}/BACKUP_MANIFEST_HMAC_KEY_BASE64"
chmod 600 \
  "${temporary_directory}/BACKUP_GPG_PUBLIC_KEY_BASE64" \
  "${temporary_directory}/BACKUP_MANIFEST_HMAC_KEY_BASE64"

set_value_file() {
  local variable_name="$1"

  railway variable set \
    --service "${service_name}" \
    --environment "${environment_name}" \
    --skip-deploys \
    --stdin \
    "${variable_name}" <"${temporary_directory}/${variable_name}" >/dev/null
}

for variable_name in \
  AWS_ENDPOINT_URL \
  AWS_ACCESS_KEY_ID \
  AWS_SECRET_ACCESS_KEY \
  AWS_S3_BUCKET_NAME \
  AWS_DEFAULT_REGION \
  AWS_S3_ADDRESSING_STYLE \
  BACKUP_GPG_PUBLIC_KEY_BASE64 \
  BACKUP_GPG_RECIPIENT \
  BACKUP_MANIFEST_HMAC_KEY_BASE64; do
  set_value_file "${variable_name}"
done

echo "Production backup worker secrets were wired without triggering a deployment."
echo "The private decryption key was not read or sent to Railway."
echo "A failed request may require an idempotent rerun; --skip-deploys keeps the worker dormant."
