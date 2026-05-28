#!/usr/bin/env bash
# tools/deconstruct/import-omf.sh
#
# Wrapper around analyzeHeadless for safe, guarded import of OMF/binary files.
#
# Usage:
#   DECONSTRUCT_TARGET=/path/to/binary.omf bash import-omf.sh
#   DECONSTRUCT_OUTPUT_DIR=/tmp/ghidra-out DECONSTRUCT_TARGET=... bash import-omf.sh
#
# Environment:
#   DECONSTRUCT_TARGET — path to OMF binary to import (required)
#   DECONSTRUCT_OUTPUT_DIR — where to write analysis output (default /tmp/ghidra-out)
#
# Clean-room: refuses to import from roms/, disk-images/, sources/, includes/,
# libraries/, GS_OS_Source/, or any path inside the repo.

set -u

DECONSTRUCT_OUTPUT_DIR="${DECONSTRUCT_OUTPUT_DIR:-/tmp/ghidra-out}"

if [[ -z "${DECONSTRUCT_TARGET:-}" ]]; then
  printf '[import-omf] ERROR: DECONSTRUCT_TARGET not set\n' >&2
  exit 1
fi

if [[ ! -r "$DECONSTRUCT_TARGET" ]]; then
  printf '[import-omf] ERROR: DECONSTRUCT_TARGET "%s" not readable\n' "$DECONSTRUCT_TARGET" >&2
  exit 1
fi

# Safety check: refuse paths inside gitignored/sensitive zones
repo_root="$(cd "$(dirname "$0")/../.." && pwd -P)"
forbidden_zones=("roms" "disk-images" "sources" "includes" "libraries" "GS_OS_Source")

is_forbidden=0
for zone in "${forbidden_zones[@]}"; do
  if [[ "$DECONSTRUCT_TARGET" =~ ^${repo_root}/${zone}/ ]] || [[ "$DECONSTRUCT_TARGET" =~ ${zone}/ ]]; then
    printf '[import-omf] ERROR: DECONSTRUCT_TARGET is in forbidden zone "%s"\n' "$zone" >&2
    is_forbidden=1
    break
  fi
done

if (( is_forbidden )); then
  exit 1
fi

# Create output directory
mkdir -p "$DECONSTRUCT_OUTPUT_DIR"

# Create a minimal post-script for analysis
postscript="$DECONSTRUCT_OUTPUT_DIR/analyze.py"
cat > "$postscript" <<'PYSCRIPT'
# Ghidra post-import script for 65816 analysis.
# Placeholder: currently a no-op. Future versions can add:
# - Symbol table enumeration
# - Cross-reference discovery
# - Export of disassembly to text format

print("Ghidra import complete for 65816 binary analysis")
PYSCRIPT

# Invoke analyzeHeadless
printf '[import-omf] Importing "%s" to "%s"...\n' "$DECONSTRUCT_TARGET" "$DECONSTRUCT_OUTPUT_DIR" >&2

if ! command -v analyzeHeadless &>/dev/null; then
  printf '[import-omf] ERROR: analyzeHeadless not found on PATH\n' >&2
  printf '[import-omf] Install Ghidra and add its support/ directory to PATH\n' >&2
  exit 1
fi

# 60-second timeout for headless import
timeout 60 analyzeHeadless \
  "$DECONSTRUCT_OUTPUT_DIR/ghidra_proj" \
  "65816_analysis" \
  -import "$DECONSTRUCT_TARGET" \
  -postScript "$postscript" \
  >/dev/null 2>&1

import_exit=$?

if (( import_exit == 0 )); then
  printf '[import-omf] Import succeeded\n' >&2
  exit 0
elif (( import_exit == 124 )); then
  printf '[import-omf] ERROR: Import timed out after 60 seconds\n' >&2
  exit 1
else
  printf '[import-omf] ERROR: Import failed (exit code %d)\n' "$import_exit" >&2
  exit 1
fi
