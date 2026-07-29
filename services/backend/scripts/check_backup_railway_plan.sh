#!/usr/bin/env bash

# Verify that the no-cost Railway graph remains free of backup resources and
# scheduled catalog execution. This script never applies the plan.
set -euo pipefail

expected_project="medical-box"
expected_environment="production"
expected_catalog_start="/bin/sh -c 'echo \"Catalog sync temporarily paused while normalization safety is repaired\"'"

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

# Only release-configuration variables may change. Resource creation, deletion,
# and every unrelated update are rejected even if Railway labels them safe.
if ! jq -e '
  def allowed_changes: [
    {
      kind: "variable.set",
      summary: "Update variable medical-box.CATALOG_MIN_FREE_BYTES",
      details: [
        "medical-box.CATALOG_MIN_FREE_BYTES (preserve() → «hidden»)"
      ]
    },
    {
      kind: "variable.set",
      summary: "Set variable medical-box.TERMS_VERSION",
      details: [
        "medical-box.TERMS_VERSION (unset → «hidden»)"
      ]
    },
    {
      kind: "variable.set",
      summary: "Set variable medical-box.TERMS_VERSION",
      details: [
        "medical-box.TERMS_VERSION (preserve() → «hidden»)"
      ]
    },
    {
      kind: "variable.set",
      summary: "Update variable catalog-sync.CATALOG_MIN_FREE_BYTES",
      details: [
        "catalog-sync.CATALOG_MIN_FREE_BYTES (preserve() → «hidden»)"
      ]
    },
    {
      kind: "resource.update",
      summary: "Update catalog-sync build.watchPatterns"
    },
    {
      kind: "resource.update",
      summary: "Update catalog-sync deploy.cronSchedule"
    }
  ];
  (.changeSet.changes | type == "array")
  and (
    .changeSet.changes
    | all(
        . as $change
        | ($change.severity | type == "string" and ascii_downcase != "destructive")
        and any(
          allowed_changes[];
          .kind == $change.kind
          and .summary == $change.summary
          and (
            .kind != "variable.set"
            or .details == $change.details
          )
        )
        and (
          $change.kind != "resource.update"
          or (
            $change.summary == "Update catalog-sync build.watchPatterns"
            and $change.details == [
              "build.watchPatterns ([\"services/backend/**\",\".railway/railway.ts\"] → [\".railway/catalog-sync-activation\"])"
            ]
          )
          or (
            $change.summary == "Update catalog-sync deploy.cronSchedule"
            and $change.details == [
              "deploy.cronSchedule (\"10 18 * * *\" → unset)"
            ]
          )
        )
      )
  )
  and (
    .changeSet.changes
    | map(.summary)
    | length == (unique | length)
  )
' "${plan_file}" >/dev/null; then
  echo "Railway plan contains a disallowed, delete, or destructive change." >&2
  exit 1
fi

# The catalog remains deliberately paused without a cron. Billable backup
# resources stay outside the active desired graph until separately approved.
if ! jq -e \
  --arg catalog_start "${expected_catalog_start}" \
  '
    (.desiredGraph.project.name == "medical-box")
    and (
      [.desiredGraph.resources[].address] | sort
    ) == [
      "database.Postgres",
      "group.Backend",
      "service.catalog-sync",
      "service.medical-box"
    ]
    and (
      [.desiredGraph.resources[] | select(.address == "service.medical-box")]
      | length == 1
      and .[0].variables.CATALOG_MIN_FREE_BYTES
        == {type: "literal", value: "1200000000"}
      and .[0].variables.TERMS_VERSION
        == {type: "literal", value: "2026-07-29"}
    )
    and (
      [.desiredGraph.resources[] | select(.address == "service.catalog-sync")]
      | length == 1
      and .[0].name == "catalog-sync"
      and .[0].deploy.startCommand == $catalog_start
      and ((.[0].deploy.cronSchedule // null) == null)
      and .[0].variables.CATALOG_MIN_FREE_BYTES
        == {type: "literal", value: "1200000000"}
    )
    and (
      [
        .desiredGraph.resources[]
        | select(
            .name == "production-backup"
            or .name == "production-backups"
            or .name == "Operations"
          )
      ]
      | length == 0
    )
  ' "${plan_file}" >/dev/null; then
  echo "The desired graph schedules catalog work or creates backup resources." >&2
  exit 1
fi

printf 'no_cost_railway_plan_guard=passed\n'
