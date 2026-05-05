# Installing ORCA/C and Golden Gate

This document covers installation of the ORCA/C compiler and the Golden Gate compatibility layer on POSIX hosts (macOS, Linux, BSD).

## What is Golden Gate?

Golden Gate is a compatibility layer created by Kelvin Sherlock that allows ORCA command-line tools (ORCA/C, ORCA/M, ORCALib) to run natively on modern POSIX systems (macOS, Linux, Windows via WSL). It bridges the gap between retro IIGS development tools and contemporary build infrastructure.

**Official documentation:** https://golden-gate.ksherlock.com/

## Install Golden Gate

### Option 1: Homebrew (macOS, Linux with Homebrew)

Check if a community tap is available:

```bash
brew search golden-gate
```

If a tap exists (e.g., `ksherlock/golden-gate`), install via:

```bash
brew tap ksherlock/golden-gate
brew install golden-gate
```

Verify:

```bash
iix --version
```

### Option 2: Build from Source

Clone the upstream repository:

```bash
git clone https://github.com/ksherlock/golden-gate.git
cd golden-gate
```

Follow the build instructions in the repository README. Typical POSIX build:

```bash
./configure
make
sudo make install
```

Verify:

```bash
iix --version
```

## Install ORCA/C

ORCA/C can be installed in two ways:

### Option 1: Pre-built Binaries (Simplest)

Download the latest stable ORCA/C release from:

https://github.com/byteworksinc/ORCA-C/releases

Extract the archive to a standard location:

```bash
mkdir -p ~/.local/orca
cd ~/.local/orca
tar -xzf ORCA-C-<version>.tar.gz
```

### Option 2: Build from Source

Clone the ORCA/C repository:

```bash
git clone https://github.com/byteworksinc/ORCA-C.git
cd ORCA-C
```

Build the compiler (requires a C compiler and standard POSIX tools):

```bash
make
```

Install to a standard location:

```bash
mkdir -p ~/.local/orca
cp -r bin/* ~/.local/orca/
```

### Option 3: Use Golden Gate's Integration

If ORCA/C is pre-installed on your system in a standard location (e.g., `/usr/local/orca` or `~/orca`), Golden Gate can discover it automatically. Set the environment variable:

```bash
export ORCA_HOME=$HOME/.local/orca
```

## Configure Environment

Add ORCA/C binaries to your PATH:

```bash
export PATH=$HOME/.local/orca/bin:$PATH
```

Add this to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) to persist:

```bash
# ORCA/C and Golden Gate
export ORCA_HOME=$HOME/.local/orca
export PATH=$ORCA_HOME/bin:$PATH
```

## Verify Installation

Test that Golden Gate can invoke ORCA tools:

```bash
# Test Golden Gate itself
iix --version

# Test ORCA/C compiler
iix cc --version

# Test ORCA/M assembler
iix asm --version

# Test ORCALink linker
iix link --version
```

If all commands succeed, you are ready to compile IIGS applications.

## Testing the Fitness Function

Run the Phase 2 (ORCA variant) fitness function:

```bash
bash phases/phase2-orca.sh
```

Expected output on a correctly configured system:

```
[phase2-orca] iix (Golden Gate): found (pass)
[phase2-orca] ORCA/C (cc): callable via iix (pass)
[phase2-orca] ORCA/M (asm): callable via iix (pass)
[phase2-orca] ORCALink (link): callable via iix (pass)
[phase2-orca] Sanity compile: 5-line C program compiled (pass)
[phase2-orca] Phase 2 (ORCA) result: GREEN (all checks pass)
```

Exit code 0 indicates success.

## References

- Golden Gate compatibility layer: https://golden-gate.ksherlock.com/
- Golden Gate GitHub: https://github.com/ksherlock/golden-gate
- ORCA/C repository: https://github.com/byteworksinc/ORCA-C
- ORCA/C releases: https://github.com/byteworksinc/ORCA-C/releases
- ORCALib (standard library for ORCA languages): https://github.com/byteworksinc/ORCALib
