#!/usr/bin/env bash
# Create the gaming distrobox from the CachyOS image (AMD GPU: no --nvidia
# needed, distrobox bind-mounts /dev/dri automatically).
source "$(dirname "$0")/../lib/common.sh"

if box_exists; then
  log "box '$BOX_NAME' already exists — skipping create"
  exit 0
fi

mkdir -p "$BOX_HOME"

volume_args=()
[ -n "$GAMES_ROOT" ] && volume_args+=(--volume "$GAMES_ROOT:$GAMES_ROOT:rw")


log "creating box '$BOX_NAME' from $BOX_IMAGE (home: $BOX_HOME)"
distrobox create \
  --name "$BOX_NAME" \
  --image "$BOX_IMAGE" \
  --home "$BOX_HOME" \
  --additional-flags "--tmpfs /tmp/.X11-unix" \  # this fixes the issue of gamescope refusing to open because this directory is not onwed by the current user.
  "${volume_args[@]}"

# First enter triggers distrobox's in-container setup (user, sudo, mounts).
log "initializing box (first enter)"
in_box true

log "box created; UID in box: $(in_box id -u)"
