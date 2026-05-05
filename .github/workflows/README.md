# GitHub Actions CI

This directory contains the GitHub Actions CI configuration for gsos-iigs-builds.

## What CI does

The `ci.yml` workflow runs on every pull request and push to `main`:

1. **Shellcheck validation** — All `.sh` files are linted with shellcheck. The `SC1091` rule (sourced file not following) is excluded to permit runtime-loaded scripts.
2. **JSON validation** — All `.json` files are validated with jq.
3. **Framework test** — If `tests/fitness/test_emit_and_compute.sh` exists, it is executed.

All steps are permissive: missing directories do not fail the workflow.

## Adding a new test

1. Create your test script in the appropriate `tests/` subdirectory (e.g., `tests/phase3/test_phase3_source_truth.sh`).
2. Ensure the script exits 0 on success, non-zero on failure.
3. The workflow will not automatically pick it up unless you add it to `ci.yml` as an explicit step. Alternatively, add your test to an existing phase test suite that is already run.

## Convention: shellcheck-clean scripts

All shell scripts in the repository **must pass shellcheck with no warnings**, except for:

- `SC1091` — "not following sourced file" (allowed for scripts that source files at runtime)

Run shellcheck locally before pushing:

```bash
shellcheck -e SC1091 your-script.sh
```

This keeps the CI gate clean and prevents silent regressions.
