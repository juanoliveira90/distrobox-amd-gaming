#!/usr/bin/env bash
# Set up the ES-DE frontend: build its ~/ROMs tree from the games drive
# (symlinks only, never copies) and preselect the standalone emulators so
# PS1/PS2/PS3 games launch with DuckStation/PCSX2/RPCS3 out of the box.
# Non-destructive and idempotent: existing links and gamelists are kept.
source "$(dirname "$0")/../lib/common.sh"

box_exists || die "box '$BOX_NAME' does not exist — run 01-create-box.sh first"

if ! in_box which es-de >/dev/null 2>&1; then
  warn "es-de is not installed in the box — run 02-install-packages.sh first"
  exit 0
fi

# ES-DE's default ROM directory is ~/ROMs, which inside the box is BOX_HOME.
ROMS_DIR="$BOX_HOME/ROMs"
mkdir -p "$ROMS_DIR"

# --- Preselect emulators (ES-DE calls these "alternative emulators") --------
# ES-DE's default launch commands for psx/ps2 are RetroArch cores, which this
# box does not install, and ps3 game directories need the "RPCS3 Directory"
# entry. The system-wide choice lives in a header tag of each system's
# gamelist.xml; ES-DE validates the label against es_systems.xml on startup.
gamelists="$BOX_HOME/ES-DE/gamelists"
preset_emulator() { # preset_emulator <system> <label>
  local sys=$1 label=$2 file="$gamelists/$1/gamelist.xml"
  if [ -f "$file" ]; then
    if grep -qF "<label>$label</label>" "$file"; then
      log "$sys: alternative emulator already set to '$label'"
    else
      warn "$sys: gamelist.xml exists without '$label' — pick it in ES-DE under Other settings > Alternative emulators (not overwriting your gamelist)"
    fi
    return
  fi
  mkdir -p "$gamelists/$sys"
  printf '%s\n' \
    '<?xml version="1.0"?>' \
    '<alternativeEmulator>' \
    "	<label>$label</label>" \
    '</alternativeEmulator>' \
    '<gameList />' > "$file"
  log "$sys: preset alternative emulator '$label'"
}
preset_emulator psx "DuckStation (Standalone)"
preset_emulator ps2 "PCSX2 (Standalone)"
preset_emulator ps3 "RPCS3 Directory (Standalone)"

if [ ! -d "$GAMES_ROOT" ]; then
  warn "games drive not mounted ($GAMES_ROOT) — skipping ROM links"
  exit 0
fi

linked=0
make_link() { # make_link <target> <link>
  if [ ! -e "$2" ] && [ ! -L "$2" ]; then
    ln -s "$1" "$2"
    linked=$((linked + 1))
  fi
}

# --- psx: one "<file>.m3u/.cue/.chd/.pbp" symlink per game ------------------
# PS1 games live in per-game subdirectories (game.cue + track .bin files).
# Linking the whole PS1 directory would list every .bin track as a separate
# game, so we use ES-DE's "directories interpreted as files" support instead:
# a symlink named after the launchable file, pointing at the game directory.
# ES-DE shows one entry and passes <link>/<file> to DuckStation, which then
# resolves the .bin tracks inside the real directory. Multi-disc games get a
# .m3u link (one entry), or one link per .cue when there is no playlist.
if [ -d "$GAMES_ROOT/PS1" ]; then
  mkdir -p "$ROMS_DIR/psx"
  shopt -s nullglob nocaseglob
  for gamedir in "$GAMES_ROOT/PS1"/*/; do
    gamedir=${gamedir%/}
    case $(basename "$gamedir") in __MACOSX) continue ;; esac
    launchers=()
    for pat in '*.m3u' '*.cue' '*.chd' '*.pbp'; do
      launchers=("$gamedir"/$pat)
      [ ${#launchers[@]} -gt 0 ] && break
    done
    if [ ${#launchers[@]} -eq 0 ]; then
      warn "psx: no launchable file (.m3u/.cue/.chd/.pbp) in $(basename "$gamedir") — skipping"
      continue
    fi
    for f in "${launchers[@]}"; do
      make_link "$gamedir" "$ROMS_DIR/psx/$(basename "$f")"
    done
  done
  # single-file games sitting directly in PS1/ (no directory to interpret)
  for f in "$GAMES_ROOT/PS1"/*.chd "$GAMES_ROOT/PS1"/*.pbp; do
    make_link "$f" "$ROMS_DIR/psx/$(basename "$f")"
  done
  shopt -u nullglob nocaseglob
else
  warn "no PS1 directory under $GAMES_ROOT — skipping psx"
fi

# --- ps2: whole-directory symlink --------------------------------------------
# PS2 dumps are single files (.iso/.chd/.cso/.gz/.zso), so pointing the ES-DE
# system directory straight at the drive works — new games appear without
# re-running this script.
if [ -d "$GAMES_ROOT/PS2" ]; then
  make_link "$GAMES_ROOT/PS2" "$ROMS_DIR/ps2"
else
  warn "no PS2 directory under $GAMES_ROOT — skipping ps2"
fi

# --- ps3: one "<game>.ps3" symlink per extracted disc game -------------------
# ES-DE requires extracted PS3 games to be directories with a .ps3 extension
# (again "directories interpreted as files"); the drive keeps its clean names
# and only the symlinks carry the suffix. Loose .iso images are linked as-is —
# the preset "RPCS3 Directory" entry runs both (same rpcs3 --no-gui command).
if [ -d "$GAMES_ROOT/PS3" ]; then
  mkdir -p "$ROMS_DIR/ps3"
  shopt -s nullglob nocaseglob
  for gamedir in "$GAMES_ROOT/PS3"/*/; do
    gamedir=${gamedir%/}
    case $(basename "$gamedir") in __MACOSX) continue ;; esac
    if [ ! -d "$gamedir/PS3_GAME" ]; then
      warn "ps3: $(basename "$gamedir") has no PS3_GAME directory — skipping"
      continue
    fi
    make_link "$gamedir" "$ROMS_DIR/ps3/$(basename "$gamedir").ps3"
  done
  for f in "$GAMES_ROOT/PS3"/*.iso; do
    make_link "$f" "$ROMS_DIR/ps3/$(basename "$f")"
  done
  shopt -u nullglob nocaseglob
else
  warn "no PS3 directory under $GAMES_ROOT — skipping ps3"
fi

log "ROM links created: $linked (existing links left untouched)"
log "ES-DE setup done — launch it with: distrobox enter $BOX_NAME -- es-de"
log "re-run this script after adding PS1/PS3 games (PS2 picks up new files automatically)"
