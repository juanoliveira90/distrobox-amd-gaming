#!/usr/bin/env bash
# Build the Game Mode prompt and install it into PATH.
#
# Usage:
#   ./install.sh            build + install to /usr/local/bin (needs sudo)
#   ./install.sh --user     build + install to ~/.local/bin (no sudo)
#   ./install.sh --build    build only, no install
set -euo pipefail
cd "$(dirname "$0")"

BIN_NAME="gamemode"
# Built into build/ because a directory named "gamemode" already exists here.
BUILD_OUT="build/$BIN_NAME"

log()  { printf '\033[1;34m[%s]\033[0m %s\n' "$(basename "$0" .sh)" "$*"; }
warn() { printf '\033[1;33m[%s] WARN:\033[0m %s\n' "$(basename "$0" .sh)" "$*" >&2; }
die()  { printf '\033[1;31m[%s] ERROR:\033[0m %s\n' "$(basename "$0" .sh)" "$*" >&2; exit 1; }

MODE="system"
case "${1:-}" in
  "")        ;;
  --user)    MODE="user" ;;
  --build)   MODE="build-only" ;;
  *)         die "unknown option: $1 (expected --user or --build)" ;;
esac

command -v gcc >/dev/null        || die "gcc not found"
command -v pkg-config >/dev/null || die "pkg-config not found"
pkg-config --exists sdl3         || die "SDL3 dev files not found (pkg-config sdl3)"

log "building $BIN_NAME against SDL3 $(pkg-config --modversion sdl3)"
mkdir -p build
# shellcheck disable=SC2046 — pkg-config output must word-split into flags
gcc main.c -o "$BUILD_OUT" $(pkg-config --cflags --libs sdl3) -Wall -O2

[ "$MODE" = "build-only" ] && { log "built $BUILD_OUT (not installed)"; exit 0; }

if [ "$MODE" = "user" ]; then
  DEST="$HOME/.local/bin"
  mkdir -p "$DEST"
  install -m 755 "$BUILD_OUT" "$DEST/"
  case ":$PATH:" in
    *":$DEST:"*) ;;
    *) warn "$DEST is not in your PATH — add it to your shell rc" ;;
  esac
else
  DEST="/usr/local/bin"
  log "installing to $DEST (sudo may prompt for your password)"
  sudo install -m 755 "$BUILD_OUT" "$DEST/"
fi

log "installed $DEST/$BIN_NAME"
command -v "$BIN_NAME" >/dev/null \
  && log "verified: '$BIN_NAME' resolves to $(command -v "$BIN_NAME")" \
  || warn "'$BIN_NAME' not found in PATH for this shell"
