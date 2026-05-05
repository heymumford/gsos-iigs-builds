# Fitness Functions — Atomic, Compound, Time-Series

Per the project North Star: every quality measurement is a fitness function returning a deterministic [0.000 ... 1.000] score, computed by comparing observed reality to an industry or internal baseline. Phase scripts emit **atomic** datums; `compute.sh` aggregates them into **compound** phase scores; the append-only NDJSON log is the **time-series**.

This replaces the bare exit-0/1/2 model. Exit codes remain (for shell-level gating) but are derived from the compound score, not from ad-hoc counters.

## Atomic datum

One JSON object per line, appended to `data/fitness-history.ndjson` (gitignored, running log):

```json
{
  "ts": "2026-05-05T10:00:00Z",
  "phase": "2",
  "metric": "phase2.cc65_present",
  "raw": 1,
  "unit": "bool",
  "baseline": {"value": 1, "source": "cc65 v2.19+ is the current stable line ..."},
  "weight": 0.2,
  "normalized": 1.000
}
```

### Fields

| Field | Meaning |
|---|---|
| `metric` | dotted name `<phase>.<measurement>` |
| `raw` | observed value (numeric) |
| `unit` | `bool` \| `semver` \| `exit_code` \| `seconds` \| `bytes` \| `count` |
| `baseline.value` | reference value from `data/industry-baselines.json` |
| `baseline.source` | one-sentence rationale + citation key |
| `weight` | contribution to compound score (0.0 ... 1.0) |
| `normalized` | `_normalize(unit, raw, baseline)` returning [0.000 ... 1.000] |

## Normalization rules

| Unit | Rule |
|---|---|
| `bool` | 1.000 if raw equals baseline, else 0.000 |
| `exit_code` | 1.000 if raw is 0, else 0.000 |
| `semver` | 1.000 if raw >= baseline; else `raw / baseline` |
| `seconds`, `bytes`, `count` | lower-is-better — 1.000 if raw <= baseline; else `baseline / raw` clamped to [0,1] |

## Compound (per phase)

```
compound_phase_N = Σ(atomic_normalized × weight) / Σ(weight)
```

Computed by `tools/fitness/compute.sh`, written to `data/fitness-snapshot.json` (committed snapshot of the latest compound state). Run after a phase script finishes.

## Time-series

`data/fitness-history.ndjson` is the append-only log. Each phase invocation appends new lines. `compute.sh` takes the most-recent atomic per `(phase, metric)`. Trends, moving averages, and convergence checks come from the log directly via `jq` queries.

The history file is gitignored — too noisy to commit. The snapshot is committed so reviewers can see the latest score without running anything.

## Industry baselines

`data/industry-baselines.json` — citation-bearing reference document. Each baseline has `metric`, `value`, `unit`, `source` (one-sentence rationale), and `citation` (URL or doc path). Updated when industry standards shift; never silently changed. Adding a baseline is a documented decision, not a config tweak.

## Usage in a phase script

```bash
# In phases/phase2-toolchain.sh
# shellcheck source=../tools/fitness/emit.sh
source "$(dirname "$0")/../tools/fitness/emit.sh"

# After detecting cc65:
fitness_emit "2" "phase2.cc65_present" 1 "bool" "0.20"

# After version check:
fitness_emit "2" "phase2.cc65_version" 2.19 "semver" "0.15"

# After compile test:
fitness_emit "2" "phase2.apple2enh_compile" 0 "exit_code" "0.20"
```

## Reading the snapshot

```bash
./tools/fitness/compute.sh
jq '.phases[] | {phase, compound: (.compound * 1000 | round / 1000)}' data/fitness-snapshot.json
```

Sample output:
```json
{"phase": "2", "compound": 0.875}
```

A compound of 1.000 means every atomic is at-or-above its baseline. Below 1.000 means at least one metric is degraded from the industry reference, weighted by importance. The number is comparable across runs and across hosts.

## Why this design

- **Determinism:** same inputs → same outputs. No timestamps in the score itself; the score is content-addressable for any (host, time) pair.
- **Comparability:** [0,1] is dimensionless. Compound scores from different phases can be compared, weighted, or rolled up further.
- **Time-series-friendly:** every measurement is logged. Convergence and regression are directly observable.
- **Citation discipline:** every baseline has a source. No silent magic numbers.
- **Composable:** atomic → compound → meta-compound (e.g., overall repo health = weighted average across phases).

## What still requires human judgment

Choosing weights, choosing baselines, deciding what to measure. The framework computes; humans decide what's worth computing. That's the contract.
