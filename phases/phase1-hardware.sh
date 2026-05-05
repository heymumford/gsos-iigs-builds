#!/usr/bin/env bash
# Phase 1 — Hardware & Environment fitness function.
#
# Green when:
#   - RAM >= 4MB (8MB recommended)
#   - Mass storage with multiple 32MB ProDOS partitions present
#   - APW Shell >= 1.0.2 active
#   - PREFIX and PATH mapped to tools
#
# Stub: prints intent, exits 2 (yellow — instrument not yet built).

set -u

cat >&2 <<'EOF'
[phase1] Hardware & Environment fitness function — STUB.
[phase1] Will check: RAM >= 4MB, ProDOS partitions, APW Shell >= 1.0.2, PREFIX/PATH.
[phase1] Run me on the IIGS or emulator host once implemented.
EOF

echo "phase=1"
echo "state=yellow"
echo "reason=stub_not_implemented"
exit 2
