#!/usr/bin/env bash

set -euo pipefail

export LC_ALL=C.UTF-8

repository_root="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.."
  pwd
)"
metadata_root="${repository_root}/store/metadata/ko-KR"

fail() {
  printf 'Store metadata validation failed: %s\n' "$1" >&2
  exit 1
}

read_required() {
  local path="$1"
  [[ -f "${path}" ]] || fail "missing ${path#${repository_root}/}"

  local value
  value="$(<"${path}")"
  [[ -n "${value}" ]] || fail "empty ${path#${repository_root}/}"
  printf '%s' "${value}"
}

assert_max_characters() {
  local relative_path="$1"
  local maximum="$2"
  local value
  value="$(read_required "${metadata_root}/${relative_path}")"

  local length="${#value}"
  if (( length > maximum )); then
    fail "${relative_path} has ${length} characters; maximum is ${maximum}"
  fi
}

assert_https_url() {
  local relative_path="$1"
  local value
  value="$(read_required "${metadata_root}/${relative_path}")"
  [[ "${value}" =~ ^https://[^[:space:]]+$ ]] ||
    fail "${relative_path} must contain one HTTPS URL"
}

assert_contains() {
  local relative_path="$1"
  local expected="$2"
  local value
  value="$(read_required "${metadata_root}/${relative_path}")"
  [[ "${value}" == *"${expected}"* ]] ||
    fail "${relative_path} must contain: ${expected}"
}

assert_absent() {
  local relative_path="$1"
  local forbidden="$2"
  local value
  value="$(read_required "${metadata_root}/${relative_path}")"
  [[ "${value}" != *"${forbidden}"* ]] ||
    fail "${relative_path} must not contain: ${forbidden}"
}

assert_max_characters app_name.txt 30
assert_max_characters subtitle.txt 30
assert_max_characters promotional_text.txt 170
assert_max_characters short_description.txt 80
assert_max_characters full_description.txt 4000
assert_max_characters keywords.txt 100
assert_max_characters release_notes.txt 4000
assert_max_characters review_notes.txt 4000
assert_max_characters copyright.txt 200

assert_https_url privacy_policy_url.txt
assert_https_url support_url.txt
assert_https_url account_deletion_url.txt
assert_https_url marketing_url.txt

assert_contains full_description.txt "회원가입과 로그인이 필요"
assert_contains full_description.txt "진단, 처방, 복용량 결정"
assert_contains review_notes.txt "sign-in are required"
assert_contains review_notes.txt "Account deletion is available"

for relative_path in \
  promotional_text.txt \
  short_description.txt \
  full_description.txt \
  review_notes.txt; do
  assert_absent "${relative_path}" "로그인 없이"
  assert_absent "${relative_path}" "로그인 선택"
  assert_absent "${relative_path}" "optional sign-in"
  assert_absent "${relative_path}" "without an account"
done

printf 'Store metadata is valid.\n'
