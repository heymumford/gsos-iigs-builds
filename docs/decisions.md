# Decision Log — gsos-iigs-builds

ADR-style log of decisions that bind the project. Each entry has context, decision, and consequence. Updates require a new entry; never edit history silently.

## D-001 — Apple IP stays out of the repo (absolute)

**As of:** 2026-05-05

**Context.** GS/OS 6.0.x source code, the Apple IIGS ROM (01 / 03), and GS/OS disk images are Apple intellectual property. The leak history of GS/OS source is widely known; the legal status of redistribution is not.

**Decision.** This repository contains build infrastructure only — Makefiles, fitness functions, scripts, documentation. Apple-owned source, ROMs, and disk images are never committed. Build harnesses read them from user-supplied mount points (`$GSOS_SOURCE_PATH`, `$IIGS_ROM_PATH`, `$IIGS_DISK_IMAGE_PATH`). `.gitignore` enforces this with explicit entries for `roms/`, `disk-images/`, `sources/`, `includes/`, `libraries/`, `GS_OS_Source/`, `*.rom`, `*.po`, `*.2mg`, `*.dsk`.

**Consequence.** A clone of this repo is not sufficient to compile GS/OS — the user must mount source out-of-band. That is by design.

## D-002 — ORCA/C + Golden Gate is the authoritative 16-bit path

**As of:** 2026-05-05

