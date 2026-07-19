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

# Gamescope refuses to start unless it can create its own nested Xwayland
# socket in /tmp/.X11-unix, and the host's copy maps to `nobody` in the rootless
# userns, so it isn't writable. A bare `--tmpfs /tmp/.X11-unix` fixes gamescope
# but hides the host's X socket, which breaks Steam with "Unable to open a
# connection to X". Do both: writable tmpfs (owned by root in the box, which
# satisfies gamescope's ownership check) with the host's socket bound back on
# top of it.
x_screen="${DISPLAY#*:}"
x_socket="/tmp/.X11-unix/X${x_screen%%.*}"
if [ -S "$x_socket" ]; then
  volume_args+=(--additional-flags "--tmpfs /tmp/.X11-unix:rw,mode=1777 --volume $x_socket:$x_socket")
else
  warn "no X socket at '$x_socket' (DISPLAY=${DISPLAY:-unset}) — X11 apps may not work in the box"
fi

log "creating box '$BOX_NAME' from $BOX_IMAGE (home: $BOX_HOME)"
distrobox create \
  --name "$BOX_NAME" \
  --image "$BOX_IMAGE" \
  --home "$BOX_HOME" \
  "${volume_args[@]}"

# First enter triggers distrobox's in-container setup (user, sudo, mounts).
log "initializing box (first enter)"
in_box true

log "box created; UID in box: $(in_box id -u)"
