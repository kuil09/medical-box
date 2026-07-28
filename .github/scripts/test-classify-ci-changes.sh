#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
classifier="${script_dir}/classify-ci-changes.sh"
repository_root="$(cd "${script_dir}/../.." && pwd)"

assert_classification() {
  local name="$1"
  local expected="$2"
  shift 2

  local actual
  actual="$(printf '%s\n' "$@" | "${classifier}")"

  if [[ "${actual}" != "${expected}" ]]; then
    printf 'Classification failed for %s.\n' "${name}" >&2
    printf 'Expected:\n%s\n' "${expected}" >&2
    printf 'Actual:\n%s\n' "${actual}" >&2
    return 1
  fi
}

assert_classification \
  "documentation only" \
  $'infrastructure=false\nbackend=false\nprototype=false\nmobile=false' \
  "README.md" \
  "docs/release-checklist.md" \
  "design/audit/prototype.png"

assert_classification \
  "Railway only" \
  $'infrastructure=true\nbackend=true\nprototype=false\nmobile=false' \
  ".railway/railway.ts"

assert_classification \
  "mobile only" \
  $'infrastructure=false\nbackend=false\nprototype=false\nmobile=true' \
  "apps/mobile/lib/main.dart"

assert_classification \
  "unknown path fails safe" \
  $'infrastructure=true\nbackend=true\nprototype=true\nmobile=true' \
  "Makefile"

assert_classification \
  "CI configuration fails safe" \
  $'infrastructure=true\nbackend=true\nprototype=true\nmobile=true' \
  ".github/workflows/ci.yml"

assert_classification \
  "production monitor uses backend checks only" \
  $'infrastructure=false\nbackend=true\nprototype=false\nmobile=false' \
  ".github/workflows/production-monitor.yml"

assert_classification \
  "mobile release uses mobile and policy checks" \
  $'infrastructure=false\nbackend=true\nprototype=false\nmobile=true' \
  ".github/workflows/mobile-release-build.yml"

if ! grep --fixed-strings --quiet \
  'git diff --no-renames --name-only "${BASE_SHA}" "${HEAD_SHA}" |' \
  "${repository_root}/.github/workflows/ci.yml"; then
  echo "CI must split cross-boundary renames into the old and new paths." >&2
  exit 1
fi

temporary_repository="$(mktemp -d)"
cleanup() {
  rm -rf -- "${temporary_repository}"
}
trap cleanup EXIT

git -C "${temporary_repository}" init --quiet
git -C "${temporary_repository}" config user.name "Medical Box CI"
git -C "${temporary_repository}" config user.email "ci@medicalbox.invalid"
mkdir -p "${temporary_repository}/apps/mobile/lib"
printf 'void main() {}\n' \
  >"${temporary_repository}/apps/mobile/lib/renamed.dart"
git -C "${temporary_repository}" add apps/mobile/lib/renamed.dart
git -C "${temporary_repository}" commit --quiet --message "Add mobile source"
base_sha="$(git -C "${temporary_repository}" rev-parse HEAD)"

mkdir -p "${temporary_repository}/docs"
git -C "${temporary_repository}" mv \
  apps/mobile/lib/renamed.dart \
  docs/renamed.dart
git -C "${temporary_repository}" commit --quiet --message "Move source to docs"
head_sha="$(git -C "${temporary_repository}" rev-parse HEAD)"

rename_detected_paths="$(
  git -C "${temporary_repository}" diff \
    --find-renames \
    --name-only \
    "${base_sha}" \
    "${head_sha}"
)"
if [[ "${rename_detected_paths}" != "docs/renamed.dart" ]]; then
  echo "Rename control did not collapse to the destination path." >&2
  exit 1
fi

split_paths="$(
  git -C "${temporary_repository}" diff \
    --no-renames \
    --name-only \
    "${base_sha}" \
    "${head_sha}"
)"
if [[ "${split_paths}" != $'apps/mobile/lib/renamed.dart\ndocs/renamed.dart' ]]; then
  echo "No-renames diff did not preserve both component boundaries." >&2
  exit 1
fi

split_classification="$(printf '%s\n' "${split_paths}" | "${classifier}")"
if [[ "${split_classification}" != \
  $'infrastructure=false\nbackend=false\nprototype=false\nmobile=true' ]]; then
  echo "Cross-boundary rename did not trigger mobile CI." >&2
  exit 1
fi
