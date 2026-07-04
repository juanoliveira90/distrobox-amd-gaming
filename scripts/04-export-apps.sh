#!/usr/bin/env bash
# Export app launchers from the box to the host application menu.
source "$(dirname "$0")/../lib/common.sh"

box_exists || die "box '$BOX_NAME' does not exist — run 01-create-box.sh first"

for app in "${EXPORT_APPS[@]}"; do
  if ! in_box bash -c "ls /usr/share/applications | grep -qi -- '$app'"; then
    warn "no desktop entry matching '$app' in box — skipping export"
    continue
  fi
  log "exporting $app"
  in_box distrobox-export --app "$app" || warn "export failed for $app"
done

log "app export done — entries appear in the host menu with a ($BOX_NAME) suffix"
