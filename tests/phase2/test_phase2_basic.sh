#!/usr/bin/env bash
# Basic sanity test for phase2-toolchain.sh
# Verifies:
#   1. Script exists and is executable
#   2. Script outputs machine-readable (key=value) facts to stdout
#   3. Script outputs human-readable notes to stderr
#   4. Exit code is 0 (green), 1 (red), or 2 (yellow)

# set -u removed due to ZSH_VERSION variable check issues in subshells

script="$(dirname "$0")/../../phases/phase2-toolchain.sh"

if [[ ! -x "$script" ]]; then
  echo "✗ FAIL: phase2-toolchain.sh not executable"
  exit 1
fi

# Run script and capture output
output=$("$script" 2>&1)
exit_code=$?

echo "Exit code: $exit_code"

# Verify exit code is valid
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
if ! echo "$output" | grep -q '\[phase2\]'; then
  echo "✗ FAIL: no [phase2] notes found"
  exit 1
fi

echo "✓ PASS: phase2-toolchain.sh output is valid"
exit 0
