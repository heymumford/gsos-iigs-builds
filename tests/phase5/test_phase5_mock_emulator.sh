#!/usr/bin/env bash
# Exit code matrix test for phase5-emulator-boot.sh
# Verifies behavior with mock emulator binaries and controlled environment

set -u

script="$(dirname "$0")/../../phases/phase5-emulator-boot.sh"
test_dir="$(dirname "$0")"
mock_bin_dir="$test_dir/.mock-emulators"

# Clean up any prior test artifacts
rm -rf "$mock_bin_dir"
mkdir -p "$mock_bin_dir"

# Create mock ROM and disk image files for testing
mock_rom="$test_dir/.mock-rom.bin"
mock_disk="$test_dir/.mock-disk.po"
echo "fake rom data" > "$mock_rom"
echo "fake disk data" > "$mock_disk"

# Helper to create a mock emulator binary that exits with a given code
make_mock_emulator() {
  local name="$1" exit_code="$2" output="$3"
  local path="$mock_bin_dir/$name"
  {
    printf '%s\n' "#!/usr/bin/env bash"
    printf '%s\n' "set +u"
    printf '%s\n' "echo '$output'"
    printf '%s\n' "exit $exit_code"
  } > "$path"
  chmod +x "$path"
}

# Test 1: Missing ROM path (expect exit code 2)
echo "Test 1: Missing IIGS_ROM_PATH"
unset IIGS_ROM_PATH
export IIGS_DISK_IMAGE_PATH="$mock_disk"
output=$("$script" 2>&1)
exit_code=$?
if [[ "$exit_code" -eq 2 ]]; then
  echo "✓ PASS: exit code 2 (yellow) when ROM path missing"
else
  echo "✗ FAIL: expected exit code 2, got $exit_code"
  exit 1
fi

# Test 2: Missing disk image path (expect exit code 2)
echo "Test 2: Missing IIGS_DISK_IMAGE_PATH"
export IIGS_ROM_PATH="$mock_rom"
unset IIGS_DISK_IMAGE_PATH
output=$("$script" 2>&1)
exit_code=$?
if [[ "$exit_code" -eq 2 ]]; then
  echo "✓ PASS: exit code 2 (yellow) when disk image path missing"
else
  echo "✗ FAIL: expected exit code 2, got $exit_code"
  exit 1
fi

# Test 3: Both paths set but no emulator on PATH (expect exit code 2)
echo "Test 3: No emulator on PATH"
export IIGS_ROM_PATH="$mock_rom"
export IIGS_DISK_IMAGE_PATH="$mock_disk"
export PATH="$mock_bin_dir:$PATH"
output=$("$script" 2>&1)
exit_code=$?
if [[ "$exit_code" -eq 2 ]]; then
  echo "✓ PASS: exit code 2 (yellow) when no emulator found"
else
  echo "✗ FAIL: expected exit code 2, got $exit_code"
  exit 1
fi

# Test 4: Mock emulator present but boot fails (expect exit code 1)
echo "Test 4: Emulator present, boot fails"
make_mock_emulator gsplus 1 "boot failed"
output=$("$script" 2>&1)
exit_code=$?
if [[ "$exit_code" -eq 1 ]]; then
  echo "✓ PASS: exit code 1 (red) when boot fails"
else
  echo "✗ FAIL: expected exit code 1, got $exit_code"
  exit 1
fi

# Test 5: Mock emulator present, boot succeeds (expect exit code 0)
echo "Test 5: Emulator present, boot succeeds"
make_mock_emulator gsplus 0 "Finder loaded successfully"
output=$("$script" 2>&1)
exit_code=$?
if [[ "$exit_code" -eq 0 ]]; then
  echo "✓ PASS: exit code 0 (green) when boot succeeds"
else
  echo "✗ FAIL: expected exit code 0, got $exit_code"
  echo "Output: $output"
  exit 1
fi

# Clean up
rm -rf "$mock_bin_dir" "$mock_rom" "$mock_disk"

echo "✓ PASS: All exit code matrix tests passed"
exit 0
