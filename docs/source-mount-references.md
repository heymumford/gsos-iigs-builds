# Source and ROM Mount References

This document lists legitimate sources where users can obtain Apple IIGS software, documentation, and disk images to populate the environment variables required by this build system.

## Environment Variables

The build harnesses expect these mounts:

- `$GSOS_SOURCE_PATH` — GS/OS source code (if compiling from source)
- `$IIGS_ROM_PATH` — Apple IIGS ROM files (01, 03)
- `$IIGS_DISK_IMAGE_PATH` — GS/OS and application disk images

## Legitimate Source Repositories

### ftp.apple.asimov.net (Asimov Archive)

**URL:** https://mirrors.apple2.org.za/ftp.apple.asimov.net/

**Scope:** Historical Apple II and IIGS software archive, actively maintained with daily mirror sync. Contains disk images, utilities, documentation, and some reference materials.

**What's available:** Disk images, emulator distributions, Apple II documentation, development tools. Some GS/OS-related documentation and utilities.

**Access:** HTTP mirror (primary), original FTP site available via ftp.apple.asimov.net (if your network permits FTP).

### Internet Archive Apple IIGS Collections

**Primary collection:** https://archive.org/details/softwarelibrary_apple2gs

**TOSEC Collection:** https://archive.org/details/Apple_II_GS_TOSEC_2012_04_23

**Scope:** Over 1,100 disk images covering games, applications, educational software, and OS releases. Includes archived GSOS 6.0.1 source code.

**What's available:** Complete disk image library suitable for populating `$IIGS_DISK_IMAGE_PATH`. GS/OS 6.0.1 source archive available as separate collection.

**Access:** Browsable web interface; download individual or bulk archives.

### Juiced.GS — Byte Works Authorization Channel

**URL:** https://juiced.gs/store/category/software/

**Scope:** Authorized distribution channel for The Byte Works' ORCA development toolchain (ORCA/C, ORCA/M, ORCA/Pascal). Distributes complete Opus ][ package including compiler suite and documentation.

**What's available:** Licensed ORCA tools and related libraries. Source code for ORCA tools also available on GitHub at https://github.com/byteworksinc/ORCA-C (open source under Apache 2.0).

**Access:** Commercial subscription/purchase model; free open-source GitHub distribution for ORCA source.

## Legal Considerations

**User responsibility:** The user is solely responsible for compliance with applicable laws and licensing terms.

- **GS/OS source and ROMs remain Apple IP.** Distribution is restricted. Users must verify their own legal standing before obtaining these materials.
- **Abandonware and archive materials:** Legal status varies by jurisdiction. Materials in the Asimov archive and Internet Archive are preserved for historical and educational purposes; users must ensure their use complies with local law.
- **Licensed software:** Byte Works tools are commercially licensed. Juiced.GS and GitHub distributions carry their respective licenses (open source for GitHub ORCA distribution; commercial license for Juiced.GS distribution).

## Discovery Notes

As of 2026-05-05:
- No canonical "OpenGS" (open-source GS/OS reimplementation) repository found. A2osX is the closest public alternative OS effort for IIGS, but it is a Unix-like environment, not a GS/OS reimplementation.
- These sources represent the primary legitimate distribution and archival channels for IIGS software and documentation.
