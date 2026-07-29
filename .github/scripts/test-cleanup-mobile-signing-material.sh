#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cleanup_script="${script_dir}/cleanup-mobile-signing-material.sh"
temporary_root="$(mktemp -d)"

cleanup() {
  command rm -rf -- "${temporary_root}"
}
trap cleanup EXIT

test_home="${temporary_root}/home"
test_runner_temp="${temporary_root}/runner-temp"
test_workspace="${temporary_root}/workspace"
mkdir -p \
  "${test_home}/Library/MobileDevice/Provisioning Profiles" \
  "${test_runner_temp}" \
  "${test_runner_temp}/app-store-connect/private_keys" \
  "${test_workspace}/build/ios" \
  "${test_workspace}/ios/Flutter"

profile_uuid="AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
printf '%s' "${profile_uuid}" >"${test_runner_temp}/profile-uuid"
touch \
  "${test_home}/Library/MobileDevice/Provisioning Profiles/${profile_uuid}.mobileprovision" \
  "${test_runner_temp}/distribution.p12" \
  "${test_runner_temp}/profile.mobileprovision" \
  "${test_runner_temp}/ExportOptions.plist" \
  "${test_runner_temp}/app-store-connect/private_keys/AuthKey_TESTKEY123.p8" \
  "${test_runner_temp}/medical-box.keychain-db" \
  "${test_workspace}/build/ios/signed.ipa" \
  "${test_workspace}/ios/Flutter/ReleaseSecrets.xcconfig"

(
  cd "${test_workspace}"
  export HOME="${test_home}"
  export RUNNER_TEMP="${test_runner_temp}"
  source "${cleanup_script}"

  removal_log="${temporary_root}/removal.log"
  rm() {
    local arguments=("$@")
    local target="${arguments[${#arguments[@]} - 1]}"
    printf '%s\n' "${target}" >>"${removal_log}"
    if [[ "${target}" == "${test_runner_temp}/distribution.p12" ]]; then
      return 1
    fi
    command rm "$@"
  }
  security() {
    if [[ "$1" != "delete-keychain" ]]; then
      return 64
    fi
    command rm -f -- "$2"
  }

  cleanup_error_log="${temporary_root}/cleanup-error.log"
  if cleanup_ios_signing_material 2>"${cleanup_error_log}"; then
    echo "Cleanup unexpectedly succeeded after an injected deletion failure." >&2
    exit 1
  fi
  grep --fixed-strings --quiet \
    "Could not remove release material: ${test_runner_temp}/distribution.p12" \
    "${cleanup_error_log}"
  grep --fixed-strings --quiet \
    "Release material remains after cleanup: ${test_runner_temp}/distribution.p12" \
    "${cleanup_error_log}"

  expected_attempts=(
    "build/ios"
    "${test_home}/Library/MobileDevice/Provisioning Profiles/${profile_uuid}.mobileprovision"
    "${test_runner_temp}/distribution.p12"
    "${test_runner_temp}/profile.mobileprovision"
    "${test_runner_temp}/ExportOptions.plist"
    "${test_runner_temp}/app-store-connect"
    "${test_runner_temp}/profile-uuid"
    "ios/Flutter/ReleaseSecrets.xcconfig"
  )
  for target in "${expected_attempts[@]}"; do
    if ! grep --fixed-strings --line-regexp --quiet "${target}" "${removal_log}"; then
      printf 'Cleanup did not attempt target after failure: %s\n' "${target}" >&2
      exit 1
    fi
  done

  test -e "${test_runner_temp}/distribution.p12"
  test ! -e "build/ios"
  test ! -e "${test_runner_temp}/profile.mobileprovision"
  test ! -e "${test_runner_temp}/ExportOptions.plist"
  test ! -e "${test_runner_temp}/app-store-connect"
  test ! -e "${test_runner_temp}/profile-uuid"
  test ! -e "${test_runner_temp}/medical-box.keychain-db"
  test ! -e "ios/Flutter/ReleaseSecrets.xcconfig"
  test ! -e \
    "${test_home}/Library/MobileDevice/Provisioning Profiles/${profile_uuid}.mobileprovision"
)
