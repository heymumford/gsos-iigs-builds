# Fitness Function Phases

Each phase script exits 0 (green) when its invariants hold, non-zero (red) when they fail. A red phase blocks the next.

| # | Script | Invariant |
|---|--------|-----------|
| 1 | `phase1-hardware.sh` | Build host has the RAM, storage, and shell to self-host an OS build |
| 2 | `phase2-toolchain.sh` | AsmIIGS, LinkIIGS, Rez, and Make are present and correct version |
| 3 | `phase3-source-truth.sh` | Source encoding, line endings, includes, and libraries align |
| 4 | `phase4-bootable.sh` | Compiled artifact is a working 800K boot disk |

## Convention

- Exit 0: green (invariant holds)
- Exit 1: red (invariant fails — actionable; print what's missing)
- Exit 2: yellow (instrument cannot answer — e.g., script can't see emulator state)
- All output to stderr is human; stdout is machine (one fact per line, `key=value`)

## Run all

```sh
for p in phases/phase[1-4]-*.sh; do
  echo "=== $p ==="
  "$p" || { echo "RED at $p"; exit 1; }
done
```

## Status

All four scripts are stubs — they print their intent and exit 2 (yellow). Implementation is the next slice.
