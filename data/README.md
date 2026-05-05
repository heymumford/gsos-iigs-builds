# GS/OS hobbyist software catalog

Local data store for the hobbyist 16-bit Apple OS / GS/OS extension ecosystem.
Foundation for downstream slices that smoke-test compiles, audit binaries, and
contribute upstream.

## Files

- `catalog.json` - JSON array, one object per release. Living document.
- `README.md` - This file. Schema, method, contribution rules.

## Schema

Each entry is an object with these fields:

| Field | Type | Notes |
|-------|------|-------|
| `name` | string | Canonical project name |
| `category` | enum | `tcp_ip_stack`, `os_extension`, `shell`, `utility`, `demoscene`, `dev_tool`, `filesystem`, `network` |
| `author` | string | Original author and any current maintainer in parentheses |
| `latest_version` | string | `"unknown"` if not surfaced by a citation |
| `latest_date` | string | ISO 8601 date or `"unknown"` |
| `license` | enum | `freeware`, `gpl`, `mit`, `bsd`, `proprietary`, `abandonware`, `unknown` |
| `source_available` | bool | `true` only when a citation points to source |
| `source_url` | string | Canonical source URL or `"unknown"` |
| `binary_url` | string | Download URL or `"unknown"` |
| `function_added` | string | What the project contributes to the GS/OS ecosystem |
| `depends_on` | array | Listed dependencies (e.g., `["GS/OS 6.0.1+"]`) |
| `still_maintained` | bool | True only when commits / releases since 2020 are observable |
| `citations` | array | Every URL used to populate the entry; required |

## Validation

```bash
jq . data/catalog.json    # must succeed; format gate
jq '. | length' data/catalog.json
```

## Research method

For each target, in order:

1. `mcp__context7__resolve-library-id` with `libraryName` and `query`. Hit -> `query-docs`.
2. `mcp__brave-search__brave_web_search` with targeted queries (e.g., `"Marinetti" Apple IIGS site:github.com`).
3. `WebFetch` against the canonical project page if neither prior tier yields a citation.
4. Every URL used in the decision is recorded in the entry's `citations` array.

## Voice rules (mandatory)

- Declarative voice ONLY for facts sourced from a citation.
- Inferences use conditional voice ("appears to be", "may be").
- Unknown values -> `"unknown"`, never invented.
- `still_maintained: true` requires observable post-2020 activity; otherwise `false`.
- `latest_date` accepts ISO 8601 (`YYYY-MM-DD`), partial dates (`2014-01-XX`), or `"unknown"`. No invented day-precision.

## Cataloged in this slice (21)

Marinetti, GNO/ME, ORCA/C, ORCA/Pascal, ORCALib, Merlin32, Cadius, Golden
Gate, Spectrum, ProTERM, HyperStudio, The Manager, GS-ShrinkIt,
Apple2GSBuildPipeline, KEGS, GSplus, GSport, MAME apple2gs driver, GSCII,
Ninjaforce demoscene tools, KansasFest.

## Deferred to a future slice

The following targets from the original brief were not cataloged in this
slice and remain TODO for a downstream slice:

- **ORCA/M** - Byte Works' 65816 macro assembler; Modula-2 fork exists at
  `pkclsoft/ORCA-Modula-2`, suggesting an ORCA/M repo also exists under
  `byteworksinc`. Verify and add.
- **BRAVO** - GS/OS-era web browser. Brave search returned no IIgs-relevant
  hits in the time bound; needs a deeper search via `whatisthe2gs.apple2.org.za`
  or a direct comp.sys.apple2 archive query.
- **Brutal Deluxe Object Module Format (OMF) tools** beyond Cadius / Merlin32 -
  e.g., `dumpobj`, `OMF` linkers. Cross-reference `brutaldeluxe.fr/products/`.
- **Crossrunner** - mentioned as a Windows-native IIgs emulator on the KEGS
  page; deserves its own entry once a citation is sourced.
- Any non-Brutal-Deluxe **demoscene release groups** (FTA, Ninjaforce already
  in; FTA still needs cataloging).
- Per-year **KansasFest releases** as separate entries (catalog currently
  treats KFest as a single entity rather than a release stream).

## Contribution rules

- Append-only by default. Edits to existing entries require a citation that
  contradicts the prior value.
- Never commit binaries, ROM files, or Apple IP into this repo.
- Every PR touching `catalog.json` must pass `jq . data/catalog.json` in CI.
