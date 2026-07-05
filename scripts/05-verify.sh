#!/usr/bin/env bash
# Post-setup assertions: GPU, emulators, native stack, exported entries.
source "$(dirname "$0")/../lib/common.sh"

box_exists || die "box '$BOX_NAME' does not exist"
fail=0
check() { # check <label> <command...>
  local label=$1; shift
  if "$@" >/dev/null 2>&1; then
    log "OK: $label"
  else
    warn "FAIL: $label"
    fail=1
  fi
}

gpu=$(in_box vulkaninfo --summary 2>/dev/null | grep -m1 deviceName || true)
if printf '%s' "$gpu" | grep -qi radv; then
  log "OK: Vulkan uses RADV — $gpu"
else
  warn "FAIL: RADV not detected (got: ${gpu:-nothing})"
  fail=1
fi

for bin in pcsx2-qt duckstation-qt rpcs3 steam heroic lutris mangohud gamescope; do
  check "$bin in box" in_box which "$bin"
done

check "PS1 BIOS linked (DuckStation)" test -e "$BOX_HOME/.local/share/duckstation/bios/SCPH1001.BIN"
check "PS2 BIOS dir populated (PCSX2)" bash -c "ls \"$BOX_HOME/.config/PCSX2/bios/\"*.BIN"

for app in "${EXPORT_APPS[@]}"; do
  check "host desktop entry for $app" bash -c "ls \"$HOME/.local/share/applications/\"*\"$app\"*.desktop"
done

if [ "$fail" -eq 0 ]; then
  log "all checks passed"
else
  die "some checks failed (see above)"
fi
