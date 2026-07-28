#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 /absolute/path/to/backup-key-directory" >&2
  exit 2
fi

for executable in railway jq base64 tr gh grep git; do
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
repository_root="$(git rev-parse --show-toplevel)"
key_directory="$(cd "${key_directory}" && pwd -P)"
case "${key_directory}" in
  "${repository_root}" | "${repository_root}/"*)
    echo "Restore key material must remain outside the Git repository." >&2
    exit 1
    ;;
esac

private_key_file="${key_directory}/backup-private.gpg"
passphrase_file="${key_directory}/backup-passphrase.txt"
hmac_key_file="${key_directory}/backup-manifest-hmac.key"

is_null_literal() {
  local source_file="$1"
  LC_ALL=C grep -Eq \
    '^[[:space:]]*[Nn][Uu][Ll][Ll][[:space:]]*$' \
    "${source_file}"
}

for required_file in \
  "${private_key_file}" \
  "${passphrase_file}" \
  "${hmac_key_file}"; do
  if [[ ! -f "${required_file}" ]] || [[ ! -s "${required_file}" ]]; then
    echo "Required restore key material is missing or empty." >&2
    exit 1
  fi
  if is_null_literal "${required_file}"; then
    echo "Required restore key material contains a null value." >&2
    exit 1
  fi
done

if ! LC_ALL=C grep -q '[^[:space:]]' "${passphrase_file}"; then
  echo "The backup passphrase is empty." >&2
  exit 1
fi

export RAILWAY_CALLER="${RAILWAY_CALLER:-skill:use-railway@1.3.6}"
export RAILWAY_AGENT_SESSION="${RAILWAY_AGENT_SESSION:-medical-box-backup-restore-wiring}"
environment_name="production"
bucket_name="production-backups"
github_environment="backup-restore"
github_repository="kuil09/medical-box"

umask 077
temporary_directory="$(
  mktemp -d /tmp/medical-box-backup-restore-secrets.XXXXXX
)"
cleanup() {
  local original_status=$?
  local cleanup_status=0
  trap - EXIT
  for temporary_file in \
    "${temporary_directory}/railway-status.json" \
    "${temporary_directory}/bucket-credentials.json"; do
    if [[ -e "${temporary_file}" ]] &&
      ! rm -f -- "${temporary_file}"; then
      echo "Could not remove temporary backup credential data." >&2
      cleanup_status=1
    fi
  done
  if [[ -d "${temporary_directory}" ]] &&
    ! rmdir -- "${temporary_directory}"; then
    echo "Could not remove the temporary backup credential directory." >&2
    cleanup_status=1
  fi
  if [[ "${original_status}" -ne 0 ]]; then
    exit "${original_status}"
  fi
  exit "${cleanup_status}"
}
trap cleanup EXIT
chmod 700 "${temporary_directory}"
status_file="${temporary_directory}/railway-status.json"
credentials_file="${temporary_directory}/bucket-credentials.json"

railway status --json >"${status_file}"
if [[ "$(jq -r '.name' "${status_file}")" != "medical-box" ]] ||
  ! jq -e \
    --arg environment "${environment_name}" \
    'any(.environments.edges[]; .node.name == $environment)' \
    "${status_file}" >/dev/null; then
  echo "Railway is not linked to medical-box production." >&2
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

credentials_are_complete="$(
  jq -r '
    [
      .endpoint,
      .accessKeyId,
      .secretAccessKey,
      .bucketName,
      .region,
      .urlStyle
    ]
    | all(
        type == "string"
        and (gsub("^[[:space:]]+|[[:space:]]+$"; "") | length > 0)
        and (
          (
            gsub("^[[:space:]]+|[[:space:]]+$"; "")
            | ascii_downcase
          ) != "null"
        )
      )
  ' "${credentials_file}"
)"
if [[ "${credentials_are_complete}" != "true" ]]; then
  echo "Railway returned incomplete bucket credentials." >&2
  exit 1
fi
url_style_is_supported="$(
  jq -r '
    .urlStyle as $url_style
    | ($url_style | type == "string")
    and ($url_style == "auto" or $url_style == "path" or $url_style == "virtual")
  ' "${credentials_file}"
)"
if [[ "${url_style_is_supported}" != "true" ]]; then
  echo "Railway returned an unsupported bucket URL style." >&2
  exit 1
fi

