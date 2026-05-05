# Toolchain Paths — cc65 vs APW

This document outlines the two viable paths for compiling GS/OS 6.0.x, noting that this phase-1 implementation chooses the cross-compile path (cc65 on POSIX hosts) as the CI default.

## Path A: Cross-Compile via cc65 (POSIX Host)

**Toolchain authority:** https://cc65.github.io/

**Overview:** cc65 is a complete cross-development package for 6502/65816-based systems. It provides a C compiler, assembler (ca65), linker (ld65), and utilities for developing software for retro computers. The 65816 instruction set is fully supported.

**Relevant cc65 features for IIGS/GS/OS:**
- Target: `apple2enh` (Enhanced Apple II; closest stock target for 65816 awareness)
- Assembler directive: `.P816` enables 65816 instruction set
- CPU detection: `__CPU_65816__` macro available for conditional compilation
- Platform detection: `__APPLE2__` macro defined for Apple II/IIe targets

**Advantages:**
- CI-friendly: runs on any POSIX host (Linux, macOS, \*BSD) without hardware or emulation layer
- Reproducible builds: deterministic cross-compiler output
- Fast iteration: no emulation startup overhead
- Version-locked: cc65 versions are stable and well-documented
- Well-maintained: active upstream (github.com/cc65/cc65)

**Disadvantages:**
- Diverges from "self-hosted OS build" purist ideal: GS/OS was originally built on a Macintosh under MPW IIGS
- Target platform mismatch: `apple2enh` is not IIGS-native; some 65816-specific idioms may require explicit conditional compilation
- No native ProDOS filesystem operations: build artifacts must be staged for transfer to real hardware or emulator

**Toolchain version (stable):** cc65 v2.19+ (released 2024+, includes 65816 full support)

## Path B: ORCA/C via Golden Gate (POSIX Host)

**Toolchain authority:** https://github.com/byteworksinc/ORCA-C (compiler) + https://github.com/ksherlock/golden-gate (compatibility layer)

**Overview:** ORCA/C is the canonical 16-bit C compiler for the Apple IIGS. Golden Gate is a compatibility layer that allows ORCA command-line tools (ORCA/C, ORCA/M, ORCALink) to run natively on POSIX systems. Together, they enable authentic IIGS development on modern machines without emulation overhead.

**Relevant ORCA/C features:**
- **Compiler:** ANSI C (C17-capable) for 65816 with native IIGS system calls
- **Assembler (ORCA/M):** Macro assembler for 65816 with S16 segment support
- **Linker (ORCALink):** 16-bit linker producing OMF (Object Module Format) S16 binaries
- **Standard library (ORCALib):** GS/OS Toolbox libraries, native ProDOS I/O
- **Output:** True 16-bit S16 executable binaries (type $B3) for IIGS hardware or emulator

**Advantages:**
- CI-friendly: runs on any POSIX host without emulation layer
- Authentic output: produces real 16-bit S16 binaries, not 8-bit targets
- Direct compilation: ORCA/C → assembly → object → link → S16 executable
- Minimal overhead: Golden Gate is a thin wrapper; no emulator startup latency
- Self-hosted path: compiles GS/OS kernel code (the original ORCA target)
- Standard library: full ORCALib integration for GS/OS Toolbox calls
- Well-maintained: ORCA/C 2.2.1+ is current and actively updated

**Disadvantages:**
- Build complexity: requires both Golden Gate and ORCA/C installations
- Newer toolchain: cc65's `apple2enh` target is more mature for quick prototyping
- Infrastructure: ORCA installation must be discoverable by Golden Gate

**Toolchain version (stable):** ORCA/C 2.2.1+ (released 2023+), Golden Gate 1.0+ (GitHub latest)

**Installation:** See `docs/install-orca.md` for detailed setup steps.

## Path C: APW on Emulated or Real IIGS

**Toolchain authority:** Apple Programmer's Workshop (Apple IIGS Programmer's Workshop Assembler Reference; PDF: http://www.goldstarsoftware.com/applesite/Documentation/APWAssemblerReference.PDF)

**Overview:** APW is the native integrated development environment for the IIGS. It consists of:
- AsmIIGS: 65816 assembler with macro support for kernel-scale development
- LinkIIGS: 16-bit linker with Segment definition support (required for GS/OS memory map)
- Rez: resource compiler for Finder and Control Panel resources
- APW Make: build tool with ProDOS filesystem integration

**Advantages:**
- Authentic environment: GS/OS was originally built under APW on IIGS hardware
- Native filesystem: ProDOS operations are first-class (no staging/transfer step)
- Memory map fidelity: LinkIIGS Segment directives directly map to IIGS memory layout
- Macro ecosystem: AsmIIGS macro libraries are canonical for GS/OS kernel work
- Self-hosted build: entire toolchain runs on the target platform

**Disadvantages:**
- CI-unfriendly: requires IIGS hardware or stable emulation (KEGS, GSplus, MAME)
- Infrastructure heavy: emulator setup, disk image mounting, ProDOS partition management
- Maintenance burden: APW is discontinued; distribution is retro-computing community sourced
- Slow iteration: emulator startup, shell I/O, and disk operations add latency
- Skill penalty: APW Make syntax differs from modern Make; MPW Make ports require adaptation

**Emulator options:**
- KEGS (Karl E. Gustafson): lightweight, command-line friendly, active development
- GSplus (digarok/gsplus): modern fork, SDL2-based, cross-platform
- MAME apple2gs driver: full-featured, but heavy configuration

## V1 Strategy: cc65 (8-bit), ORCA/Golden Gate (16-bit), APW as Long-Tail Variant

**Rationale:**
1. **Dual path:** cc65 (8-bit Apple II Enhanced target) is a quick smoke test; ORCA/Golden Gate (16-bit S16 binaries) is the authentic GS/OS path.
2. **Velocity:** Both paths run on POSIX CI with no emulation overhead. ORCA reaches real kernel/driver code; cc65 validates toolchain readiness.
3. **Reversibility:** Phase 2 now offers two independent fitness functions (`phase2-toolchain.sh` for cc65, `phase2-orca.sh` for ORCA). Each is decoupled from the other and from APW.
4. **Learning:** ORCA/Golden Gate exposes the real constraints of GS/OS development (OMF linking, segment definitions, Toolbox calls). cc65 remains a shallow-test option.
5. **Compatibility:** Both paths compile the same source tree. Conditional compilation (e.g., `#ifdef __ORCA__` / `#ifdef __CC65__`) bridges differences without forking.

**Next phases (slice 3+):**
- Phase 3 (Source Truth) remains toolchain-agnostic: it tests source properties (encoding, line endings, includes).
- Phase 4 (Bootable Artifact) will prioritize ORCA/Golden Gate for authentic S16 binaries; cc65 variant deferred.
- APW-based phases (`phase1-hardware-apw.sh`, `phase2-toolchain-apw.sh`, etc.) are long-tail, added only after emulator infrastructure (KEGS, GSplus, MAME) is stable and in-scope.

## References

- cc65 documentation: https://cc65.github.io/doc/
- cc65 GitHub (active upstream): https://github.com/cc65/cc65
- Apple IIGS Toolbox Reference Volume 1: https://mirrors.apple2.org.za/ftp.apple.asimov.net/documentation/programming/65816_gs/Apple%20IIGS%20Toolbox%20Reference%20Volume%201.pdf
- GSplus emulator: https://github.com/digarok/gsplus
- KEGS emulator: https://www.kegstoys.com/
