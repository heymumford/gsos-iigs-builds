#!/usr/bin/env bash
# Test harness for phase2-toolchain.sh
#
# Runs phase2 in three modes by injecting fake cc65 tools on PATH:
#   1. all-green: all tools present and functional
#   2. one-red: cc65 missing
#   3. one-yellow: cc65 present but version unknown
#
# Each mode verifies exit code and output facts.

set -u

# Test setup: create temporary directories for fake executables
setup_fake_cc65_path() {
  local mode="$1"
  local tmpdir="$2"
  local fakedir="$tmpdir/fake_cc65_$mode"
  mkdir -p "$fakedir"

  case "$mode" in
    green)
      # Create all cc65 tools with working versions
      cat > "$fakedir/cc65" <<'CC65_EOF'
#!/usr/bin/env bash
if [[ "$1" == "--version" ]]; then
  echo "cc65 V2.19 - (C) 1998-2024 Ullrich von Bassewitz"
  exit 0
fi
# Simulate successful compilation
exit 0
CC65_EOF
      chmod +x "$fakedir/cc65"

      cat > "$fakedir/ca65" <<'CA65_EOF'
#!/usr/bin/env bash
if [[ "$1" == "--version" ]]; then
  echo "ca65 V2.19 - (C) 1998-2024 Ullrich von Bassewitz"
  exit 0
fi
# Simulate successful assembly
if [[ "$*" == *"-o"* ]]; then
  # Extract output filename
  for arg in "$@"; do
    if [[ "$prev_arg" == "-o" ]]; then
      touch "$arg"
      break
    fi
    prev_arg="$arg"
  done
fi
exit 0
CA65_EOF
      chmod +x "$fakedir/ca65"

      cat > "$fakedir/ld65" <<'LD65_EOF'
#!/usr/bin/env bash
if [[ "$1" == "--version" ]]; then
  echo "ld65 V2.19 - (C) 1998-2024 Ullrich von Bassewitz"
  exit 0
fi
exit 0
LD65_EOF
      chmod +x "$fakedir/ld65"

      cat > "$fakedir/cl65" <<'CL65_EOF'
#!/usr/bin/env bash
if [[ "$1" == "--version" ]]; then
  echo "cl65 V2.19 - (C) 1998-2024 Ullrich von Bassewitz"
  exit 0
fi
exit 0
CL65_EOF
      chmod +x "$fakedir/cl65"
      ;;

    red_missing_cc65)
      # Create only ca65, ld65, cl65 (missing cc65)
      cat > "$fakedir/ca65" <<'CA65_EOF'
#!/usr/bin/env bash
echo "ca65 V2.19"
exit 0
CA65_EOF
      chmod +x "$fakedir/ca65"

      cat > "$fakedir/ld65" <<'LD65_EOF'
#!/usr/bin/env bash
echo "ld65 V2.19"
exit 0
LD65_EOF
      chmod +x "$fakedir/ld65"

      cat > "$fakedir/cl65" <<'CL65_EOF'
#!/usr/bin/env bash
echo "cl65 V2.19"
exit 0
CL65_EOF
      chmod +x "$fakedir/cl65"
      ;;

    yellow_unknown_version)
      # cc65 present but returns unparseable version
      cat > "$fakedir/cc65" <<'CC65_EOF'
#!/usr/bin/env bash
if [[ "$1" == "--version" ]]; then
  echo "some-custom-build"
  exit 0
fi
exit 0
CC65_EOF
      chmod +x "$fakedir/cc65"

      cat > "$fakedir/ca65" <<'CA65_EOF'
#!/usr/bin/env bash
echo "ca65 V2.19"
exit 0
CA65_EOF
      chmod +x "$fakedir/ca65"

      cat > "$fakedir/ld65" <<'LD65_EOF'
#!/usr/bin/env bash
echo "ld65 V2.19"
exit 0
LD65_EOF
      chmod +x "$fakedir/ld65"

      cat > "$fakedir/cl65" <<'CL65_EOF'
#!/usr/bin/env bash
echo "cl65 V2.19"
exit 0
CL65_EOF
      chmod +x "$fakedir/cl65"
      ;;
  esac

  echo "$fakedir"
}

run_phase2_test() {
  local mode="$1"
  local test_name="test_phase2_$mode"

  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" EXIT

  # Set up fake PATH with mode-specific executables
  fakedir=$(setup_fake_cc65_path "$mode" "$tmpdir")
  export PATH="$fakedir:$PATH"

  # Run phase2 and capture output
  output=$("$(dirname "$0")/../../phases/phase2-toolchain.sh" 2>&1)
  exit_code=$?

  # Parse output for verification
  echo "=== $test_name ==="
  echo "Exit code: $exit_code"
  echo "Output:"
  echo "$output" | head -20

  # Verify exit code matches expected
  case "$mode" in
    green)
      if [[ $exit_code -eq 0 ]]; then
        echo "✓ PASS: exit code 0 (green)"
      else
        echo "✗ FAIL: expected exit 0, got $exit_code"
        return 1
      fi
      ;;
    red_missing_cc65)
      if [[ $exit_code -eq 1 ]]; then
        echo "✓ PASS: exit code 1 (red)"
      else
        echo "✗ FAIL: expected exit 1, got $exit_code"
        return 1
      fi
      ;;
    yellow_unknown_version)
      if [[ $exit_code -eq 2 ]]; then
        echo "✓ PASS: exit code 2 (yellow)"
      else
        echo "✗ FAIL: expected exit 2, got $exit_code"
        return 1
      fi
      ;;
  esac

  echo ""
  return 0
}

# Run all three modes
echo "Testing phase2-toolchain.sh..."
echo ""

pass_count=0
fail_count=0

for mode in green red_missing_cc65 yellow_unknown_version; do
  if run_phase2_test "$mode"; then
    pass_count=$((pass_count + 1))
  else
    fail_count=$((fail_count + 1))
  fi
done

echo "=== Summary ==="
echo "Passed: $pass_count"
echo "Failed: $fail_count"

if [[ $fail_count -eq 0 ]]; then
  exit 0
else
  exit 1
fi
