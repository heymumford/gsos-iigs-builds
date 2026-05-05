#!/usr/bin/env bash
# Phase 3 — Ground Truth Source fitness function.
#
# Green when:
#   - Source files are MacRoman or ProDOS ASCII with CR line endings
#   - {Includes}* paths resolve
#   - Apple IIGS Interface Libraries (Interfaces, Libraries) match GS/OS version
#
# Stub: prints intent, exits 2 (yellow).

set -u

cat >&2 <<'EOF'
[phase3] Ground Truth Source fitness function — STUB.
[phase3] Will verify: encoding (MacRoman/ProDOS ASCII), CR line endings,
[phase3]               include resolution, Interfaces/Libraries presence and version.
[phase3] Source must be supplied out-of-band; this repo never ships it.
EOF

echo "phase=3"
echo "state=yellow"
echo "reason=stub_not_implemented"
exit 2
