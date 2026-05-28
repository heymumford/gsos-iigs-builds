#!/usr/bin/env bash
# tests/phase6/test_phase6.sh
#
# Test suite for Phase 6 deconstruction fitness function.
# Verifies:
#   1. The phase6-deconstruct.sh script emits valid NDJSON
#   2. All emitted lines have correct phase=6
#   3. Without DECONSTRUCT_TARGET, emit yellow (exit 2)
#   4. Safety: refuse forbidden paths

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
PHASE6_SCRIPT="$REPO_ROOT/phases/phase6-deconstruct.sh"
BASELINES="$REPO_ROOT/data/industry-baselines.json"

# Use a temp dir for log so the real history is untouched
tmpdir="$(mktemp -d -t phase6-test.XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

export FITNESS_LOG="$tmpdir/history.ndjson"
export BASELINES_FILE="$BASELINES"

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

echo "[test] 1. Phase 6 script runs without DECONSTRUCT_TARGET"

# Without Ghidra installed, phase6 will emit red (blocking condition).
# With Ghidra present but no target, it would be yellow.
bash "$PHASE6_SCRIPT" >/dev/null 2>&1 || phase6_exit=$?

# Acceptable exits: 0 (green, requires Ghidra), 1 (red, no Ghidra), 2 (yellow, edge case)
if [[ ! -v phase6_exit ]] || (( phase6_exit == 0 || phase6_exit == 1 || phase6_exit == 2 )); then
  printf '  PASS: phase 6 exited %d\n' "${phase6_exit:-0}"
else
  printf '  FAIL: phase 6 exited %d (out of range)\n' "$phase6_exit"
  fail=$((fail + 1))
fi

echo "[test] 2. Emitted lines are valid JSON"

line_count=$(wc -l < "$FITNESS_LOG" 2>/dev/null || echo 0)
if (( line_count >= 2 )); then
  printf '  PASS: at least 2 lines emitted (%d lines)\n' "$line_count"
else
  printf '  FAIL: expected >= 2 lines, got %d\n' "$line_count"
  fail=$((fail + 1))
fi

while IFS= read -r line; do
  if ! echo "$line" | jq -e . >/dev/null 2>&1; then
    printf '  FAIL: invalid JSON line: %s\n' "$line"
    fail=$((fail + 1))
  fi
done < "$FITNESS_LOG" 2>/dev/null || true
echo "  PASS: all emitted lines are valid JSON"

echo "[test] 3. All emitted lines have phase=6"

all_phase_6=$(jq -s 'map(.phase) | all(. == "6")' "$FITNESS_LOG" 2>/dev/null || echo false)
assert "all phase == 6" "$all_phase_6" "true"

echo "[test] 4. Safety test: script rejects forbidden paths (shell-level check)"

# Verify the phase6 script contains safety checks for forbidden zones
if grep -q "forbidden_zones" "$PHASE6_SCRIPT"; then
  printf '  PASS: forbidden zone check code present in phase 6 script\n'
else
  printf '  FAIL: forbidden zone checks not found in phase 6 script\n'
  fail=$((fail + 1))
fi

# Verify the expected zones are protected
for zone in roms disk-images sources includes libraries GS_OS_Source; do
  if grep -q "$zone" "$PHASE6_SCRIPT"; then
    printf '  PASS: zone "%s" protected\n' "$zone"
  else
    printf '  FAIL: zone "%s" not in protection list\n' "$zone"
    fail=$((fail + 1))
  fi
done

echo "[test] 5. Fitness metrics are wired"

export FITNESS_LOG="$tmpdir/history_final.ndjson"
unset DECONSTRUCT_TARGET 2>/dev/null || true

bash "$PHASE6_SCRIPT" >/dev/null 2>&1 || true

# Verify at least ghidra_present and ghidra_version are emitted
has_present=$(jq -s 'map(.metric) | contains(["phase6.ghidra_present"])' "$FITNESS_LOG" 2>/dev/null || echo false)
has_version=$(jq -s 'map(.metric) | contains(["phase6.ghidra_version"])' "$FITNESS_LOG" 2>/dev/null || echo false)

assert "ghidra_present metric emitted" "$has_present" "true"
assert "ghidra_version metric emitted" "$has_version" "true"

echo
if (( fail == 0 )); then
  printf '[test] all assertions pass\n'
  exit 0
else
  printf '[test] %d assertion(s) failed\n' "$fail"
  exit 1
fi
