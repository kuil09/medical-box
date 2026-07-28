#!/usr/bin/env bash
set -euo pipefail

manifest="${1:-}"
if [[ -z "${manifest}" ]]; then
  manifest="$(
    find build/app/intermediates/merged_manifests/debug \
      -name AndroidManifest.xml \
      -type f \
      -print \
      -quit
  )"
fi

if [[ -z "${manifest}" || ! -f "${manifest}" ]]; then
  echo "Merged Android manifest was not found." >&2
  exit 1
fi

required_entries=(
  "android.permission.RECEIVE_BOOT_COMPLETED"
  "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
  "com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
  "android.intent.action.BOOT_COMPLETED"
  "android.intent.action.MY_PACKAGE_REPLACED"
)

for entry in "${required_entries[@]}"; do
  if ! grep --fixed-strings --quiet "${entry}" "${manifest}"; then
    echo "Merged Android manifest is missing: ${entry}" >&2
    exit 1
  fi
done

echo "Merged Android notification manifest configuration is valid."
