#!/usr/bin/env bash
# Phase 4 — Bootable Artifact fitness function.
#
# Green when an 800K disk image:
#   - Has ProDOS (P8) at root
#   - Has the compiled kernel named GS.OS at root
#   - Has .Sony or .Disk3.5 driver in */SYSTEM/DRIVERS/
#   - Total size of System/, Drivers/, Tools/ < 800K
#
# Stub: prints intent, exits 2 (yellow).

set -u

cat >&2 <<'EOF'
[phase4] Bootable Artifact fitness function — STUB.
[phase4] Will verify: ProDOS root, GS.OS kernel, driver path, < 800K floppy budget.
[phase4] Operates on a built disk image; should be runnable in CI against an emulator.
EOF

echo "phase=4"
echo "state=yellow"
echo "reason=stub_not_implemented"
exit 2
