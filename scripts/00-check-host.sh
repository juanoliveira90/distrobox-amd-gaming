#!/usr/bin/env bash
# Preflight checks: required tools, GPU device, games storage mounted.
source "$(dirname "$0")/../lib/common.sh"

command -v distrobox >/dev/null || die "distrobox not found on host"
command -v podman >/dev/null || command -v docker >/dev/null || die "no container runtime (podman/docker) found"

ls /dev/dri/renderD* >/dev/null 2>&1 || die "no GPU render node under /dev/dri"
log "GPU render node present: $(ls /dev/dri/renderD* | tr '\n' ' ')"

if [ -n "$GAMES_ROOT" ]; then
  [ -d "$GAMES_ROOT" ] || die "GAMES_ROOT not found: $GAMES_ROOT — mount the HDD first (it is a udisks2 auto-mount; open it in the file manager or run: udisksctl mount -b /dev/sda1)"
  [ -r "$GAMES_ROOT" ] || die "GAMES_ROOT not readable: $GAMES_ROOT"
  log "games storage OK: $GAMES_ROOT"

  fstype=$(findmnt -no FSTYPE --target "$GAMES_ROOT" 2>/dev/null || true)
  if [ "${fstype#ntfs}" != "$fstype" ]; then
    warn "games storage is NTFS — fine for ROMs, but keep Steam libraries and Proton/Wine prefixes in BOX_HOME ($BOX_HOME), not on the HDD"
  fi

  [ -d "$BIOS_ROOT" ] || warn "BIOS dir not found: $BIOS_ROOT (BIOS linking will be skipped)"
else
  log "GAMES_ROOT not set — skipping games storage checks"
fi

# Steam Input needs /dev/uinput access, granted by host-side udev rules.
if command -v pacman >/dev/null && ! pacman -Qq game-devices-udev >/dev/null 2>&1 \
    && ! pacman -Qq steam-devices >/dev/null 2>&1; then
  warn "game-devices-udev not installed on the host — Steam Input (controller remapping) won't work until you run: sudo pacman -S game-devices-udev"
fi

log "host checks passed"
