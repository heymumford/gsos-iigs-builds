#!/usr/bin/env bash
# Phase 2 — Compiler & Toolchain fitness function.
#
# Green when:
#   - AsmIIGS supports kernel macros
#   - LinkIIGS is the 16-bit Segment-aware version
#   - Rez present
#   - APW Make can parse the build files (port from MPW Make if needed)
#
# Stub: prints intent, exits 2 (yellow).

set -u

cat >&2 <<'EOF'
[phase2] Compiler & Toolchain fitness function — STUB.
[phase2] Will verify: AsmIIGS macro support, LinkIIGS Segment support, Rez, APW Make.
[phase2] Blocked until phase1 is green.
EOF

echo "phase=2"
echo "state=yellow"
echo "reason=stub_not_implemented"
exit 2
