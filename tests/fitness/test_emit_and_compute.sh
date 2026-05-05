#!/usr/bin/env bash
# tests/fitness/test_emit_and_compute.sh
#
# End-to-end test for the fitness framework:
#   1. Sources tools/fitness/emit.sh
#   2. Emits a known set of atomic datums to a temp NDJSON log
#   3. Runs tools/fitness/compute.sh against that log
#   4. Asserts the compound score matches the expected weighted average

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
EMIT="$REPO_ROOT/tools/fitness/emit.sh"
COMPUTE="$REPO_ROOT/tools/fitness/compute.sh"
BASELINES="$REPO_ROOT/data/industry-baselines.json"

# Use a temp dir for log + snapshot so the real history is untouched.
tmpdir="$(mktemp -d -t fitness-test.XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

export FITNESS_LOG="$tmpdir/history.ndjson"
export SNAPSHOT="$tmpdir/snapshot.json"
export BASELINES_FILE="$BASELINES"

# Source the emitter.
# shellcheck source=../../tools/fitness/emit.sh
source "$EMIT"

fail=0
assert() {
  local label="$1" actual="$2" expected="$3"
  if [[ "$actual" == "$expected" ]]; then
    printf '  PASS: %s (%s)\n' "$label" "$actual"
  else
    printf '  FAIL: %s — expected %s, got %s\n' "$label" "$expected" "$actual"
    fail=$((fail + 1))
  fi
}

echo "[test] 1. emit five atomic datums for a synthetic phase 99"

# All five should normalize to 1.000 against their baselines (best case).
fitness_emit "99" "phase2.cc65_present" 1 "bool" "0.20"
fitness_emit "99" "phase2.cc65_version" 2.20 "semver" "0.15"
fitness_emit "99" "phase2.ca65_present" 1 "bool" "0.10"
fitness_emit "99" "phase2.apple2enh_compile" 0 "exit_code" "0.20"
fitness_emit "99" "phase2.p816_directive" 0 "exit_code" "0.15"

# Each line should be valid JSON
echo "[test] 2. each emitted line is valid JSON"
line_count=$(wc -l < "$FITNESS_LOG" | awk '{print $1}')
assert "line count == 5" "$line_count" "5"

while IFS= read -r line; do
  if ! echo "$line" | jq -e . >/dev/null 2>&1; then
    echo "  FAIL: invalid JSON line: $line"
    fail=$((fail + 1))
  fi
done < "$FITNESS_LOG"
echo "  PASS: all lines parse as JSON"

# Each normalized value should equal 1.000 (raw at or above baseline)
echo "[test] 3. normalized values are 1.000 for at-or-above-baseline raw"
all_one=$(jq -s 'map(.normalized) | all(. == 1.000)' "$FITNESS_LOG")
assert "all normalized == 1.000" "$all_one" "true"

# Test 4: degraded case — emit a below-baseline cc65 version, compound should drop
echo "[test] 4. degraded case — semver below baseline"
export FITNESS_LOG="$tmpdir/history2.ndjson"
fitness_emit "98" "phase2.cc65_present" 1 "bool" "0.20"
fitness_emit "98" "phase2.cc65_version" 1.50 "semver" "0.15"  # 1.50 / 2.19 = 0.685
fitness_emit "98" "phase2.apple2enh_compile" 1 "exit_code" "0.20"  # nonzero = 0.000

normalized_version=$(jq -s 'map(select(.metric == "phase2.cc65_version") | .normalized) | .[0]' "$FITNESS_LOG")
normalized_compile=$(jq -s 'map(select(.metric == "phase2.apple2enh_compile") | .normalized) | .[0]' "$FITNESS_LOG")
# Note: semver normalization is 1.50/2.19 = 0.6849... → printf "%.3f" → "0.685"
assert "semver below baseline normalized" "$normalized_version" "0.685"
assert "exit_code nonzero normalized" "$normalized_compile" "0.000"

# Test 5: compute.sh produces a snapshot
echo "[test] 5. compute.sh produces a snapshot"
export FITNESS_LOG="$tmpdir/history.ndjson"
export SNAPSHOT="$tmpdir/snapshot.json"
"$COMPUTE" >/dev/null
if [[ -f "$SNAPSHOT" ]]; then
  echo "  PASS: snapshot file exists"
else
  echo "  FAIL: snapshot file not created"
  fail=$((fail + 1))
fi

# Compound for phase 99 should be 1.000 (all metrics at baseline)
compound=$(jq '.phases[] | select(.phase == "99") | .compound' "$SNAPSHOT")
assert "phase 99 compound == 1.000" "$compound" "1"

# Test 6: compute.sh on degraded log
echo "[test] 6. compound calculation on degraded log"
export FITNESS_LOG="$tmpdir/history2.ndjson"
export SNAPSHOT="$tmpdir/snapshot2.json"
"$COMPUTE" >/dev/null
# Expected weighted average:
#   cc65_present: normalized=1.000, weight=0.20
#   cc65_version: normalized=0.685, weight=0.15  → 1.50/2.19 = 0.6849...
#   apple2enh_compile: normalized=0.000, weight=0.20
# numerator = 1.0*0.20 + 0.685*0.15 + 0.0*0.20 = 0.20 + 0.10275 + 0 = 0.30275
# denominator = 0.20 + 0.15 + 0.20 = 0.55
# compound = 0.30275 / 0.55 = 0.5505 (approx)
compound2=$(jq '.phases[] | select(.phase == "98") | (.compound * 1000 | round / 1000)' "$SNAPSHOT")
# Allow small floating-point variance: expect ~0.55 ± 0.01
expected_lo=0.54
expected_hi=0.56
within=$(awk -v c="$compound2" -v lo="$expected_lo" -v hi="$expected_hi" \
  'BEGIN { print (c+0 >= lo && c+0 <= hi) ? "true" : "false" }')
assert "phase 98 compound in [0.54, 0.56]" "$within" "true"

echo
if (( fail == 0 )); then
  echo "[test] all assertions pass"
  exit 0
else
  echo "[test] $fail assertion(s) failed"
  exit 1
fi
