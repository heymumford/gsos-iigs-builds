# Apple IIGS Emulator Setup

This document describes the emulator stack for Phase 5 boot testing on POSIX hosts (including Apple Silicon m4max).

## Emulator Priority

### Primary: GSplus

**GSplus** is David Schmidt's modern fork of KEGS (Kent Dickey). It is actively maintained, performant, and supports headless (SDL2) rendering.

- **Repository:** https://github.com/GOFAI/gsplus
- **License:** GPL (source); binary redistributable under GPL terms
- **Availability:** Homebrew (`brew install gsplus`), or build from source on POSIX
- **Install (Homebrew):**
  ```bash
  brew tap gofai/gofai
  brew install gsplus
  ```
- **Version pin:** v0.26+ (verified 2026-05-05)
- **Headless mode:** `-video headless` flag + SDL2 backend
- **ROM mount:** CLI `-s5 <path>` (Slot 5 = ROM card); ROM file must be 128KB or 256KB
- **Disk mount:** CLI `-d1 <path>` (Disk 1 = primary 3.5" slot)
- **Example boot:**
  ```bash
  export IIGS_ROM_PATH="/path/to/rom.bin"
  export IIGS_DISK_IMAGE_PATH="/path/to/gsos.po"
  gsplus -d1 "$IIGS_DISK_IMAGE_PATH" -s5 "$IIGS_ROM_PATH" -video headless
  ```

### Fallback: KEGS (Original)

**KEGS** is Kent Dickey's original Apple IIGS emulator. POSIX build available; no active maintenance.

- **Repository:** https://sourceforge.net/projects/kegs/
- **License:** GPL (source)
- **Availability:** Source distribution; compile from source on POSIX
- **Install (POSIX):**
  ```bash
  # Clone or download kegs source
  cd kegs/src
  ./make.depend
  make
  sudo cp kegs /usr/local/bin/
  ```
- **Version pin:** v1.30+ (last stable release, 2018)
- **Headless mode:** No native headless support; use timeout-based testing with output scraping
- **ROM mount:** Config file `config.kegs` or `-r <path>` CLI option (requires config file setup)
- **Disk mount:** Config file or `-d1 <path>` CLI
- **Note:** KEGS may display X11 window by default; use Xvfb or similar for CI headless testing

### Accuracy Oracle: MAME

**MAME** (`apple2gs` driver) is the reference accuracy emulator, maintained by the MAME project.

- **Repository:** https://github.com/mamedev/mame
- **License:** GPL-2.0 (source)
- **Availability:** Homebrew, pkg managers, or build from source
- **Install (Homebrew):**
  ```bash
  brew install mame
  ```
- **Version pin:** v0.259+ (verified 2026-05-05)
- **Headless mode:** `-nodisplay -skip_gameinfo` flags
- **ROM mount:** MAME ROM database; requires ROM files in `~/.mame/roms/apple2gs/` directory or config-specified path
- **Disk mount:** `-d1 <path>` (primary slot)
- **Example boot:**
  ```bash
  export IIGS_ROM_PATH="~/.mame/roms/apple2gs/rom.bin"
  mame apple2gs -d1 "$IIGS_DISK_IMAGE_PATH" -nodisplay -skip_gameinfo
  ```
- **Use case:** Verify compatibility across authoritative hardware behavior

## ROM File Conventions

**DO NOT commit ROM files to this repository.** Apple IIGS ROM 01 and ROM 03 are Apple intellectual property.

### User-supplied ROM file

Set the `IIGS_ROM_PATH` environment variable to point to a user-supplied ROM file:

```bash
export IIGS_ROM_PATH="$HOME/Library/IIGS/rom01.bin"
```

The ROM file must be:
- 128KB (for ROM 01) or 256KB (for ROM 03)
- Byte-accurate to the original Apple IIGS ROM dump
- Readable by the emulator and the running user

### Directory structure (recommended)

```
~/.local/iigs-roms/           # or ~/Library/IIGS/ on macOS
├── rom01.bin                 # ROM 01 (128KB)
└── rom03.bin                 # ROM 03 (256KB)
```

Then:
```bash
export IIGS_ROM_PATH="$HOME/.local/iigs-roms/rom01.bin"
```

## Disk Image Conventions

### User-supplied GS/OS boot image

Set the `IIGS_DISK_IMAGE_PATH` environment variable to point to a user-supplied GS/OS disk image:

```bash
export IIGS_DISK_IMAGE_PATH="$HOME/disk-images/gsos-6.0.1.po"
```

The disk image must be:
- ProDOS format (`.po`) or 2IMG format (`.2mg`)
- Contain a bootable GS/OS installation
- Readable by the emulator and the running user

### Directory structure (recommended)

```
~/.local/iigs-disks/          # or ~/Library/IIGS/ on macOS
├── gsos-6.0.1.po             # ProDOS format
└── gsos-6.0.1.2mg            # 2IMG format (alternative)
```

Then:
```bash
export IIGS_DISK_IMAGE_PATH="$HOME/.local/iigs-disks/gsos-6.0.1.po"
```

### Obtaining a GS/OS boot image

GS/OS 6.0.x source code and pre-built disk images are Apple intellectual property. Contact Apple or consult community resources (e.g., apple2history.org) for legitimate acquisition paths.

## Gitignore Rules

The `.gitignore` file in this repository already excludes emulator artifacts:

```gitignore
*.rom        # ROM files
*.dsk        # Disk images (raw format)
*.po         # ProDOS format images
*.2mg        # 2IMG format images
```

Additionally, do NOT commit:
- The `roms/` directory (if it exists locally)
- The `disk-images/` directory (if it exists locally)
- Any symlinks to user-supplied ROM or disk paths

## Phase 5 Boot Test

The `phases/phase5-emulator-boot.sh` fitness function uses the following boot detection logic:

1. **GSplus:** Launches emulator with `-video headless` and checks stdout for "Finder", "desktop", or "boot complete" signals
2. **KEGS:** Launches emulator with timeout; checks stdout for boot indicators (heuristic)
3. **MAME:** Launches `apple2gs` driver with `-nodisplay`; checks stdout for "booting", "loaded", or "finder" signals

Boot is considered successful (exit 0) when:
- The emulator binary launches without crashing
- The ROM and disk image are accessible and valid
- The boot sequence completes within 60 seconds
- A "boot complete" or "Finder" signal is detected in emulator output (or heuristically inferred)

Boot fails (exit 1) when:
- The emulator crashes or exits with non-zero status
- The boot sequence times out (>60 seconds)
- No "boot complete" signal is detected

Ambiguous signals (yellow, exit 2) when:
- `$IIGS_ROM_PATH` is not set or not readable
- `$IIGS_DISK_IMAGE_PATH` is not set or not readable
- No emulator binary is found on PATH
- Emulator stdout is inconclusive

## References

- **GSplus repository:** https://github.com/GOFAI/gsplus
- **KEGS homepage:** https://sourceforge.net/projects/kegs/
- **MAME apple2gs driver:** https://github.com/mamedev/mame/tree/master/src/devices/bus/a2bus/
- **Apple IIGS Technical Reference:** https://apple2history.org/ (community archive)
- **ProDOS format:** https://www.apple.asimov.net/documentation/Disks/ProDOS_Technical_Reference.pdf
- **2IMG disk format:** https://www.apple.asimov.net/documentation/Disks/
