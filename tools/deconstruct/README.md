# Deconstruction Infrastructure (Phase 6)

This directory holds the static analysis toolkit for 65816 OMF binaries using Ghidra headless mode.

## What this is

Phase 6 deconstruction is a **fitness function** that verifies Ghidra is installed and operational for headless analysis of Apple IIGS binaries. It does not perform disassembly automatically — it gates the infrastructure.

## What this is NOT

- **Not a compiler or linker.** Use cc65 or ORCA for building.
- **Not an emulator.** Use GSplus, KEGS, or MAME for execution.
- **Not a decompiler.** Ghidra produces annotated disassembly, not source code.

## The clean-room rule

**NO APPLE INTELLECTUAL PROPERTY BINARIES ARE IMPORTED HERE.**

The import wrapper (`import-omf.sh`) refuses to import from:
- `roms/`
- `disk-images/`
- `sources/`
- `includes/`
- `libraries/`
- `GS_OS_Source/`

Valid targets:
- User-supplied binaries (third-party, public-domain)
- Test artifacts (e.g., `hello-world/build/hello`)
- Community-contributed tools

## Files

### `install-ghidra.sh`

Prints step-by-step installation instructions for Ghidra 11.0+ and the 65816 SLEIGH processor module.

**Usage:**
```bash
bash tools/deconstruct/install-ghidra.sh
```

### `import-omf.sh`

Wrapper around `analyzeHeadless` for safe, guarded import of a single OMF or binary file.

**Usage:**
```bash
export DECONSTRUCT_TARGET=/path/to/hello-world/build/hello
export DECONSTRUCT_OUTPUT_DIR=/tmp/ghidra-out
bash tools/deconstruct/import-omf.sh
```

Returns 0 on success; non-zero on refusal (forbidden path) or import failure.

## Phase 6 Fitness Function

Run the fitness function to verify Ghidra is set up:

```bash
bash phases/phase6-deconstruct.sh
```

This emits three atomics:
1. **`phase6.ghidra_present`** (bool, weight 0.40) — analyzeHeadless or ghidraRun on PATH
2. **`phase6.ghidra_version`** (semver, weight 0.30) — version >= 11.0
3. **`phase6.target_imports_clean`** (exit_code, weight 0.30) — successful headless import of `$DECONSTRUCT_TARGET` (if set)

Exit codes:
- **0 (green):** All checks pass; Ghidra is ready
- **1 (red):** Ghidra missing or version too old; import failed
- **2 (yellow):** Ghidra present but version unknown or target not tested

## Installing Ghidra

1. Download from https://github.com/NationalSecurityAgency/ghidra/releases (v11.0+)
2. Extract to a standard location (e.g., `~/tools/ghidra_11.x_PUBLIC`)
3. Install the 65816 SLEIGH processor module (community-contributed, search GitHub for `ghidra-6502` or `ghidra-65816`)
4. Add `<ghidra-path>/support` to `PATH`
5. Run `bash tools/deconstruct/install-ghidra.sh` for full details

## References

- **Ghidra Releases:** https://github.com/NationalSecurityAgency/ghidra/releases
- **Ghidra Headless Documentation:** https://github.com/NationalSecurityAgency/ghidra/blob/master/Ghidra/RuntimeScripts/Common/support/analyzeHeadlessREADME.html
- **6502/65816 Processor Module:** https://github.com/andrew-jacobs/ghidra-6502
- **Ghidra Scripting:** https://ghidra.re/ghidra_docs/api/ghidra/app/script/doc/GhidraScriptProperties.html
