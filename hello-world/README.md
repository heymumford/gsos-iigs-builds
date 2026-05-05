# Hello World — toolchain smoke test

A minimal 16-bit GS/OS application. Used as the "lights up green" check before any GS/OS kernel build is attempted.

## Why this comes first

The Apple IIGS toolchain (APW shell, AsmIIGS, LinkIIGS, Rez, Make) has a long failure surface. Compiling a 50-line Hello World exercises every link in that chain without the cognitive load of GS/OS kernel sources. If Hello World will not compile, link, and run, no useful work on the kernel is possible.

## Acceptance (TDD targets)

| # | Test | Mechanism |
|---|------|-----------|
| 1 | Source assembles without error | AsmIIGS exit 0 + zero unresolved externals in `.OBJ` |
| 2 | Linker produces a 16-bit `S16` (Application) executable | `LinkIIGS` exit 0 + file type `$B3 / $0000` |
| 3 | Resource compile produces a valid `.r` resource fork | `Rez` exit 0 + non-empty resource fork |
| 4 | Binary launches under emulator | KEGS or GSplus headless, exit code or screen scrape detects "Hello, World" |
| 5 | Binary launches on real hardware (manual gate) | Photo of the screen attached to a release |

Tests 1–4 are CI-runnable. Test 5 is a manual milestone.

## Layout (planned)

```
hello-world/
├── README.md           this file
├── hello.asm           65816 source
├── hello.r             Rez resource source
├── Makefile            APW Make (initial); a portable POSIX wrapper may follow
└── tests/
    ├── test_assemble.sh
    ├── test_link.sh
    ├── test_resource.sh
    └── test_emulator.sh
```

Status: scaffolding only. Source, Makefile, and tests are not yet written.
