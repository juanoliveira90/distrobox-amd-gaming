#!/usr/bin/env bash
# Deploy Steam ROM Manager parser configs (PS1/PS2/PS3) into the box, so ROMs
# on the games drive can be added to the Steam library with artwork.
source "$(dirname "$0")/../lib/common.sh"

box_exists || die "box '$BOX_NAME' does not exist — run 01-create-box.sh first"

if ! in_box pacman -Qq steam-rom-manager-bin >/dev/null 2>&1; then
  warn "steam-rom-manager-bin is not installed — run 02-install-packages.sh first"
  exit 0
fi

STEAM_DIR="$BOX_HOME/.local/share/Steam"
[ -d "$STEAM_DIR" ] || warn "no Steam directory at $STEAM_DIR yet — log into Steam once before adding ROMs"

userdata="$BOX_HOME/.config/steam-rom-manager/userData"
mkdir -p "$userdata"

for file in userSettings.json userConfigurations.json; do
  rendered=$(sed -e "s|@STEAM_DIR@|$STEAM_DIR|g" -e "s|@ROMS_DIR@|$GAMES_ROOT|g" \
             "$PROJECT_ROOT/config/srm/$file")
  if [ -f "$userdata/$file" ]; then
    if [ "$rendered" = "$(cat "$userdata/$file")" ]; then
      log "$file already up to date"
      continue
    fi
    backup="$userdata/$file.bak.$(date +%Y%m%d%H%M%S)"
    warn "$file exists and differs — backing up to $(basename "$backup")"
    cp "$userdata/$file" "$backup"
  fi
  printf '%s\n' "$rendered" > "$userdata/$file"
  log "installed $file"
done

log "SRM config deployed. To add your ROMs to Steam:"
log "  distrobox enter $BOX_NAME -- steam -shutdown          # CLI hangs if Steam is running"
log "  distrobox enter $BOX_NAME -- steam-rom-manager add    # headless: parse + save + artwork"
log "or open the GUI (Preview -> Generate app list -> Save app list); it restarts Steam itself."
