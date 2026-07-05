#!/usr/bin/env bash
# Install the shell hook that makes `distrobox enter` run under systemd-inhibit,
# so the screen never blanks and the system never suspends mid-game.
#
# Idempotent: adds a single source line to each shell's rc file only if missing.
source "$(dirname "$0")/../lib/common.sh"

SHELL_DIR="$PROJECT_ROOT/shell"
MARKER="# distrobox-gaming: keep screen awake (systemd-inhibit)"

command -v systemd-inhibit >/dev/null 2>&1 \
  || warn "systemd-inhibit not found on host — the hook installs but is a no-op until it is available"

# Add a guarded source line to an rc file if it is not already present.
install_hook() {
  local rc="$1" hook="$2"
  [ -f "$hook" ] || { warn "missing hook file: $hook"; return; }
  mkdir -p "$(dirname "$rc")"
  if [ -f "$rc" ] && grep -qF "$MARKER" "$rc"; then
    log "hook already present in $rc"
    return
  fi
  {
    printf '\n%s\n' "$MARKER"
    printf 'test -f %q && source %q\n' "$hook" "$hook"
  } >>"$rc"
  log "installed hook into $rc"
}

install_hook "$HOME/.bashrc"                  "$SHELL_DIR/distrobox-inhibit.sh"
install_hook "$HOME/.zshrc"                   "$SHELL_DIR/distrobox-inhibit.sh"
install_hook "$HOME/.config/fish/config.fish" "$SHELL_DIR/distrobox-inhibit.fish"

log "done — open a new shell (or re-source your rc) to activate"
