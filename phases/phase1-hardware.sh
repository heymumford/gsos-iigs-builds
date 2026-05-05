#!/usr/bin/env bash
# Phase 1 — Hardware & Environment fitness function.
#
# For cc65 cross-compile (POSIX host), verifies:
#   - Host RAM >= 4GB (sufficient for cc65 + ld65 + emulator simultaneously)
#   - Free disk space >= 1GB on the repo partition
#   - An emulator binary is reachable (kegs, gsplus, or mame)
#
# Exit codes:
#   0: green (all checks pass)
#   1: red (actionable failure — print what's missing)
#   2: yellow (instrument cannot answer — e.g., no /proc/meminfo on this system)
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
  printf '[phase1] %s\n' "$*" >&2
}

# Counters for overall health
red_count=0
yellow_count=0
checks=0

# --- Check 1: RAM >= 4GB ---
checks=$((checks + 1))

# Try multiple methods to detect RAM, in order of preference
total_ram_bytes=""

# Method 1: /proc/meminfo (Linux)
if [[ -f /proc/meminfo ]]; then
  if total_ram_bytes=$(grep '^MemTotal:' /proc/meminfo | awk '{print $2 * 1024}'); then
    :
  fi
fi

# Method 2: sysctl (POSIX systems)
if [[ -z "$total_ram_bytes" ]] && command -v sysctl &>/dev/null; then
  if total_ram_bytes=$(sysctl -n hw.memsize 2>/dev/null); then
    :
  fi
fi

# Method 3: vm.statistics on macOS
if [[ -z "$total_ram_bytes" ]] && command -v sysctl &>/dev/null; then
  if phys_mem=$(sysctl -n hw.physmem 2>/dev/null); then
    total_ram_bytes="$phys_mem"
  fi
fi

if [[ -n "$total_ram_bytes" ]]; then
  # Convert to GB for readability
  total_ram_gb=$(( (total_ram_bytes + 1073741823) / 1073741824 ))
  emit_fact "total_ram_gb" "$total_ram_gb"

  if (( total_ram_bytes >= 4294967296 )); then
    emit_note "RAM: $total_ram_gb GB (pass, >= 4GB)"
  else
    emit_note "RAM: $total_ram_gb GB (fail, < 4GB)"
    red_count=$((red_count + 1))
  fi
else
  emit_fact "total_ram_gb" "unknown"
  emit_note "RAM: cannot determine via /proc/meminfo or sysctl (yellow)"
  yellow_count=$((yellow_count + 1))
fi

# --- Check 2: Free disk space >= 1GB on repo partition ---
checks=$((checks + 1))

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
if [[ -d "$repo_root" ]]; then
  # Use stat to get available space; falls back to df if stat fails
  available_bytes=""

  # Try df first (most portable)
  if available_kb=$(df "$repo_root" | tail -1 | awk '{print $4}'); then
    available_bytes=$((available_kb * 1024))
  fi

  if [[ -n "$available_bytes" ]]; then
    available_gb=$(( (available_bytes + 1073741823) / 1073741824 ))
    emit_fact "available_disk_gb" "$available_gb"

    if (( available_bytes >= 1073741824 )); then
      emit_note "Disk: $available_gb GB available (pass, >= 1GB)"
    else
      emit_note "Disk: $available_gb GB available (fail, < 1GB)"
      red_count=$((red_count + 1))
    fi
  else
    emit_fact "available_disk_gb" "unknown"
    emit_note "Disk: cannot determine available space (yellow)"
    yellow_count=$((yellow_count + 1))
  fi
else
  emit_fact "available_disk_gb" "unknown"
  emit_note "Disk: repo root not found (yellow)"
  yellow_count=$((yellow_count + 1))
fi

# --- Check 3: An emulator binary is reachable ---
checks=$((checks + 1))

emulator_found=""
for emu in kegs gsplus mame; do
  if command -v "$emu" &>/dev/null; then
    emulator_found="$emu"
    break
  fi
done

if [[ -n "$emulator_found" ]]; then
  emit_fact "emulator" "$emulator_found"
  emit_note "Emulator: $emulator_found found (pass)"
else
  emit_fact "emulator" "none"
  emit_note "Emulator: none of {kegs, gsplus, mame} found (yellow; not blocking for cc65 cross-compile)"
  yellow_count=$((yellow_count + 1))
fi

# --- Summary ---
emit_fact "checks_total" "$checks"
emit_fact "red_count" "$red_count"
emit_fact "yellow_count" "$yellow_count"

# Determine exit code
if (( red_count > 0 )); then
  emit_note "Phase 1 result: RED (failing checks: see above)"
  exit 1
elif (( yellow_count > 0 )); then
  emit_note "Phase 1 result: YELLOW (could not verify some checks)"
  exit 2
else
  emit_note "Phase 1 result: GREEN (all checks pass)"
  exit 0
fi
