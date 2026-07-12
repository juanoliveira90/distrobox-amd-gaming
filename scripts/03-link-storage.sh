#!/usr/bin/env bash
# Link BIOS files into emulator directories and add a convenience ~/Games
# symlink inside the box home. Non-destructive: never overwrites real files.
source "$(dirname "$0")/../lib/common.sh"

box_exists || die "box '$BOX_NAME' does not exist — run 01-create-box.sh first"

if [ -z "$GAMES_ROOT" ]; then
  log "GAMES_ROOT not set — skipping storage linking"
  exit 0
fi

# Convenience symlink in the box home (link lives on btrfs, target on NTFS).
if [ ! -e "$BOX_HOME/Games" ]; then
  ln -s "$GAMES_ROOT" "$BOX_HOME/Games"
  log "linked $BOX_HOME/Games -> $GAMES_ROOT"
fi

if [ ! -d "$BIOS_ROOT" ]; then
  warn "BIOS dir missing ($BIOS_ROOT) — skipping BIOS links"
  exit 0
fi

# Both emulators scan their bios dir and pick up only files they recognize,
# so we link every BIOS-ish file into both. AppleDouble junk (._*) and
# archives are skipped.
duckstation_bios="$BOX_HOME/.local/share/duckstation/bios"
pcsx2_bios="$BOX_HOME/.config/PCSX2/bios"
mkdir -p "$duckstation_bios" "$pcsx2_bios"

linked=0
while IFS= read -r -d '' f; do
  base=$(basename "$f")
  for dest in "$duckstation_bios" "$pcsx2_bios"; do
    if [ ! -e "$dest/$base" ]; then
      ln -s "$f" "$dest/$base"
      linked=$((linked + 1))
    fi
  done
done < <(find "$BIOS_ROOT" -maxdepth 2 -type f \
           ! -name '._*' ! -name '.DS_Store' ! -path '*__MACOSX*' \
           ! -name '*.zip' ! -name '*.PUP' -print0)
log "BIOS links created: $linked (existing links left untouched)"

# RPCS3 firmware: install from the PUP if not already installed.
pup="$BIOS_ROOT/PS3UPDAT.PUP"
if [ -f "$pup" ] && [ ! -d "$BOX_HOME/.config/rpcs3/dev_flash/vsh" ]; then
  if in_box which rpcs3 >/dev/null 2>&1; then
    log "installing PS3 firmware into RPCS3 (one-time)"
    in_box rpcs3 --installfw "$pup" ||
      warn "automatic firmware install failed — open RPCS3 and use File > Install Firmware with $pup"
  fi
fi

log "storage linking done"
