#!/usr/bin/env bash
# Export app launchers from the box to the host application menu.
source "$(dirname "$0")/../lib/common.sh"

box_exists || die "box '$BOX_NAME' does not exist — run 01-create-box.sh first"

# Match the way distrobox-export finds entries: against the Exec=/Name= lines
# inside the desktop files, not the file names (org.es_de.frontend.desktop
# would never match 'es-de' by name, but its Exec line does).
for app in "${EXPORT_APPS[@]}"; do
  if ! in_box bash -c "grep -qsie 'Exec=.*$app' -e 'Name=.*$app' /usr/share/applications/*.desktop"; then
    warn "no desktop entry matching '$app' in box — skipping export"
    continue
  fi
  log "exporting $app"
  in_box distrobox-export --app "$app" || warn "export failed for $app"
done

log "app export done — entries appear in the host menu with a ($BOX_NAME) suffix"
