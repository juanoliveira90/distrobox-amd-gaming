# Shared helpers. Source this from every script:
#   source "$(dirname "$0")/../lib/common.sh"

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/config/gaming.env"

log()  { printf '\033[1;34m[%s]\033[0m %s\n' "$(basename "$0" .sh)" "$*"; }
warn() { printf '\033[1;33m[%s] WARN:\033[0m %s\n' "$(basename "$0" .sh)" "$*" >&2; }
die()  { printf '\033[1;31m[%s] ERROR:\033[0m %s\n' "$(basename "$0" .sh)" "$*" >&2; exit 1; }

# Run a command inside the box.
in_box() { distrobox-enter -n "$BOX_NAME" -- "$@"; }

box_exists() { distrobox list --no-color 2>/dev/null | awk -F'|' '{gsub(/ /,"",$2); print $2}' | grep -qx "$BOX_NAME"; }
