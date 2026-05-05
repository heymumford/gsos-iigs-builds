# Roadmap — gsos-iigs-builds

Fitness-function-driven build pipeline for Apple IIGS GS/OS, with the larger arc of cataloging the hobbyist 16-bit Apple OS ecosystem, exercising open-source toolchains, and recompiling GS/OS factory source (when supplied out-of-band).

Each slice closes on deterministic [0.000 ... 1.000] compound fitness scores, not vibes. The framework lives in `tools/fitness/`; baselines in `data/industry-baselines.json`. See `tools/fitness/README.md` for the contract.

## Status

| Slice | Tracks | State | Evidence |
|---|---|---|---|
| 1 — Scaffold | repo, README, phase stubs | done | PR #1 |
| 2 — cc65 (8-bit) | phase1, phase2-cc65, hello-world cc65, catalog (21 releases), phase5 emulator boot | done | PRs #2, #3, #4 |
| 2-extension | phase2-orca, hello-world-s16, ORCA install doc | merged this PR | this PR |
| 2-fitness | atomic + compound fitness framework, retrofit phase2-cc65 | merged this PR | this PR |
| 3 (next) | wave 2C (GSplus install + Phase 5 green), wave 3 (catalog/audit/bug-bash) | planned | see below |

## Toolchain choices

- **8-bit smoke path:** cc65 + ca65 + ld65 + cl65 targeting `apple2enh`. Fast, CI-friendly, low coverage of GS/OS surface.
- **16-bit S16 path (real GS/OS):** ORCA/C 2.2.1+ via Golden Gate. Native POSIX execution, produces type $B3 binaries. This is the path to "recompile GS/OS last factory."
- **Authentic legacy path (deferred):** APW on emulated IIGS. Slow, ground-truth oracle, future track.

See `docs/toolchain-paths.md` for details and `docs/install-orca.md` for ORCA + Golden Gate setup.

## Emulator stack

- Primary: GSplus (`digarok/gsplus`, SDL2, headless-capable).
- Fallback: KEGS (Kent Dickey, original).
- Oracle: MAME `apple2gs` driver (slowest, most accurate).

ROM and disk image are user-supplied via `$IIGS_ROM_PATH` and `$IIGS_DISK_IMAGE_PATH`. Apple IP is never committed; `.gitignore` enforces it.

## Wave 3 plan (after this PR merges)

Three parallel tracks, dispatchable as 3-wide wave (within local subagent cap) or via comms fleet to remote executors:

- **3A — GSplus install + Phase 5 green.** Install GSplus on POSIX host. Run `phases/phase5-emulator-boot.sh` against a user-mounted GS/OS 6.0.1 disk image. Document exact env-var contract.
- **3B — GS/OS recompile harness.** `scripts/recompile-gsos.sh` reads `$GSOS_SOURCE_PATH`. Never commits Apple IP. Validates ORCA path against real kernel source.
- **3C — OSS hobbyist binary disassembly inventory.** Open-source projects only (Marinetti, ORCA/C runtime, GNO/ME). Output lives outside the repo. `data/disassembly-inventory.json` records what was disassembled and where.

## Wave 4 plan (after wave 3)

- **4A — Adversarial bug-bash.** `tools/bug-bash-65816.py` matchers for known 65816 footguns: 8/16-bit accumulator mode confusion, direct-page register issues, stack-frame management. Run against disassembled OSS source.
- **4B — Upstream contributions.** Pick one finding from 4A or one open issue in `digarok/gsplus`. Submit upstream PR. Document in `docs/upstream-contributions.md`.
- **4C — Iterate.** Repeat 4A on the next batch from `data/catalog.json`. Stop when no new findings on three consecutive iterations or a wall-clock budget is exhausted (whichever first). No "until flawless" recursion.

## Stop conditions (project-wide)

- Each track closes on a binary green/red exit derived from the compound fitness score.
- Bound to 3 iterations per track unless explicitly extended.
- Closed-source disassembly: personal-study scope only — never commit output to the public repo.
- Apple GS/OS source, IIGS ROM, GS/OS disk images: never committed under any circumstance.

## Cross-cutting invariants

See `docs/decisions.md` for the decision log. Highlights:

1. Apple IP boundary is absolute.
2. ORCA/Golden Gate is the authoritative 16-bit path; cc65 is a smoke harness.
3. OSS emulators are audited and contributed to upstream — not reverse-engineered.
4. Fitness scores are deterministic [0.000 ... 1.000] compound averages; exit codes derive from thresholds.
5. No AI attribution. POSIX terminology only.
