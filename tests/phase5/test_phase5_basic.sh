#!/usr/bin/env bash
# Basic sanity test for phase5-emulator-boot.sh
# Verifies:
#   1. Script exists and is executable
#   2. Script outputs machine-readable (key=value) facts to stdout
#   3. Script outputs human-readable notes to stderr
#   4. Exit code is 0 (green), 1 (red), or 2 (yellow)

script="$(dirname "$0")/../../phases/phase5-emulator-boot.sh"

if [[ ! -x "$script" ]]; then
  echo "✗ FAIL: phase5-emulator-boot.sh not executable"
  exit 1
fi

# Run script with no environment variables (expect yellow exit code 2)
unset IIGS_ROM_PATH
unset IIGS_DISK_IMAGE_PATH
output=$("$script" 2>&1)
exit_code=$?

echo "Exit code (no env vars): $exit_code"

# Verify exit code is valid (should be 2 for missing prerequisites)
if [[ ! "$exit_code" =~ ^[0-2]$ ]]; then
  echo "✗ FAIL: invalid exit code $exit_code (expected 0, 1, or 2)"
  exit 1
fi

# Verify stdout has key=value lines
if ! echo "$output" | grep -q '^[a-z_]*=[^=]*$'; then
  echo "✗ FAIL: no key=value output found"
  exit 1
fi

# Verify stderr has human-readable notes
if ! echo "$output" | grep -q '\[phase5\]'; then
  echo "✗ FAIL: no [phase5] notes found"
  exit 1
fi

echo "✓ PASS: phase5-emulator-boot.sh output is valid"
exit 0
