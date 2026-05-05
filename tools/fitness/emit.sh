#!/usr/bin/env bash
# tools/fitness/emit.sh — Atomic fitness datum emitter.
#
# Source this from a phase script. Each call appends one NDJSON line to
# data/fitness-history.ndjson with raw, normalized [0.000..1.000], baseline,
# and weight. Compound phase scores are computed by tools/fitness/compute.sh
# from the time-series log.
#
# Usage:
#   source "$(dirname "$0")/../tools/fitness/emit.sh"
#   fitness_emit <phase> <metric> <raw> <unit> <weight>
#
# Units supported (see _normalize): bool, semver, exit_code, seconds, bytes, count.
# Baselines and citations live in data/industry-baselines.json (lookup is by metric).

set -u

_FITNESS_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
FITNESS_LOG="${FITNESS_LOG:-${_FITNESS_REPO_ROOT}/data/fitness-history.ndjson}"
BASELINES_FILE="${BASELINES_FILE:-${_FITNESS_REPO_ROOT}/data/industry-baselines.json}"

# _normalize <unit> <raw> <baseline> -> 0.000..1.000 on stdout
_normalize() {
  local unit="$1" raw="$2" baseline="$3"
  case "$unit" in
    bool|exit_code)
      if [[ "$raw" == "$baseline" ]]; then printf '1.000'; else printf '0.000'; fi
      ;;
    semver)
      awk -v r="$raw" -v b="$baseline" 'BEGIN {
        if (b == "null" || b+0 == 0) { printf "1.000"; exit }
        if (r+0 >= b+0) { printf "1.000" } else { printf "%.3f", (r+0)/(b+0) }
      }'
      ;;
    seconds|bytes|count)
      # Lower-is-better: 1.0 at-or-below baseline, baseline/raw above.
      awk -v r="$raw" -v b="$baseline" 'BEGIN {
        if (b == "null" || b+0 == 0) { printf "1.000"; exit }
        if (r+0 <= b+0) { printf "1.000" } else {
          v = (b+0)/(r+0); if (v < 0) v = 0; if (v > 1) v = 1; printf "%.3f", v
        }
      }'
      ;;
    *)
      printf '0.000'
      ;;
  esac
}

# fitness_emit <phase> <metric> <raw> <unit> <weight>
fitness_emit() {
  local phase="$1" metric="$2" raw="$3" unit="$4" weight="$5"
  local ts baseline_value baseline_source normalized

  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  baseline_value="null"
  baseline_source="unknown"
  if [[ -f "$BASELINES_FILE" ]] && command -v jq &>/dev/null; then
    local v s
    v=$(jq -r --arg m "$metric" '.baselines[]? | select(.metric == $m) | .value' "$BASELINES_FILE" 2>/dev/null || true)
    s=$(jq -r --arg m "$metric" '.baselines[]? | select(.metric == $m) | .source' "$BASELINES_FILE" 2>/dev/null || true)
    [[ -n "$v" ]] && baseline_value="$v"
    [[ -n "$s" ]] && baseline_source="$s"
  fi

  normalized="$(_normalize "$unit" "$raw" "$baseline_value")"

  mkdir -p "$(dirname "$FITNESS_LOG")"
  printf '{"ts":"%s","phase":"%s","metric":"%s","raw":%s,"unit":"%s","baseline":{"value":%s,"source":"%s"},"weight":%s,"normalized":%s}\n' \
    "$ts" "$phase" "$metric" "$raw" "$unit" "$baseline_value" "$baseline_source" "$weight" "$normalized" \
    >> "$FITNESS_LOG"

  printf '[fitness] %s = %s (normalized=%s, baseline=%s)\n' \
    "$metric" "$raw" "$normalized" "$baseline_value" >&2
}

# If executed directly, print usage.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  cat <<'EOF'
tools/fitness/emit.sh — sourced by phase scripts.

Usage:
  source tools/fitness/emit.sh
  fitness_emit <phase> <metric> <raw> <unit> <weight>

Units: bool | semver | exit_code | seconds | bytes | count
Output: NDJSON appended to $FITNESS_LOG (default data/fitness-history.ndjson)
Baselines: looked up by metric in $BASELINES_FILE (default data/industry-baselines.json)
EOF
  exit 0
fi
