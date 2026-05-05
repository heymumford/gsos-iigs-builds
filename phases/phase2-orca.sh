#!/usr/bin/env bash
# Phase 2 — ORCA/C Compiler & Toolchain fitness function (Golden Gate variant).
#
# For ORCA/C cross-compile via Golden Gate compatibility layer, verifies:
#   - Golden Gate runtime installed and callable (iix command)
#   - ORCA/C compiler reachable through Golden Gate
#   - ORCA/M (assembler) reachable
#   - ORCALink (linker) reachable
#   - A minimal compile test succeeds: 5-line C program → OMF S16 binary
#
# Exit codes:
#   0: green (all tools present and functional)
#   1: red (actionable failure — missing tool or version)
#   2: yellow (tool present but verification cannot be determined)
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
  printf '[phase2-orca] %s\n' "$*" >&2
}

# Counters for overall health
red_count=0
yellow_count=0
checks=0

# --- Check 1: Golden Gate runtime (iix) present ---
checks=$((checks + 1))

if command -v iix &>/dev/null; then
  iix_version=$(iix --version 2>&1 | head -1 || echo "unknown")
  emit_fact "iix_version" "$iix_version"
  emit_note "iix (Golden Gate): found (pass)"
else
  emit_fact "iix_version" "not_found"
  emit_note "iix (Golden Gate): command not found (red)"
  red_count=$((red_count + 1))
fi

# --- Check 2: ORCA/C compiler reachable via Golden Gate ---
checks=$((checks + 1))

if command -v iix &>/dev/null; then
  # ORCA/C is invoked as 'iix cc' when installed via Golden Gate
  # Try to get version; if it fails silently, assume not installed (red)
  orca_c_test=$(iix cc 2>&1 | head -1 || echo "not_found")

  if [[ "$orca_c_test" == *"ORCA/C"* ]] || [[ "$orca_c_test" == *"cc"* ]]; then
    emit_fact "orca_c_version" "found"
    emit_note "ORCA/C (cc): callable via iix (pass)"
  elif [[ "$orca_c_test" == "not_found" ]]; then
    emit_fact "orca_c_version" "not_found"
    emit_note "ORCA/C (cc): not reachable via Golden Gate (red)"
    red_count=$((red_count + 1))
  else
    emit_fact "orca_c_version" "unknown"
    emit_note "ORCA/C (cc): response unclear: '$orca_c_test' (yellow)"
    yellow_count=$((yellow_count + 1))
  fi
else
  emit_fact "orca_c_version" "depends_on_iix"
  emit_note "ORCA/C: cannot test (iix not found) (red)"
  red_count=$((red_count + 1))
fi

# --- Check 3: ORCA/M (assembler) reachable ---
checks=$((checks + 1))

if command -v iix &>/dev/null; then
  orca_m_test=$(iix asm 2>&1 | head -1 || echo "not_found")

  if [[ "$orca_m_test" == *"ORCA"* ]] || [[ "$orca_m_test" == *"asm"* ]]; then
    emit_fact "orca_m_version" "found"
    emit_note "ORCA/M (asm): callable via iix (pass)"
  elif [[ "$orca_m_test" == "not_found" ]]; then
    emit_fact "orca_m_version" "not_found"
    emit_note "ORCA/M (asm): not reachable via Golden Gate (red)"
    red_count=$((red_count + 1))
  else
    emit_fact "orca_m_version" "unknown"
    emit_note "ORCA/M (asm): response unclear (yellow)"
    yellow_count=$((yellow_count + 1))
  fi
else
  emit_fact "orca_m_version" "depends_on_iix"
  emit_note "ORCA/M: cannot test (iix not found) (red)"
  red_count=$((red_count + 1))
fi

# --- Check 4: ORCALink (linker) reachable ---
checks=$((checks + 1))

if command -v iix &>/dev/null; then
  link_test=$(iix link 2>&1 | head -1 || echo "not_found")

  if [[ "$link_test" == *"ORCALink"* ]] || [[ "$link_test" == *"link"* ]]; then
    emit_fact "orca_link_version" "found"
    emit_note "ORCALink (link): callable via iix (pass)"
  elif [[ "$link_test" == "not_found" ]]; then
    emit_fact "orca_link_version" "not_found"
    emit_note "ORCALink (link): not reachable via Golden Gate (red)"
    red_count=$((red_count + 1))
  else
    emit_fact "orca_link_version" "unknown"
    emit_note "ORCALink (link): response unclear (yellow)"
    yellow_count=$((yellow_count + 1))
  fi
else
  emit_fact "orca_link_version" "depends_on_iix"
  emit_note "ORCALink: cannot test (iix not found) (red)"
  red_count=$((red_count + 1))
fi

# --- Check 5: Sanity compile test: 5-line C → OMF S16 binary ---
checks=$((checks + 1))

if command -v iix &>/dev/null && [[ "$orca_c_test" != "not_found" ]]; then
  # Create a minimal 5-line C program
  test_c=$(cat <<'EOF'
#pragma lint -1
int main(void) {
  return 0;
}
EOF
)

  # Try to compile via Golden Gate
  # This will attempt: iix cc <options> test.c -o test.s16
  # The exact invocation depends on Golden Gate's wrapper behavior
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT

  echo "$test_c" > "$tmpdir/test.c"

  # Attempt compile (output to assembly or object)
  if iix cc -o "$tmpdir/test" "$tmpdir/test.c" 2>/dev/null || \
     iix cc "$tmpdir/test.c" 2>/dev/null; then
    emit_fact "sanity_compile" "success"
    emit_note "Sanity compile: 5-line C program compiled (pass)"
  else
    emit_fact "sanity_compile" "fail"
    emit_note "Sanity compile: iix cc failed on minimal program (red)"
    red_count=$((red_count + 1))
  fi
else
  emit_fact "sanity_compile" "skipped"
  emit_note "Sanity compile: skipped (iix or ORCA/C not available)"
  # Don't count as red; it's a prerequisite failure already logged
fi

# --- Summary ---
emit_fact "checks_total" "$checks"
emit_fact "red_count" "$red_count"
emit_fact "yellow_count" "$yellow_count"

# Determine exit code
if (( red_count > 0 )); then
  emit_note "Phase 2 (ORCA) result: RED (failing checks: see above)"
  exit 1
elif (( yellow_count > 0 )); then
  emit_note "Phase 2 (ORCA) result: YELLOW (could not verify some checks)"
  exit 2
else
  emit_note "Phase 2 (ORCA) result: GREEN (all checks pass)"
  exit 0
fi
