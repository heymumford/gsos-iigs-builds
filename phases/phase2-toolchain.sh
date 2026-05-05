#!/usr/bin/env bash
# Phase 2 — Compiler & Toolchain fitness function.
#
# For cc65 cross-compile, verifies:
#   - cc65 and ld65 present and at stable version (v2.19+)
#   - ca65 (assembler) present
#   - cl65 (compiler driver) present
#   - apple2enh target is recognized (65816-aware target for IIGS)
#   - A minimal compile test succeeds (echo 'int main(){return 0;}' | cc65 ...)
#
# Exit codes:
#   0: green (all tools present and functional)
#   1: red (actionable failure — missing tool or version)
#   2: yellow (tool present but version cannot be determined)
#
# Output:
#   stdout: machine-readable, one fact per line (key=value)
#   stderr: human-readable explanation

set -u

# Helper to emit a key=value pair on stdout
emit_fact() {
  local key="$1" value="$2"
  printf '%s=%s\n' "$key" "$value"
}

# Helper to emit human prose on stderr
emit_note() {
  printf '[phase2] %s\n' "$*" >&2
}

# Source the atomic fitness emitter. Each check below emits a fitness datum
# with raw + normalized [0..1] + baseline + weight. Compound score is
# computed by tools/fitness/compute.sh.
# shellcheck source=../tools/fitness/emit.sh
source "$(dirname "$0")/../tools/fitness/emit.sh"

# Counters for overall health
red_count=0
yellow_count=0
checks=0

# --- Check 1: cc65 present and version >= 2.19 ---
checks=$((checks + 1))

if command -v cc65 &>/dev/null; then
  cc65_version=$(cc65 --version 2>&1 | head -1)
  emit_fact "cc65_version" "$cc65_version"
  fitness_emit "2" "phase2.cc65_present" 1 "bool" "0.20"

  # Parse semantic version: expect "cc65 V2.19" or similar
  # Extract major.minor from version string
  if [[ "$cc65_version" =~ V([0-9]+)\.([0-9]+) ]]; then
    cc65_major="${BASH_REMATCH[1]}"
    cc65_minor="${BASH_REMATCH[2]}"
    cc65_semver=$(printf '%d.%d' "$cc65_major" "$cc65_minor")
    fitness_emit "2" "phase2.cc65_version" "$cc65_semver" "semver" "0.15"

    if (( cc65_major > 2 || (cc65_major == 2 && cc65_minor >= 19) )); then
      emit_note "cc65: $cc65_version (pass, >= 2.19)"
    else
      emit_note "cc65: $cc65_version (fail, < 2.19; 65816 support may be incomplete)"
      red_count=$((red_count + 1))
    fi
  else
    emit_note "cc65: version string '$cc65_version' does not match expected format (yellow)"
    fitness_emit "2" "phase2.cc65_version" 0 "semver" "0.15"
    yellow_count=$((yellow_count + 1))
  fi
else
  emit_fact "cc65_version" "not_found"
  emit_note "cc65: command not found (red)"
  fitness_emit "2" "phase2.cc65_present" 0 "bool" "0.20"
  fitness_emit "2" "phase2.cc65_version" 0 "semver" "0.15"
  red_count=$((red_count + 1))
fi

# --- Check 2: ca65 (assembler) present ---
checks=$((checks + 1))

if command -v ca65 &>/dev/null; then
  ca65_version=$(ca65 --version 2>&1 | head -1)
  emit_fact "ca65_version" "$ca65_version"
  fitness_emit "2" "phase2.ca65_present" 1 "bool" "0.10"
  emit_note "ca65: found (pass)"
else
  emit_fact "ca65_version" "not_found"
  fitness_emit "2" "phase2.ca65_present" 0 "bool" "0.10"
  emit_note "ca65: command not found (red)"
  red_count=$((red_count + 1))
fi

# --- Check 3: ld65 (linker) present ---
checks=$((checks + 1))

if command -v ld65 &>/dev/null; then
  ld65_version=$(ld65 --version 2>&1 | head -1)
  emit_fact "ld65_version" "$ld65_version"
  fitness_emit "2" "phase2.ld65_present" 1 "bool" "0.10"
  emit_note "ld65: found (pass)"
