#!/usr/bin/env bash

# Remove runner-local signed outputs and signing material without allowing one
# failed deletion to prevent the remaining cleanup attempts.
set -u -o pipefail

cleanup_failed=0

record_cleanup_failure() {
  local target="$1"
  printf 'Could not remove release material: %s\n' "${target}" >&2
  cleanup_failed=1
}

remove_release_file() {
  local target="$1"
  if ! rm -f -- "${target}"; then
    record_cleanup_failure "${target}"
  fi
}

remove_release_directory() {
  local target="$1"
  if ! rm -rf -- "${target}"; then
    record_cleanup_failure "${target}"
  fi
}

verify_release_target_absent() {
  local target="$1"
  if [[ -e "${target}" ]]; then
    printf 'Release material remains after cleanup: %s\n' "${target}" >&2
    cleanup_failed=1
  fi
}

cleanup_android_signing_material() {
  cleanup_failed=0
  local targets=(
    "build/app"
    "android/key.properties"
    "android/upload-keystore.jks"
  )

  remove_release_directory "${targets[0]}"
  remove_release_file "${targets[1]}"
  remove_release_file "${targets[2]}"

  local target
  for target in "${targets[@]}"; do
    verify_release_target_absent "${target}"
  done

  ((cleanup_failed == 0))
}

cleanup_ios_signing_material() {
  cleanup_failed=0
  local runner_temp="${RUNNER_TEMP:?RUNNER_TEMP is required for iOS cleanup}"
  local keychain="${runner_temp}/medical-box.keychain-db"
  local profile_uuid_file="${runner_temp}/profile-uuid"
  local installed_profile=""
  local targets=(
    "build/ios"
    "${runner_temp}/distribution.p12"
    "${runner_temp}/profile.mobileprovision"
    "${runner_temp}/ExportOptions.plist"
    "${runner_temp}/app-store-connect"
    "${profile_uuid_file}"
    "ios/Flutter/ReleaseSecrets.xcconfig"
  )

  if [[ -f "${profile_uuid_file}" ]]; then
    local profile_uuid
    if profile_uuid="$(<"${profile_uuid_file}")" &&
      [[ "${profile_uuid}" =~ ^[A-Fa-f0-9-]{36}$ ]]; then
      installed_profile="${HOME}/Library/MobileDevice/Provisioning Profiles/${profile_uuid}.mobileprovision"
    else
      record_cleanup_failure "${profile_uuid_file}"
    fi
  fi

  remove_release_directory "${targets[0]}"
  if [[ -n "${installed_profile}" ]]; then
    remove_release_file "${installed_profile}"
  fi
  remove_release_file "${targets[1]}"
  remove_release_file "${targets[2]}"
  remove_release_file "${targets[3]}"
  remove_release_directory "${targets[4]}"
  remove_release_file "${targets[5]}"
  remove_release_file "${targets[6]}"

  if [[ -e "${keychain}" ]] && ! security delete-keychain "${keychain}"; then
    printf 'security delete-keychain failed; removing the keychain file directly.\n' >&2
    remove_release_file "${keychain}"
  fi

  local target
  for target in "${targets[@]}"; do
    verify_release_target_absent "${target}"
  done
  if [[ -n "${installed_profile}" ]]; then
    verify_release_target_absent "${installed_profile}"
  fi
  verify_release_target_absent "${keychain}"

  ((cleanup_failed == 0))
}

main() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: cleanup-mobile-signing-material.sh <android|ios>" >&2
    return 64
  fi

  case "$1" in
    android)
      cleanup_android_signing_material
      ;;
    ios)
      cleanup_ios_signing_material
      ;;
    *)
      echo "Unsupported mobile release platform: $1" >&2
      return 64
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
