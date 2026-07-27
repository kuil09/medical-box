#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
classifier="${script_dir}/classify-ci-changes.sh"

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
  $'infrastructure=true\nbackend=false\nprototype=false\nmobile=false' \
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
