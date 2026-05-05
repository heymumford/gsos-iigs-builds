#!/usr/bin/env bash
# tools/deconstruct/install-ghidra.sh
#
# Prints instructions for installing Ghidra and the 65816 SLEIGH processor module.
# This script does NOT perform automatic installation — it documents the process.

set -u

cat <<'EOF'
Ghidra Installation & 65816 Module Setup
==========================================

Phase 6 deconstruction requires Ghidra 11.0+ in headless mode.

STEP 1: Install Ghidra
-----------------------

1. Download Ghidra 11.0+ from:
   https://github.com/NationalSecurityAgency/ghidra/releases

2. Extract to a standard location (e.g., /opt/ghidra or ~/tools/ghidra):
   unzip ghidra_11.x_PUBLIC.zip -d ~/tools/

3. Verify the installation:
   ~/tools/ghidra_11.x_PUBLIC/support/analyzeHeadless --help

4. Add to PATH (add to ~/.bashrc or ~/.zshrc):
   export PATH="$PATH:$HOME/tools/ghidra_11.x_PUBLIC/support"

STEP 2: Install 65816 SLEIGH Processor Module (Community)
----------------------------------------------------------

The 65816 processor (Apple IIGS CPU) is not in the Ghidra core distribution.
Install a community-contributed 65816 module:

Option A: ghidra-6502 (covers 6502 + 65C02 + 65816)
   Repository: https://github.com/andrew-jacobs/ghidra-6502
   1. Clone: git clone https://github.com/andrew-jacobs/ghidra-6502 ~/tools/ghidra-6502
   2. Copy to Ghidra extensions:
      mkdir -p ~/tools/ghidra_11.x_PUBLIC/Extensions/Ghidra
      cp -r ~/tools/ghidra-6502 ~/tools/ghidra_11.x_PUBLIC/Extensions/Ghidra/
   3. Restart analyzeHeadless (extensions are loaded on startup)

Option B: ghidra-65816 (65816-specific)
   Search GitHub for "ghidra 65816 sleigh" or "ghidra m65816"
   Install similarly to Option A.

STEP 3: Verify 65816 Support
-----------------------------

Once the module is installed, test that 65816 is available:

   # Create a minimal 65816 assembly file
   cat > /tmp/test_65816.s <<'SAMPLE'
   .org $00
   lda #$1234
   rtl
   SAMPLE

   # Ghidra should recognize the 65816 processor in import options

STEP 4: Test with Phase 6
--------------------------

Once installed, test phase 6 fitness:

   export DECONSTRUCT_TARGET=/path/to/your/omf/binary
   bash phases/phase6-deconstruct.sh

Exit code 0 = green (all checks pass).
Exit code 2 = yellow (Ghidra present but module or target missing).
Exit code 1 = red (Ghidra missing or target import failed).

Resources
---------

- Ghidra Releases: https://github.com/NationalSecurityAgency/ghidra/releases
- Ghidra Headless README:
  https://github.com/NationalSecurityAgency/ghidra/blob/master/Ghidra/RuntimeScripts/Common/support/analyzeHeadlessREADME.html
- 6502 Processor Module: https://github.com/andrew-jacobs/ghidra-6502
- Ghidra Scripting Guide: https://ghidra.re/ghidra_docs/api/ghidra/app/script/doc/GhidraScriptProperties.html

Clean-Room Rule
---------------

DECONSTRUCT_TARGET must point to a user-supplied binary or a test artifact
(hello-world/ build, etc.). Phase 6 automatically refuses to import binaries
from:
  - roms/
  - disk-images/
  - sources/
  - includes/
  - libraries/
  - GS_OS_Source/

This enforces the apple-ip-boundary contract: no Apple proprietary binaries
are disassembled by this infrastructure.
EOF
