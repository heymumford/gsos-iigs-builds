#!/usr/bin/env bash
# test_compile.sh — verify cc65 toolchain is present and functional.
# Runs the Phase 2 fitness function to gate this test.
#
# Exit codes:
#   0: green (cc65 is available and >= v2.19)
#   1: red (cc65 not found or version too old)
#   2: yellow (cc65 present but version cannot be determined)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE2_SCRIPT="$SCRIPT_DIR/../../phases/phase2-toolchain.sh"

if [[ ! -f "$PHASE2_SCRIPT" ]]; then
    echo "[test_compile] YELLOW: phase2-toolchain.sh not found at $PHASE2_SCRIPT" >&2
    exit 2
fi

# Run Phase 2 fitness function and capture exit code
if bash "$PHASE2_SCRIPT" >/dev/null 2>&1; then
    echo "[test_compile] GREEN: cc65 toolchain is available" >&2
    exit 0
else
    phase2_exit=$?
    echo "[test_compile] RED: cc65 toolchain not available (phase2 exit code: $phase2_exit)" >&2
    exit 1
fi
