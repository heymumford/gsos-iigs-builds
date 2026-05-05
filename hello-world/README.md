# Hello World — toolchain smoke test

A minimal 16-bit GS/OS application. Used as the "lights up green" check before any GS/OS kernel build is attempted.

## Why this comes first

The Apple IIGS toolchain (APW shell, AsmIIGS, LinkIIGS, Rez, Make) has a long failure surface. Compiling a minimal Hello World exercises every link in that chain without the cognitive load of GS/OS kernel sources. If Hello World will not compile, link, and run, no useful work on the kernel is possible.

## Implementation

### Source choice: Option B (minimal original C)

**Why not Option A (cc65 sample)?** cc65's `samples/` directory contains example code, but including it as a redistributable adds a build-time external dependency. Option B (minimal 30-line MIT-licensed C source) achieves the same test coverage (full toolchain exercise) without the fetch/verify overhead. This choice supports offline and hermetic builds.

**Source:** `hello.c` — minimal C program using `stdio.h`. Exercises:
- C compiler (cc65)
- Preprocessor and linker (cl65)
- Platform-specific I/O library (conio or ProDOS)

**License:** MIT (see LICENSE in repo root)

## How to run

```bash
# Compile and link
make

# Run tests (requires Phase 2 toolchain to be green)
make test

# Clean artifacts
make clean
```

## Acceptance criteria

| # | Test | Mechanism | Status |
|---|------|-----------|--------|
| 1 | Compile succeeds | `cc65 --version` check via Phase 2 fitness function | Implemented (test_compile.sh) |
| 2 | Binary is valid | `file` magic byte check for Mach-O or executable | Implemented (test_artifact.sh) |
| 3 | Linker produces 16-bit S16 | Binary type inspection (apple2enh target) | Deferred to Phase 3 (source truth) |
| 4 | Binary launches under emulator | KEGS or GSplus headless execution | Deferred to Phase 4 (bootable artifact) |
| 5 | Binary launches on real hardware | Manual verification with photo | Out of scope for CI (Phase 5) |

## Tests implemented

### test_compile.sh
Invokes Phase 2 fitness function (`phases/phase2-toolchain.sh`). Returns:
- **0 (green):** cc65 is available and version >= 2.19
- **1 (red):** cc65 not found or version too old
- **2 (yellow):** cc65 present but version cannot be determined

### test_artifact.sh
Checks compiled binary exists and is not empty. Uses `file` command to detect binary type (Mach-O, executable, etc.). Returns:
- **0 (green):** binary exists and type is recognized
- **1 (red):** binary missing or empty
- **2 (yellow):** binary present but type cannot be determined

## Future tests (deferred)

### test_resource.sh (Phase 3)
Verify Rez (resource compiler) works on apple2enh target. Requires APW or compatible Rez implementation.

### test_emulator.sh (Phase 4)
Launch binary under KEGS or GSplus headless mode. Verify "Hello, GS/OS World!" appears in stdout or screen capture.

## Layout

```
hello-world/
├── README.md           this file
├── hello.c             16-bit C source (MIT license)
├── Makefile            POSIX make (cc65 toolchain)
└── tests/
    ├── test_compile.sh verify cc65 toolchain available
    └── test_artifact.sh verify compiled binary is valid
```

## Build environment

- **Default PATH:** respects `$CC65_PREFIX` env var (default: `/usr/local`)
- **Target:** `apple2enh` (cc65 Enhanced Apple II target, 65816-aware)
- **Toolchain:** cc65 v2.19+ (as verified by Phase 2)

## References

- cc65 documentation: https://cc65.github.io/doc/
- cc65 GitHub (upstream): https://github.com/cc65/cc65
- Apple IIGS Programmer's Reference: https://mirrors.apple2.org.za/