# Complete every read-only preflight before the first GitHub secret mutation.
gh auth status >/dev/null 2>&1
resolved_repository="$(
  gh repo view --json nameWithOwner |
    jq -r '.nameWithOwner'
)"
if [[ "${resolved_repository}" != "${github_repository}" ]]; then
  echo "GitHub is not targeting the expected medical-box repository." >&2
  exit 1
fi

# The restore environment contains production bucket credentials and an offline
# recovery private key. Refuse to create or update even one secret unless the
# environment itself enforces an independently reviewed, main-only deployment.
# These are all read-only calls and deliberately precede the first mutation.
authenticated_login="$(gh api user --jq '.login')"
if [[ -z "${authenticated_login}" ]] ||
  [[ "${authenticated_login}" == "null" ]]; then
  echo "GitHub did not return an authenticated user login." >&2
  exit 1
fi
environment_protection_json="$(
  gh api "repos/${github_repository}/environments/${github_environment}"
)"
branch_policies_json="$(
  gh api \
    "repos/${github_repository}/environments/${github_environment}/deployment-branch-policies?per_page=100"
)"

environment_is_protected="$(
  jq -r \
    --arg authenticated_login "${authenticated_login}" \
    '
      . as $environment
      | (
          ($environment.protection_rules // [])
          | map(select(.type == "required_reviewers"))
          | any(
              . as $review_rule
              | ($review_rule.prevent_self_review == true)
              and (($review_rule.reviewers // []) | length > 0)
              and (
                ($review_rule.reviewers // [])
                | any(
                    .[]?;
                    .type == "Team"
                    or (
                      .type == "User"
                      and (.reviewer.login? // "") != $authenticated_login
                    )
                  )
              )
            )
        )
      and ($environment.deployment_branch_policy.protected_branches == false)
      and ($environment.deployment_branch_policy.custom_branch_policies == true)
    ' <<<"${environment_protection_json}"
)"
if [[ "${environment_is_protected}" != "true" ]]; then
  echo "GitHub backup-restore environment protections are insufficient." >&2
  exit 1
fi

main_is_the_only_deployment_branch="$(
  jq -r '
    (.total_count == 1)
    and ((.branch_policies // []) | length == 1)
    and ((.branch_policies // []) | map(.name) == ["main"])
  ' <<<"${branch_policies_json}"
)"
if [[ "${main_is_the_only_deployment_branch}" != "true" ]]; then
  echo "GitHub backup-restore must allow deployments from only main." >&2
  exit 1
fi

endpoint="$(jq -r '.endpoint' "${credentials_file}")"
access_key_id="$(jq -r '.accessKeyId' "${credentials_file}")"
secret_access_key="$(jq -r '.secretAccessKey' "${credentials_file}")"
bucket_identifier="$(jq -r '.bucketName' "${credentials_file}")"
bucket_region="$(jq -r '.region' "${credentials_file}")"
bucket_url_style="$(jq -r '.urlStyle' "${credentials_file}")"
passphrase="$(<"${passphrase_file}")"

set_github_secret() {
  local secret_name="$1"
  gh secret set "${secret_name}" \
    --env "${github_environment}" \
    --repo "${github_repository}" >/dev/null
}

set_github_variable() {
  local variable_name="$1"
  gh variable set "${variable_name}" \
    --env "${github_environment}" \
    --repo "${github_repository}" >/dev/null
}

printf '%s' "${endpoint}" |
  set_github_secret AWS_ENDPOINT_URL
printf '%s' "${access_key_id}" |
  set_github_secret AWS_ACCESS_KEY_ID
printf '%s' "${secret_access_key}" |
  set_github_secret AWS_SECRET_ACCESS_KEY
printf '%s' "${bucket_identifier}" |
  set_github_secret AWS_S3_BUCKET_NAME
base64 <"${private_key_file}" |
  tr -d '\n' |
  set_github_secret BACKUP_GPG_PRIVATE_KEY_BASE64
printf '%s' "${passphrase}" |
  set_github_secret BACKUP_GPG_PASSPHRASE
base64 <"${hmac_key_file}" |
  tr -d '\n' |
  set_github_secret BACKUP_MANIFEST_HMAC_KEY_BASE64

printf '%s' "${bucket_region}" |
  set_github_variable AWS_DEFAULT_REGION
printf '%s' "${bucket_url_style}" |
  set_github_variable AWS_S3_ADDRESSING_STYLE

echo "Seven protected backup-restore environment secrets and two non-secret variables were configured."
echo "No backup public-key material was sent to GitHub."
