# gsos-iigs-builds
![CI](https://github.com/heymumford/gsos-iigs-builds/actions/workflows/ci.yml/badge.svg)

Apple IIGS GS/OS builds. A fitness-function-driven pipeline for self-hosted OS compilation using APW (Apple Programmer's Workshop).

## What this repo is

Build infrastructure for compiling GS/OS 6.0.x on an Apple IIGS (real hardware or emulator). Each phase is gated by a fitness function — a script that exits 0 (green) when the prerequisite invariant holds, non-zero (red) when it does not. Phases gate each other: no Phase 2 work begins until Phase 1 is green, etc.

## What this repo is not

This repo does **not** contain GS/OS source code. The GS/OS 6.0.x source is Apple intellectual property. Build scripts expect the source to be present at a configurable path; obtaining it is not in scope here.

GS/OS 6.0.x source was originally written and maintained on the Macintosh under MPW IIGS. Compiling on the IIGS using APW requires hand-porting the build scripts (Make syntax) and meeting the memory and storage demands of a self-hosted OS build.

## Fitness Function Phases

### Phase 1 — Hardware & Environment

Verify the build host (real IIGS or emulator) meets the floor for self-hosted compilation.

- RAM ≥ 4MB. 8MB recommended; APW and the linker crash with "Out of Memory" on large GS/OS source files at 4MB.
- Mass storage (CF/SD card or hard drive) with multiple 32MB ProDOS partitions: source, object files, tools.
- APW Shell ≥ 1.0.2 active. `PREFIX` and `PATH` mapped to the tools directory.

Run: `phases/phase1-hardware.sh`

### Phase 2 — Compiler & Toolchain

Verify the 65816 + ORCA/Pascal toolchain is present and version-correct.

- AsmIIGS (65816 assembler) supports the large macros used in the GS/OS kernel.
- LinkIIGS (linker) is the 16-bit version with Segment definition support for the GS/OS memory map.
- Rez (resource compiler) present — required for Finder and Control Panel resources.
- APW Make can parse the build files. MPW Make files must be ported to APW Make syntax.

Run: `phases/phase2-toolchain.sh`

### Phase 3 — Ground Truth Source

Verify integrity of the source tree (once supplied out-of-band).

- Encoding: MacRoman or ProDOS ASCII. Line endings: CR, not LF.
- `{Includes}GSOS.h` and similar hard-coded include paths resolve. Set the `Includes` env var or alias.
- Apple IIGS Interface Libraries (`Interfaces`, `Libraries` folders) match the GS/OS version being built.

Run: `phases/phase3-source-truth.sh`

### Phase 4 — Bootable Artifact

Verify compiled binaries (`SYS`, `FST`, `DRIVER`) boot from a 3.5" disk.

- `ProDOS` (P8) at root of 800K disk.
- Compiled kernel named `GS.OS` at root.
- `.Sony` or `.Disk3.5` driver in `*/SYSTEM/DRIVERS/`.
- Total size of `System/`, `Drivers/`, `Tools/` < 800K (single floppy boot).

Run: `phases/phase4-bootable.sh`

## Strategy

**Toolchain test before kernel build.** Compile a 16-bit GS/OS Hello World application using APW. Once that lights green under Phases 1+2, compile a single GS/OS driver. Only then attempt the full kernel.

`hello-world/` holds the smoke-test app and its TDD harness.

## Layout

```
phases/         fitness-function scripts, one per phase, exit 0 = green
hello-world/    minimal 16-bit GS/OS app, toolchain smoke test
docs/           porting notes, MPW→APW Make conversion, partition layouts
```

## Roadmap, decisions, and fitness framework

- [`ROADMAP.md`](ROADMAP.md) — slice plan, current state, next waves
- [`docs/decisions.md`](docs/decisions.md) — ADR-style decision log (Apple IP boundary, ORCA path, fitness contract, stop conditions)
- [`docs/source-mount-references.md`](docs/source-mount-references.md) — legitimate sources for GS/OS, ROMs, and disk images
- [`tools/fitness/README.md`](tools/fitness/README.md) — atomic + compound + time-series fitness framework
- [`data/industry-baselines.json`](data/industry-baselines.json) — citation-bearing reference values per metric

Each phase script emits atomic fitness datums (NDJSON) normalized to [0.000 ... 1.000] against industry baselines. `tools/fitness/compute.sh` aggregates them into a compound score per phase.

## Status

| Phase | Script | State |
|-------|--------|-------|
| 1 — Hardware | `phases/phase1-hardware.sh` | implemented (cc65 POSIX host variant) |
| 2 — Toolchain (cc65) | `phases/phase2-toolchain.sh` | implemented + fitness emission wired |
| 2-ORCA — Toolchain (16-bit) | `phases/phase2-orca.sh` | implemented (ORCA/C + Golden Gate) |
| 3 — Source | `phases/phase3-source-truth.sh` | not yet implemented |
| 4 — Bootable | `phases/phase4-bootable.sh` | not yet implemented |
| 5 — Emulator Boot | `phases/phase5-emulator-boot.sh` | implemented (GSplus/KEGS/MAME support) |
| 6 — Deconstruction | `phases/phase6-deconstruct.sh` | implemented (Ghidra headless infrastructure) |
| Hello World (cc65) | `hello-world/` | implemented (8-bit smoke) |
| Hello World (S16) | `hello-world-s16/` | implemented (ORCA/C real S16) |
| Toolchain Doc | `docs/toolchain-paths.md` | cc65 + ORCA + APW |
| ORCA Install Doc | `docs/install-orca.md` | implemented |
| Emulator Doc | `docs/emulator-setup.md` | implemented (GSplus primary, KEGS/MAME fallback) |
| Deconstruct Doc | `tools/deconstruct/README.md` | Ghidra + 65816 SLEIGH + clean-room rules |
| Fitness Framework | `tools/fitness/` | implemented (emit + compute + baselines + tests) |

## License

Build infrastructure is MIT-licensed (see `LICENSE`). License does not extend to any GS/OS source code or Apple IIGS Interface Libraries that may be placed in expected paths at build time — those remain Apple IP.
