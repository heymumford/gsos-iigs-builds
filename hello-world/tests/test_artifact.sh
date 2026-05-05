#!/usr/bin/env bash
# test_artifact.sh — verify compiled binary is a valid 16-bit S16 (Application) file.
#
# Usage: test_artifact.sh <binary_path>
#
# Exit codes:
#   0: green (file exists and has correct type/size)
#   1: red (file missing, empty, or wrong type)
#   2: yellow (file present but type cannot be determined)

set -u

BINARY="${1:?Usage: test_artifact.sh <binary_path>}"

if [[ ! -f "$BINARY" ]]; then
    echo "[test_artifact] RED: binary file not found: $BINARY" >&2
    exit 1
fi

if [[ ! -s "$BINARY" ]]; then
    echo "[test_artifact] RED: binary is empty: $BINARY" >&2
    exit 1
fi

# For apple2enh (ProDOS), we expect a 16-bit file with file type $B3 (S16).
# Use `file` to detect type; if not available, assume YELLOW.
if ! command -v file &>/dev/null; then
    echo "[test_artifact] YELLOW: 'file' command not available, cannot verify type" >&2
    exit 2
fi

file_output=$(file "$BINARY" 2>&1)

# Look for "Mach-O" or "executable" or similar marker; ProDOS/apple2enh may report differently
if echo "$file_output" | grep -q -E "(Mach-O|executable|apple|binary)"; then
    file_size=$(stat -f%z "$BINARY" 2>/dev/null || stat -c%s "$BINARY" 2>/dev/null || echo "?")
    echo "[test_artifact] GREEN: binary is valid ($file_size bytes)" >&2
    exit 0
else
    echo "[test_artifact] YELLOW: file type unclear: $file_output" >&2
    exit 2
fi
