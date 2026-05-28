# Legal and Ethics — Clean-Room Deconstruction

This document establishes the legal and ethical boundaries for public deconstruction of GS/OS and the Apple IIGS ecosystem. The project operates under established fair-use precedents and clean-room reimplementation doctrine.

## Fair Use and Reverse Engineering for Interoperability

**Sega v. Accolade (1992, 977 F.2d 1510)**

The Ninth Circuit held that reverse engineering of copyrighted software for the purpose of achieving interoperability is fair use. Accolade disassembled Sega's game cartridges to understand the console's authentication protocol — necessary to develop compatible software. The court recognized that:

- The purpose was transformative (interoperability research, not republication)
- The amount taken was necessary (only what was required to learn the interface)
- The market effect was neutral or positive (Accolade's games expanded the market)

This repo's deconstruction is similarly transformative: we publish annotations and behavioral models for education and interoperability research, not the copyrighted code itself.

## Clean-Room Reimplementation

**Sony v. Connectix (2000, 203 F.3d 596)**

The Federal Circuit held that clean-room emulation of a gaming console is fair use. Connectix reverse-engineered the Sony PlayStation to understand its behavior, then built an emulator without using Sony's protected code. The court distinguished:

- Access to the original (allowed for study)
- Copying the original (prohibited)
- Creating a compatible implementation (allowed, if done independently)

This repo's unlock extensions follow this doctrine: we study GS/OS published interfaces (Toolbox Reference, GS/OS Reference), then create net-new drivers and system extensions in ORCA/C, without copying Apple code.

## What This Repo Does

1. **Analyze** Apple GS/OS binaries and IIGS ROM via Ghidra, MAME, and GSplus
2. **Publish** callgraphs, behavioral models, API signatures, and memory maps
3. **Cite** every claim against either a public Apple reference or a specific observation
4. **Create** net-new code (drivers, FSTs, CDevs) targeting published Apple interfaces
5. **Never** redistribute Apple's binaries, source code, ROM images, or modifications thereof

## What This Repo Does Not Do

- Republish disassembled bytes or decompiled source from Apple binaries
- Distribute ROM images, GS/OS factory source, or disk images
- Modify Apple-protected system files or binaries
- Create complete reconstructions of Apple intellectual property
- Circumvent copyright or licensing without published fair-use precedent

## Contributor Guidelines

All contributions to this repository must satisfy:

1. **Provenance:** Net-new code or annotations of your own observation
2. **No verbatim Apple bytes:** No disassembled code, opcode sequences, or source snippets from Apple binaries
3. **Published interfaces only:** Extensions use only Apple's published Toolbox Reference, GS/OS Reference, and Programmer's Reference
4. **Citable claims:** Every behavioral assertion cites a public reference or a specific test
5. **Independent creation:** If inspired by existing source (OSS or otherwise), document the inspiration and confirm your code was written independently

## Open Questions and Limitations

- **Derivative analysis status:** While Sega v. Accolade and Sony v. Connectix favor reverse engineering for interoperability, fair use is determined case-by-case. A future dispute with Apple could test the boundaries of published annotations and callgraphs.
- **Jurisdiction:** Fair use is a U.S. doctrine. Readers in other jurisdictions (EU, Japan, etc.) should consult local counsel before republishing or modifying this repo's contents.
- **Scope creep:** Publishing detailed pseudocode or near-complete behavioral reconstruction (even if technically non-verbatim) courts legal risk. This repo prioritizes safety over completeness.

## Related References

- `docs/decisions.md` — D-009 (mission scope), D-010 (Ghidra tooling), D-011 (unlock extensions)
- `docs/deconstruct/methodology.md` — Publication standards and citation discipline
- `docs/deconstruct/unlock-targets.md` — Apple IIGS extension points (FSTs, drivers, CDevs)
- Apple IIGS Toolbox Reference Vol. 1–2 (canonical system interfaces)
- Apple GS/OS Reference (file system and device interfaces)
- Apple IIGS Programmer's Reference (memory, interrupt, and hardware details)
