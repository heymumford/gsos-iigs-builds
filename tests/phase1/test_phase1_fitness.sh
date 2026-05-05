#!/usr/bin/env bash
# tests/phase1/test_phase1_fitness.sh
#
# Test that phase1-hardware.sh emits exactly three atomic fitness datums:
#   - phase1.ram_gb (raw=measured, unit=count, weight=0.40)
#   - phase1.disk_gb (raw=measured, unit=count, weight=0.30)
#   - phase1.emulator_present (raw=0|1, unit=bool, weight=0.30)
#
# Each line is validated as JSON and checked for correct metric names and phase.

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
PHASE1="$REPO_ROOT/phases/phase1-hardware.sh"
BASELINES="$REPO_ROOT/data/industry-baselines.json"

# Use a temp file for the fitness log so the real history is untouched.
tmpdir="$(mktemp -d -t phase1-test.XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

export FITNESS_LOG="$tmpdir/history.ndjson"
export BASELINES_FILE="$BASELINES"

echo "[test] Running phase1-hardware.sh with FITNESS_LOG=$FITNESS_LOG"
bash "$PHASE1" >/dev/null 2>&1 || true

echo "[test] Checking fitness log was created"
if [[ ! -f "$FITNESS_LOG" ]]; then
  echo "  FAIL: $FITNESS_LOG not created"
  exit 1
fi
echo "  PASS: $FITNESS_LOG exists"

echo "[test] Checking exactly 3 lines emitted"
line_count=$(wc -l < "$FITNESS_LOG" | awk '{print $1}')
if [[ "$line_count" -eq 3 ]]; then
  echo "  PASS: line count == 3"
else
  echo "  FAIL: expected 3 lines, got $line_count"
  exit 1
fi

echo "[test] Validating each line is valid JSON"
while IFS= read -r line; do
  if ! echo "$line" | jq -e . >/dev/null 2>&1; then
    echo "  FAIL: invalid JSON line: $line"
    exit 1
  fi
done < "$FITNESS_LOG"
echo "  PASS: all lines are valid JSON"

echo "[test] Checking phase == '1' for all lines"
all_phase_1=$(jq -s 'map(.phase == "1") | all' "$FITNESS_LOG")
if [[ "$all_phase_1" == "true" ]]; then
  echo "  PASS: all lines have phase='1'"
else
  echo "  FAIL: not all lines have phase='1'"
  exit 1
fi

echo "[test] Checking metric names are correct"
metrics=$(jq -s 'map(.metric) | sort' "$FITNESS_LOG" | jq -r '.[]')
expected_metrics="phase1.disk_gb
phase1.emulator_present
phase1.ram_gb"

actual_metrics=$(echo "$metrics" | sort)
if [[ "$actual_metrics" == "$expected_metrics" ]]; then
  echo "  PASS: metrics are {phase1.ram_gb, phase1.disk_gb, phase1.emulator_present}"
else
  echo "  FAIL: metrics do not match"
  echo "Expected:"
  echo "$expected_metrics"
  echo "Actual:"
  echo "$actual_metrics"
  exit 1
fi

echo
echo "[test] All assertions pass"
exit 0
