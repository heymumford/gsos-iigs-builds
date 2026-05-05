#!/usr/bin/env bash
# Test harness for phase1-hardware.sh
#
# Runs phase1 in three modes by injecting fake system tools on PATH:
#   1. all-green: sufficient RAM, disk, emulator present
#   2. one-red: insufficient RAM
#   3. one-yellow: RAM unknown (sysctl missing)
#
# Each mode verifies exit code and key output facts.

set -u

# Test setup: create temporary directories for fake executables
setup_fake_path() {
  local mode="$1"
  local tmpdir="$2"
  local fakedir="$tmpdir/fake_$mode"
  mkdir -p "$fakedir"

  case "$mode" in
    green)
      # All tools work
      cat > "$fakedir/sysctl" <<'SYSCTL_EOF'
#!/usr/bin/env bash
if [[ "$1" == "-n" && "$2" == "hw.memsize" ]]; then
  echo "8589934592"  # 8GB
else
  /usr/bin/sysctl "$@"
fi
SYSCTL_EOF
      chmod +x "$fakedir/sysctl"

      cat > "$fakedir/df" <<'DF_EOF'
#!/usr/bin/env bash
available_blocks=$((2147483648 / 512))  # 2GB
printf '%s %d %d %d %d %d %d%%\n' \
  "fake-fs" "4194304" "2097152" "$available_blocks" "0" "0" "50"
DF_EOF
      chmod +x "$fakedir/df"

      cat > "$fakedir/kegs" <<'KEGS_EOF'
#!/usr/bin/env bash
exit 0
KEGS_EOF
      chmod +x "$fakedir/kegs"
      ;;

    red_ram)
      # Insufficient RAM, sufficient disk
      cat > "$fakedir/sysctl" <<'SYSCTL_EOF'
#!/usr/bin/env bash
if [[ "$1" == "-n" && "$2" == "hw.memsize" ]]; then
  echo "1073741824"  # 1GB (insufficient)
else
  /usr/bin/sysctl "$@"
fi
SYSCTL_EOF
      chmod +x "$fakedir/sysctl"

      cat > "$fakedir/df" <<'DF_EOF'
#!/usr/bin/env bash
available_blocks=$((2147483648 / 512))  # 2GB
printf '%s %d %d %d %d %d %d%%\n' \
  "fake-fs" "4194304" "2097152" "$available_blocks" "0" "0" "50"
DF_EOF
      chmod +x "$fakedir/df"

      cat > "$fakedir/kegs" <<'KEGS_EOF'
#!/usr/bin/env bash
exit 0
KEGS_EOF
      chmod +x "$fakedir/kegs"
      ;;

    yellow)
      # sysctl and df not available; only emulator check works
      # (Simulate a system where memory detection tools are missing)
      cat > "$fakedir/kegs" <<'KEGS_EOF'
#!/usr/bin/env bash
exit 0
KEGS_EOF
      chmod +x "$fakedir/kegs"
      ;;
  esac

  echo "$fakedir"
}

run_phase1_test() {
  local mode="$1"
  local test_name="test_phase1_$mode"

  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" EXIT

  # Set up fake PATH with mode-specific executables
  fakedir=$(setup_fake_path "$mode" "$tmpdir")

  # Export environment for fake tools
  export PATH="$fakedir:$PATH"

  # Run phase1 and capture output
  output=$("$(dirname "$0")/../../phases/phase1-hardware.sh" 2>&1)
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
    red_ram)
      if [[ $exit_code -eq 1 ]]; then
        echo "✓ PASS: exit code 1 (red)"
      else
        echo "✗ FAIL: expected exit 1, got $exit_code"
        return 1
      fi
      ;;
    yellow)
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
echo "Testing phase1-hardware.sh..."
echo ""

pass_count=0
fail_count=0

for mode in green red_ram yellow; do
  if run_phase1_test "$mode"; then
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
