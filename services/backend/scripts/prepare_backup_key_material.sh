#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 /absolute/path/outside-the-repository" >&2
  exit 2
fi

for executable in gpg openssl git; do
  if ! command -v "${executable}" >/dev/null 2>&1; then
    echo "Required executable is missing: ${executable}" >&2
    exit 1
  fi
done

repository_root="$(git rev-parse --show-toplevel)"
requested_directory="$1"
if [[ "${requested_directory}" != /* ]]; then
  echo "The key directory must be an absolute path." >&2
  exit 2
fi
if [[ -e "${requested_directory}" ]]; then
  echo "Refusing to overwrite an existing key directory." >&2
  exit 1
fi

parent_directory="$(cd "$(dirname "${requested_directory}")" && pwd -P)"
output_directory="${parent_directory}/$(basename "${requested_directory}")"
case "${output_directory}" in
  "${repository_root}" | "${repository_root}/"*)
    echo "Backup key material must be stored outside the Git repository." >&2
    exit 1
    ;;
esac

umask 077
mkdir "${output_directory}"
cleanup_on_failure=true
gpg_home=""
cleanup() {
  if [[ -n "${gpg_home}" ]]; then
    rm -rf "${gpg_home}"
  fi
  if [[ "${cleanup_on_failure}" == true ]]; then
    rm -rf "${output_directory}"
  fi
}
trap cleanup EXIT

gpg_home="$(mktemp -d /tmp/medical-box-gpg.XXXXXX)"
passphrase_file="${output_directory}/backup-passphrase.txt"
hmac_key_file="${output_directory}/backup-manifest-hmac.key"
fingerprint_file="${output_directory}/backup-recipient-fingerprint.txt"
public_key_file="${output_directory}/backup-public.gpg"
private_key_file="${output_directory}/backup-private.gpg"

chmod 700 "${gpg_home}"
openssl rand -base64 48 >"${passphrase_file}"
openssl rand 32 >"${hmac_key_file}"

gpg --homedir "${gpg_home}" \
  --batch \
  --pinentry-mode loopback \
  --passphrase-file "${passphrase_file}" \
  --quick-gen-key \
  "Medical Box Production Backup <backup@medicalbox.outoftokens.ai>" \
  ed25519 cert 5y

fingerprint="$(
  gpg --homedir "${gpg_home}" --batch --with-colons --list-secret-keys |
    awk -F: '$1 == "fpr" { print $10; exit }'
)"
if [[ ! "${fingerprint}" =~ ^[0-9A-F]{40,64}$ ]]; then
  echo "Could not resolve the dedicated backup key fingerprint." >&2
  exit 1
fi

gpg --homedir "${gpg_home}" \
  --batch \
  --pinentry-mode loopback \
  --passphrase-file "${passphrase_file}" \
  --quick-add-key "${fingerprint}" cv25519 encr 5y
gpg --homedir "${gpg_home}" \
  --batch \
  --output "${public_key_file}" \
  --export "${fingerprint}"
gpg --homedir "${gpg_home}" \
  --batch \
  --pinentry-mode loopback \
  --passphrase-file "${passphrase_file}" \
  --output "${private_key_file}" \
  --export-secret-keys "${fingerprint}"
printf '%s\n' "${fingerprint}" >"${fingerprint_file}"

rm -rf "${gpg_home}"
gpg_home=""
chmod 600 \
  "${passphrase_file}" \
  "${hmac_key_file}" \
  "${fingerprint_file}" \
  "${public_key_file}" \
  "${private_key_file}"

cleanup_on_failure=false
echo "Dedicated backup key material created."
echo "Directory: ${output_directory}"
echo "Recipient fingerprint: ${fingerprint}"
echo "Store this directory in an approved offline recovery location before activation."
