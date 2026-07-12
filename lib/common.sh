# Shared helpers. Source this from every script:
#   source "$(dirname "$0")/../lib/common.sh"

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/config/gaming.env"

# GAMES_ROOT (and thus BIOS_ROOT) is optional — default to empty so `set -u`
# doesn't trip if it was commented out entirely.
GAMES_ROOT="${GAMES_ROOT:-}"
BIOS_ROOT="${BIOS_ROOT:-}"

log()  { printf '\033[1;34m[%s]\033[0m %s\n' "$(basename "$0" .sh)" "$*"; }
warn() { printf '\033[1;33m[%s] WARN:\033[0m %s\n' "$(basename "$0" .sh)" "$*" >&2; }
die()  { printf '\033[1;31m[%s] ERROR:\033[0m %s\n' "$(basename "$0" .sh)" "$*" >&2; exit 1; }

# Packages that failed to install land here (one per line); setup.sh reports
# them at the end of the full run. 02-install-packages.sh truncates it on each
# run, so it always reflects the latest attempt.
FAILED_PACKAGES_FILE="$PROJECT_ROOT/.failed-packages"

# Run a command inside the box.
in_box() { distrobox-enter -n "$BOX_NAME" -- "$@"; }

box_exists() { distrobox list --no-color 2>/dev/null | awk -F'|' '{gsub(/ /,"",$2); print $2}' | grep -qx "$BOX_NAME"; }
