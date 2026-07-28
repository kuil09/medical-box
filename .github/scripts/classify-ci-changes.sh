#!/usr/bin/env bash

set -euo pipefail

infrastructure=false
backend=false
prototype=false
mobile=false

enable_all() {
  infrastructure=true
  backend=true
  prototype=true
  mobile=true
}

while IFS= read -r path; do
  [[ -z "${path}" ]] && continue

  case "${path}" in
    .github/workflows/ci.yml | .github/scripts/*)
      enable_all
      ;;
    .github/workflows/mobile-release-build.yml)
      mobile=true
      backend=true
      ;;
    .github/workflows/production-monitor.yml | \
      .github/workflows/production-backup-restore.yml)
      backend=true
      ;;
    .github/workflows/*)
      enable_all
      ;;
    .railway/* | package.json | package-lock.json)
      infrastructure=true
      backend=true
      ;;
    services/backend/*)
      backend=true
      ;;
    design/prototype/*)
      prototype=true
      ;;
    apps/mobile/* | .fvmrc)
      mobile=true
      ;;
    docs/* | design/audit/* | README.md)
      ;;
    *)
      enable_all
      ;;
  esac
done

printf 'infrastructure=%s\n' "${infrastructure}"
printf 'backend=%s\n' "${backend}"
printf 'prototype=%s\n' "${prototype}"
printf 'mobile=%s\n' "${mobile}"
