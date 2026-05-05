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

## Path B: APW on Emulated or Real IIGS

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

## V1 Strategy: cc65 as CI Default, APW as Future Separate Track

**Rationale:**
1. **Velocity:** cc65 ships immediately in CI. Hello World compiles in seconds, not minutes.
2. **Reversibility:** cc65 phases are completely decoupled from APW infrastructure. They can coexist.
3. **Learning:** Phase 1 + 2 will expose what cc65 cannot express (if anything). Phase 3 (source truth) and Phase 4 (bootable artifact) will reveal the cost of divergence.
4. **Compatibility:** Both paths use the same source tree. Conditional compilation (e.g., `#ifdef __CC65_FOR_IIGS__`) can bridge differences without forking the codebase.

**Next phases (slice 3+):**
- Phase 3 (Source Truth) remains CC65-agnostic: it tests source properties (encoding, line endings, includes) that are toolchain-independent.
- Phase 4 (Bootable Artifact) will be cc65-specific for v1, deferred to a separate `phases/phase4-*-apw.sh` variant once APW infrastructure is available.
- APW-based phases can be added as `phases/phase1-hardware-apw.sh`, `phases/phase2-toolchain-apw.sh`, etc., running in parallel once emulator tooling is stable.

## References

- cc65 documentation: https://cc65.github.io/doc/
- cc65 GitHub (active upstream): https://github.com/cc65/cc65
- Apple IIGS Toolbox Reference Volume 1: https://mirrors.apple2.org.za/ftp.apple.asimov.net/documentation/programming/65816_gs/Apple%20IIGS%20Toolbox%20Reference%20Volume%201.pdf
- GSplus emulator: https://github.com/digarok/gsplus
- KEGS emulator: https://www.kegstoys.com/
