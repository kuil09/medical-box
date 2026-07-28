#!/usr/bin/env bash

# Preview the only Railway changes that may precede the first encrypted
# production backup. This script never applies the plan.
set -euo pipefail

expected_project="medical-box"
expected_environment="production"
expected_catalog_start="/bin/sh -c 'echo \"Catalog sync temporarily paused while normalization safety is repaired\"'"
expected_backup_start="/bin/sh -c 'echo \"Production backup schedule paused pending first verified restore\"'"

for executable in railway jq git mktemp rm rmdir; do
  if ! command -v "${executable}" >/dev/null 2>&1; then
    echo "Required executable is missing: ${executable}" >&2
    exit 1
  fi
done

repository_root="$(git rev-parse --show-toplevel)"
if [[ -z "${repository_root}" ]] || [[ ! -f "${repository_root}/.railway/railway.ts" ]]; then
  echo "Run this script from the medical-box repository." >&2
  exit 1
fi
cd "${repository_root}"

umask 077
temporary_directory="$(mktemp -d /tmp/medical-box-backup-plan.XXXXXX)"
status_file="${temporary_directory}/status.json"
plan_file="${temporary_directory}/plan.json"

cleanup() {
  local original_status=$?
  local cleanup_status=0
  trap - EXIT
  if ! rm -f -- "${status_file}" "${plan_file}"; then
    echo "Could not remove Railway plan temporary files." >&2
    cleanup_status=1
  fi
  if ! rmdir -- "${temporary_directory}"; then
    echo "Could not remove the Railway plan temporary directory." >&2
    cleanup_status=1
  fi
  if [[ "${original_status}" -ne 0 ]]; then
    exit "${original_status}"
  fi
  exit "${cleanup_status}"
}
trap cleanup EXIT

# The explicit status target is independent of the local Railway link. The
# returned IDs are compared with the plan's currentEnvironment below so a
# linked staging project cannot be mistaken for production.
if ! railway status \
  --project "${expected_project}" \
  --environment "${expected_environment}" \
  --json >"${status_file}"; then
  echo "Could not read Railway production status." >&2
  exit 1
fi

if ! jq -e \
  --arg project "${expected_project}" \
  --arg environment "${expected_environment}" \
  '
    .name == $project
    and (.id | type == "string" and length > 0)
    and (.environments.edges | type == "array" and length == 1)
    and (.environments.edges[0].node.name == $environment)
    and (.environments.edges[0].node.id | type == "string" and length > 0)
  ' "${status_file}" >/dev/null; then
  echo "Railway status is not exactly medical-box production." >&2
  exit 1
fi

# Deliberately use only `config plan`: no apply, confirmation, decrypt, or
# show-values option is permitted in this guard.
if ! railway config plan \
  --file "${repository_root}/.railway/railway.ts" \
  --json >"${plan_file}"; then
  echo "Railway configuration plan failed." >&2
  exit 1
fi

if ! jq -e \
  --slurpfile status "${status_file}" \
  --arg project "${expected_project}" \
  --arg environment "${expected_environment}" \
  '
    .ok == true
    and (.diagnostics | type == "array" and length == 0)
    and (.currentEnvironment.projectName == $project)
    and (.currentEnvironment.environmentName == $environment)
    and (.currentEnvironment.projectId == $status[0].id)
    and (.currentEnvironment.environmentId == $status[0].environments.edges[0].node.id)
  ' "${plan_file}" >/dev/null; then
  echo "Railway plan did not target exactly medical-box production or reported diagnostics." >&2
  exit 1
fi

# Only the two capacity-reserve variables and the paused backup resources may
# be introduced. Every other update, including a delete or destructive change,
# is rejected even if Railway labels it safe.
if ! jq -e '
  def allowed_changes: [
    {kind: "variable.set", summary: "Update variable medical-box.CATALOG_MIN_FREE_BYTES"},
    {kind: "variable.set", summary: "Update variable catalog-sync.CATALOG_MIN_FREE_BYTES"},
    {kind: "resource.create", summary: "Create group Operations"},
    {kind: "resource.create", summary: "Create service production-backup"},
    {kind: "resource.create", summary: "Create bucket production-backups"}
  ];
  (.changeSet.changes | type == "array")
  and (.changeSet.changes | length == (allowed_changes | length))
  and (
    .changeSet.changes
    | all(
        . as $change
        | ($change.severity | type == "string" and ascii_downcase != "destructive")
        and ($change.kind | type == "string" and test("delete|destroy"; "i") | not)
        and any(
          allowed_changes[];
          .kind == $change.kind and .summary == $change.summary
        )
      )
  )
  and (
    .changeSet.changes
    | map({kind, summary})
    | sort_by(.kind, .summary)
    == (allowed_changes | sort_by(.kind, .summary))
  )
' "${plan_file}" >/dev/null; then
  echo "Railway plan contains a disallowed, delete, or destructive change." >&2
  exit 1
fi

# The catalog remains deliberately paused and the newly created backup worker
# has no cron until the first backup and disposable restore are verified.
if ! jq -e \
  --arg catalog_start "${expected_catalog_start}" \
  --arg backup_start "${expected_backup_start}" \
  '
    (.desiredGraph.project.name == "medical-box")
    and (
      [.desiredGraph.resources[] | select(.address == "service.catalog-sync")]
      | length == 1
      and .[0].name == "catalog-sync"
      and .[0].deploy.startCommand == $catalog_start
    )
    and (
      [.desiredGraph.resources[] | select(.address == "service.production-backup")]
      | length == 1
      and .[0].name == "production-backup"
      and .[0].deploy.startCommand == $backup_start
      and ((.[0].deploy.cronSchedule // null) == null)
    )
  ' "${plan_file}" >/dev/null; then
  echo "The desired catalog or backup schedule is not safely paused." >&2
  exit 1
fi

printf 'backup_railway_plan_guard=passed\n'
