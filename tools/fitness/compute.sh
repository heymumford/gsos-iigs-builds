#!/usr/bin/env bash
# tools/fitness/compute.sh — Compute compound fitness score per phase.
#
# Reads data/fitness-history.ndjson (append-only time-series log).
# Takes the most recent atomic value per (phase, metric).
# Computes weighted average of normalized values per phase.
# Writes data/fitness-snapshot.json (committed snapshot).
#
# Exit codes:
#   0: snapshot written successfully
#   1: jq missing or required dependency unavailable
#   2: no fitness log to read

set -u

_FITNESS_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
FITNESS_LOG="${FITNESS_LOG:-${_FITNESS_REPO_ROOT}/data/fitness-history.ndjson}"
SNAPSHOT="${SNAPSHOT:-${_FITNESS_REPO_ROOT}/data/fitness-snapshot.json}"

if ! command -v jq &>/dev/null; then
  echo "[fitness/compute] jq is required (brew install jq)" >&2
  exit 1
fi

if [[ ! -f "$FITNESS_LOG" ]]; then
  echo "[fitness/compute] no log at $FITNESS_LOG; nothing to compute" >&2
  exit 2
fi

if [[ ! -s "$FITNESS_LOG" ]]; then
  echo "[fitness/compute] log is empty" >&2
  exit 2
fi

# Group by phase; for each phase, take latest atomic per metric, compute compound
# as weighted average of normalized values.
jq -s '
  group_by(.phase)
  | map(
      . as $entries
      | {
          phase: $entries[0].phase,
          generated: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
          atomics: ($entries | group_by(.metric) | map(max_by(.ts))),
          compound: (
            ($entries | group_by(.metric) | map(max_by(.ts)))
            | (if (map(.weight) | add) == 0 then 0 else
                ((map(.normalized * .weight) | add) / (map(.weight) | add))
              end)
          )
        }
    )
  | { schema_version: "1.0", generated: (now | strftime("%Y-%m-%dT%H:%M:%SZ")), phases: . }
' "$FITNESS_LOG" > "$SNAPSHOT"

echo "[fitness/compute] snapshot: $SNAPSHOT" >&2
jq '.phases | map({phase, compound: (.compound * 1000 | round / 1000), atomic_count: (.atomics | length)})' "$SNAPSHOT"
