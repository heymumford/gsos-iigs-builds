#!/usr/bin/env bash
# Phase 6 — Static Analysis & Deconstruction fitness function.
#
# Verifies Ghidra headless environment for static analysis of 65816 OMF binaries.
#
# Atomics:
#   - ghidra_present (bool) — analyzeHeadless or ghidraRun on PATH (weight 0.40)
#   - ghidra_version (semver) — version >= 11.0 (weight 0.30)
#   - target_imports_clean (exit_code) — successful headless import of $DECONSTRUCT_TARGET (weight 0.30)
#
# Exit codes:
#   0: green (Ghidra present + version OK + target imports clean)
#   1: red (Ghidra missing or version too old)
#   2: yellow (Ghidra present but version unknown or import not tested)
#
# Environment:
#   $DECONSTRUCT_TARGET — path to OMF binary to import (optional; if absent, emit yellow)
#
# Clean-room rule: never imports from roms/, disk-images/, sources/, includes/,
# libraries/, GS_OS_Source/, or any path inside gitignored zones.

set -u

# Helper to emit a key=value pair on stdout
emit_fact() {
  local key="$1" value="$2"
  printf '%s=%s\n' "$key" "$value"
}

# Helper to emit human prose on stderr
emit_note() {
  printf '[phase6] %s\n' "$*" >&2
}

# Source the atomic fitness emitter
# shellcheck source=../tools/fitness/emit.sh
source "$(dirname "$0")/../tools/fitness/emit.sh"

# Counters for overall health
red_count=0
yellow_count=0
checks=0

# --- Check 1: Ghidra present ---
checks=$((checks + 1))

if command -v analyzeHeadless &>/dev/null || command -v ghidraRun &>/dev/null; then
  emit_fact "ghidra_present" "yes"
  fitness_emit "6" "phase6.ghidra_present" 1 "bool" "0.40"
  emit_note "Ghidra: command found (pass)"

  # --- Check 2: Ghidra version ---
  checks=$((checks + 1))

  ghidra_version=""
  if command -v analyzeHeadless &>/dev/null; then
    ghidra_version=$(analyzeHeadless --help 2>&1 | head -1 || true)
  else
    ghidra_version=$(ghidraRun --help 2>&1 | head -1 || true)
  fi

  emit_fact "ghidra_version_string" "$ghidra_version"

  # Parse version: expect "Ghidra 11.x" or "Ghidra 11.x.x"
  if [[ "$ghidra_version" =~ Ghidra[[:space:]]+([0-9]+)\.([0-9]+) ]]; then
    ghidra_major="${BASH_REMATCH[1]}"
    ghidra_minor="${BASH_REMATCH[2]}"
    ghidra_semver=$(printf '%d.%d' "$ghidra_major" "$ghidra_minor")
    fitness_emit "6" "phase6.ghidra_version" "$ghidra_semver" "semver" "0.30"

    if (( ghidra_major > 11 || (ghidra_major == 11 && ghidra_minor >= 0) )); then
      emit_note "Ghidra version: $ghidra_semver (pass, >= 11.0)"
    else
      emit_note "Ghidra version: $ghidra_semver (fail, < 11.0; headless mode may be unstable)"
      red_count=$((red_count + 1))
    fi
  else
    emit_note "Ghidra version: '$ghidra_version' does not match expected format (yellow)"
    fitness_emit "6" "phase6.ghidra_version" 0 "semver" "0.30"
    yellow_count=$((yellow_count + 1))
  fi

  # --- Check 3: Target import test (only if $DECONSTRUCT_TARGET is set) ---
  checks=$((checks + 1))

  if [[ -z "${DECONSTRUCT_TARGET:-}" ]]; then
    emit_note "DECONSTRUCT_TARGET not set; import test skipped (yellow)"
    fitness_emit "6" "phase6.target_imports_clean" 2 "exit_code" "0.30"
    yellow_count=$((yellow_count + 1))
  else
    # Safety check: refuse paths inside gitignored zones
    repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
    forbidden_zones=("roms" "disk-images" "sources" "includes" "libraries" "GS_OS_Source")

    is_forbidden=0
    for zone in "${forbidden_zones[@]}"; do
      if [[ "$DECONSTRUCT_TARGET" =~ ^${repo_root}/${zone}/ ]] || [[ "$DECONSTRUCT_TARGET" =~ ${zone}/ ]]; then
        emit_note "DECONSTRUCT_TARGET '$DECONSTRUCT_TARGET' is in forbidden zone '$zone' (red)"
        is_forbidden=1
        break
      fi
    done

    if (( is_forbidden )); then
      fitness_emit "6" "phase6.target_imports_clean" 1 "exit_code" "0.30"
      red_count=$((red_count + 1))
    elif [[ ! -r "$DECONSTRUCT_TARGET" ]]; then
      emit_note "DECONSTRUCT_TARGET '$DECONSTRUCT_TARGET' is not readable (red)"
      fitness_emit "6" "phase6.target_imports_clean" 1 "exit_code" "0.30"
      red_count=$((red_count + 1))
    else
      # Attempt a minimal headless import
      tmpdir=$(mktemp -d -t ghidra_phase6.XXXXXX)
      trap 'rm -rf "$tmpdir"' EXIT

      emit_note "Attempting headless import of '$DECONSTRUCT_TARGET'..."

      # Create a no-op post-script to avoid any analysis
      postscript="$tmpdir/noop.py"
      cat > "$postscript" <<'PYSCRIPT'
# No-op Ghidra script; import only
pass
PYSCRIPT

      import_timeout=60
      if timeout "$import_timeout" analyzeHeadless \
        "$tmpdir/ghidra_proj" "phase6" \
        -import "$DECONSTRUCT_TARGET" \
        -postScript "$postscript" \
        >/dev/null 2>&1; then
        emit_note "Import succeeded (exit 0) (pass)"
        fitness_emit "6" "phase6.target_imports_clean" 0 "exit_code" "0.30"
      else
        import_exit=$?
        emit_note "Import failed (exit $import_exit) or timed out after ${import_timeout}s (red)"
        fitness_emit "6" "phase6.target_imports_clean" 1 "exit_code" "0.30"
        red_count=$((red_count + 1))
      fi
    fi
  fi

else
  emit_fact "ghidra_present" "no"
  emit_note "Ghidra: command not found (red)"
  fitness_emit "6" "phase6.ghidra_present" 0 "bool" "0.40"
  fitness_emit "6" "phase6.ghidra_version" 0 "semver" "0.30"
  fitness_emit "6" "phase6.target_imports_clean" 2 "exit_code" "0.30"
  red_count=$((red_count + 1))
  yellow_count=$((yellow_count + 1))
fi

# --- Summary ---
emit_fact "checks_total" "$checks"
emit_fact "red_count" "$red_count"
emit_fact "yellow_count" "$yellow_count"

# Determine exit code
if (( red_count > 0 )); then
  emit_note "Phase 6 result: RED (failing checks: see above)"
  exit 1
elif (( yellow_count > 0 )); then
  emit_note "Phase 6 result: YELLOW (could not verify some checks)"
  exit 2
else
  emit_note "Phase 6 result: GREEN (all checks pass)"
  exit 0
fi