else
  emit_fact "ld65_version" "not_found"
  fitness_emit "2" "phase2.ld65_present" 0 "bool" "0.10"
  emit_note "ld65: command not found (red)"
  red_count=$((red_count + 1))
fi

# --- Check 4: cl65 (compiler driver) present ---
checks=$((checks + 1))

if command -v cl65 &>/dev/null; then
  cl65_version=$(cl65 --version 2>&1 | head -1)
  emit_fact "cl65_version" "$cl65_version"
  fitness_emit "2" "phase2.cl65_present" 1 "bool" "0.10"
  emit_note "cl65: found (pass)"
else
  emit_fact "cl65_version" "not_found"
  fitness_emit "2" "phase2.cl65_present" 0 "bool" "0.10"
  emit_note "cl65: command not found (red)"
  red_count=$((red_count + 1))
fi

# --- Check 5: apple2enh target recognized ---
checks=$((checks + 1))

# Try a minimal compile for apple2enh target.
# Create a minimal C program and attempt to preprocess/compile.
test_c=$(cat <<'EOF'
int main() { return 0; }
EOF
)

if echo "$test_c" | cc65 --target apple2enh -o /dev/null - 2>/dev/null; then
  emit_fact "apple2enh_target" "success"
  fitness_emit "2" "phase2.apple2enh_compile" 0 "exit_code" "0.20"
  emit_note "apple2enh target: compile test passed (pass)"
elif echo "$test_c" | cc65 --target apple2enh -o /tmp/test_phase2.s - 2>/dev/null; then
  # Fallback: check if assembly was generated (some versions write to file)
  if [[ -f /tmp/test_phase2.s ]]; then
    rm -f /tmp/test_phase2.s
    emit_fact "apple2enh_target" "success"
    fitness_emit "2" "phase2.apple2enh_compile" 0 "exit_code" "0.20"
    emit_note "apple2enh target: compile test passed (pass)"
  else
    emit_fact "apple2enh_target" "fail"
    fitness_emit "2" "phase2.apple2enh_compile" 1 "exit_code" "0.20"
    emit_note "apple2enh target: compile test failed (red)"
    red_count=$((red_count + 1))
  fi
else
  emit_fact "apple2enh_target" "fail"
  fitness_emit "2" "phase2.apple2enh_compile" 1 "exit_code" "0.20"
  emit_note "apple2enh target: compile test failed (red)"
  red_count=$((red_count + 1))
fi

# --- Check 6: .P816 directive (65816 instruction set) recognized ---
checks=$((checks + 1))

test_asm=$(cat <<'EOF'
.P816
.code
lda #$0000
rtl
EOF
)

# Try assembling with .P816 directive
if echo "$test_asm" | ca65 --target apple2enh -o /tmp/test_phase2.o - 2>/dev/null; then
  rm -f /tmp/test_phase2.o
  emit_fact "p816_directive" "success"
  fitness_emit "2" "phase2.p816_directive" 0 "exit_code" "0.15"
  emit_note ".P816 directive: assembler test passed (pass)"
else
  # Try without the target flag
  if echo "$test_asm" | ca65 -o /tmp/test_phase2.o - 2>/dev/null; then
    rm -f /tmp/test_phase2.o
    emit_fact "p816_directive" "success"
    fitness_emit "2" "phase2.p816_directive" 0 "exit_code" "0.15"
    emit_note ".P816 directive: assembler test passed (pass)"
  else
    emit_fact "p816_directive" "fail"
    fitness_emit "2" "phase2.p816_directive" 1 "exit_code" "0.15"
    emit_note ".P816 directive: assembler test failed (red)"
    red_count=$((red_count + 1))
  fi
fi

# --- Summary ---
emit_fact "checks_total" "$checks"
emit_fact "red_count" "$red_count"
emit_fact "yellow_count" "$yellow_count"

# Determine exit code
if (( red_count > 0 )); then
  emit_note "Phase 2 result: RED (failing checks: see above)"
  exit 1
elif (( yellow_count > 0 )); then
  emit_note "Phase 2 result: YELLOW (could not verify some checks)"
  exit 2
else
  emit_note "Phase 2 result: GREEN (all checks pass)"
  exit 0
fi