**Context.** cc65 was the obvious POSIX cross-compile candidate for slice 2. Investigation in slice 2 (catalog research, PR #3) surfaced that ORCA/C — the canonical Byte Works compiler for the Apple IIGS — is open source on GitHub (`byteworksinc/ORCA-C`) and has shipped C17 support as recently as 2023. Kelvin Sherlock's Golden Gate (`ksherlock/golden-gate`) is a compatibility layer that runs ORCA tools natively on POSIX hosts. Together they produce real S16 binaries (file type $B3) — the same format the Apple IIGS hardware loads.

**Decision.** ORCA/C via Golden Gate is the authoritative 16-bit path for GS/OS-targeted code, including any future "recompile GS/OS factory source" track. cc65 is retained only as an 8-bit `apple2enh` smoke test that exercises basic toolchain plumbing.

**Consequence.** Phase 2 splits into two scripts: `phase2-toolchain.sh` (cc65) and `phase2-orca.sh` (ORCA + Golden Gate). Both must be green before slice 3 starts.

## D-003 — OSS emulators are audited and contributed to, not reverse-engineered

**As of:** 2026-05-05

**Context.** GSplus, KEGS, and MAME's `apple2gs` driver are all open-source, source-available projects. The original brief used the language "reverse engineer the emulator," which conflates closed-box analysis with what the situation actually requires.

**Decision.** No reverse engineering of OSS emulators. Findings flow as upstream pull requests to the canonical project (`digarok/gsplus`, `mamedev/mame`, etc.) per each project's contribution policy. Local audits live in this repo as documentation; code changes live upstream.

**Consequence.** Faster turnaround, legitimate maintainer relationship, no fork drift. We document upstream contributions in `docs/upstream-contributions.md` (added when the first PR lands).

## D-004 — Closed-source hobbyist disassembly is personal-study scope only

**As of:** 2026-05-05

**Context.** Some Apple IIGS hobbyist software (commercial freeware, abandonware) is distributed only as binaries. Disassembly for personal study, interoperability research, and bug investigation is generally permissible under fair use. Public redistribution of the disassembly output is murkier and varies by jurisdiction.

**Decision.** Disassembly of closed-source IIGS binaries is permitted for personal study only. Disassembly output is never committed to this public repository. `tools/disassemble.sh` (when added) writes to a path outside the repo by default.

**Consequence.** `data/disassembly-inventory.json` (when added) catalogs what was disassembled and where it lives — but the artifacts themselves stay off GitHub.

## D-005 — Fitness scores are deterministic [0.000 ... 1.000] compounds

**As of:** 2026-05-05

**Context.** The original phase scripts emitted exit codes 0 (green) / 1 (red) / 2 (yellow) plus key=value stdout. That is too coarse — it cannot distinguish "everything passes" from "everything passes, but cc65 is on an old version" from "we didn't even run the check." Per the project North Star, we want fast, real-time, deterministic, time-series-friendly quality measurements.

**Decision.** Every quality measurement is now an atomic fitness datum (NDJSON line in `data/fitness-history.ndjson`) carrying `raw`, `unit`, `baseline.value`, `baseline.source`, `weight`, and `normalized` (in [0.000, 1.000]). Compound phase scores are weighted averages computed by `tools/fitness/compute.sh` and snapshotted to `data/fitness-snapshot.json`. Exit codes remain — they derive from compound thresholds (`compound >= 0.95` → green; `>= 0.5` → yellow; `< 0.5` → red).

**Consequence.** The framework lives in `tools/fitness/`. Baselines live in `data/industry-baselines.json` with a citation per metric. Phase scripts source `tools/fitness/emit.sh` and call `fitness_emit` per check. The retrofit to existing phases (phase1, phase2-cc65, phase2-orca, phase5) is incremental — phase2-cc65 is the first retrofit in this PR.

## D-006 — No "until flawless" recursion; bounded iterations only

**As of:** 2026-05-05

**Context.** Open-ended directives like "iterate like a Mandelbrot set until flawless" are not executable stop conditions. They produce inflation, drift, and analysis paralysis.

**Decision.** Each track closes on a binary green/red derived from the compound fitness score. Each track is bounded to 3 iterations unless explicitly extended in a new decision entry. Wave 4 has an additional wall-clock budget (7 days of fleet wall-clock) as a hard ceiling.

**Consequence.** `tools/fitness/compute.sh` and the snapshot are the canonical "are we there yet?" instrument. Conversation cannot extend a track; only a new decision entry can.

## D-007 — Industry baselines must be cited

**As of:** 2026-05-05

**Context.** A normalized score is meaningful only if the baseline is real. Magic numbers without citations are inflation.

**Decision.** Every entry in `data/industry-baselines.json` carries `source` (one-sentence rationale) and `citation` (URL or doc path). Baselines are updated by editing the file with a new ADR entry; never silently changed. New atomic metrics added to a phase script require a new baseline before the metric can be emitted.

**Consequence.** PR review checks the baselines file as carefully as it checks code. A baseline without a citation blocks merge.

## D-008 — OpenGS is adjacent reference, not a contribution target

**As of:** 2026-05-05

**Context.** Reconnaissance of the IIGS ecosystem flagged "OpenGS" as a potential open-source reimplementation of GS/OS. Investigation found no canonical OpenGS repository (seanpm2001/WacOS_OpenGS is meme-tier placeholder). The closest public alternative OS effort is A2osX — a multi-tasking Unix-like environment for II, IIc, and IIGS — but it is not a GS/OS reimplementation.

**Decision.** GS/OS reimplementation is not in scope for gsos-iigs-builds. This repo focuses on compiling the original GS/OS source on period hardware (with modern toolchains as a bridge). Alternative OS projects (A2osX, GNO, etc.) are adjacent reference only and are documented in `data/catalog.json` for researcher awareness. This repo does not contribute to or fork alternative OS efforts.

**Consequence.** `data/catalog.json` catalogs historical and contemporary IIGS ecosystem sources. Legitimate source repositories (Asimov archive, Internet Archive, Juiced.GS distribution) are documented in `docs/source-mount-references.md` for user self-service. Alternative OS efforts appear in the catalog with clear scope boundaries ("not a GS/OS reimplementation").

## D-009 — Mission scope: clean-room deconstruction + net-new extensions, never modification of Apple binaries

**As of:** 2026-05-05

**Context.** The project mission has expanded beyond "fitness-function-driven compilation" to encompass two new pillars: (a) clean-room public deconstruction of GS/OS for researcher and hobbyist education, and (b) net-new extensions (drivers, FSTs, init files, system extensions) that unlock hardware capabilities on the Apple IIGS. The scope boundary must be clear: what gets published, what never does, and the legal framing behind both.

**Decision.** This repository publishes annotations, callgraphs, behavioral models, methodology, and our own net-new code. This repository never publishes redistributed disassembly bytes, ROM files, factory GS/OS source, or modifications to Apple-protected binaries. The project operates under fair-use doctrine for personal study and clean-room reimplementation — citing precedents Sega v. Accolade (1992, reverse engineering for interoperability) and Sony v. Connectix (2000, clean-room emulation).

**Consequence.** Two new documentation files establish the methodology (`docs/deconstruct/methodology.md`) and legal frame (`docs/deconstruct/legal-and-ethics.md`). Contributor guidelines require net-new code or annotations of personally-conducted observation; verbatim Apple byte sequences are prohibited. The discipline is called "tolerant publication" — we publish what we learned, not what we copied.

## D-010 — Ghidra is the chosen world-class disassembly + decompilation tool

**As of:** 2026-05-05

**Context.** Deconstruction of GS/OS and the Apple IIGS ecosystem requires a production-grade disassembly and decompilation framework. The space has three candidates: Ghidra (NSA, Apache-2.0, actively maintained, community 65816 support), Capstone (single-instruction dissection, language bindings, limited decompiler), and MAME `apple2gs` driver (cycle-accurate execution oracle, slow, read-only). Each serves distinct roles; Ghidra is the primary analysis platform.

**Decision.** Ghidra is the chosen primary disassembly and decompilation tool. The community-contributed 65816 SLEIGH processor module (search GitHub for `ghidra 65816` or check SleighDevs for the canonical entry) is battle-tested on GS/OS binaries and Apple IIGS object code. Capstone is the secondary instruction-level dissector (when byte-by-byte labeling is required). MAME `apple2gs` driver is the dynamic-execution oracle (verification only, not analysis primary). Ghidra's headless mode integrates with CI; decompiler output is publishable as derivative annotation under fair use.

**Consequence.** `docs/deconstruct/methodology.md` documents the toolchain contract: Ghidra for static analysis, MAME for trace capture, GSplus debugger for interactive inspection. Workflow examples and baseline annotations live in `tools/deconstruct/`. The 65816 SLEIGH module is documented in a wiki page or `.md` reference inside `docs/deconstruct/` with installation and module-loading instructions.

## D-011 — "Unlock" extensions are net-new code only — drivers, FSTs, init files, system extensions, CDevs

**As of:** 2026-05-05

**Context.** The Apple IIGS hardware (Ensoniq sound synthesizer, SuperHires video mode, GPI interrupt controller, accelerator cards like TransWarp and Zip) contains capabilities that the factory GS/OS ROM may not fully expose. Net-new drivers, file system translators (FSTs), system extensions, and control panel extensions (CDevs) can unlock this hardware without modifying Apple-protected system binaries. The architecture is well-documented in official Apple references.

**Decision.** "Unlock" extensions are net-new Byte Works ORCA/C code written against the published Apple IIGS Toolbox and GS/OS interfaces. Legal unlock targets: `*/SYSTEM/DRIVERS/` (drivers for hardware interfaces), `*/SYSTEM/FSTs/` (file system translators), `*/SYSTEM/EXTENSIONS/` (system extensions and init files), `*/SYSTEM/CDEVS/` (control panel extensions). Modifications to Apple-supplied binaries, system files, or ROM images are prohibited. The canonical reference is Apple IIGS Toolbox Reference Vol. 2 (Chapter on System Extensions) and GS/OS Reference Vol. 1 (Chapters on FSTs and Device Drivers).

**Consequence.** `docs/deconstruct/unlock-targets.md` maps the extension points and cites the Apple reference by chapter and section. Exemplar projects: accelerator-detection driver (probing for TransWarp GS / Zip GS registers), SuperHires video FST stub (proof-of-concept), and a simple CPanel extension (system metrics display). Each exemplar is standalone net-new code that compiles with ORCA/C and requires no modifications to Apple system binaries.
