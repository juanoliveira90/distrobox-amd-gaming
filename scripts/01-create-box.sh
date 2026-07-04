#!/usr/bin/env bash
# Create the gaming distrobox from the CachyOS image (AMD GPU: no --nvidia
# needed, distrobox bind-mounts /dev/dri automatically).
source "$(dirname "$0")/../lib/common.sh"

if box_exists; then
  log "box '$BOX_NAME' already exists — skipping create"
  exit 0
fi

mkdir -p "$BOX_HOME"

log "creating box '$BOX_NAME' from $BOX_IMAGE (home: $BOX_HOME)"
distrobox create \
  --name "$BOX_NAME" \
  --image "$BOX_IMAGE" \
  --home "$BOX_HOME" \
  --volume "$GAMES_ROOT:$GAMES_ROOT:rw"

# First enter triggers distrobox's in-container setup (user, sudo, mounts).
log "initializing box (first enter)"
in_box true

log "box created; UID in box: $(in_box id -u)"
