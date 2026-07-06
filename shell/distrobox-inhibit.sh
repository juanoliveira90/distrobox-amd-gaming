# distrobox-gaming: keep the screen awake during a gaming session.
#
# Wraps `distrobox` so that `distrobox enter ...` runs under systemd-inhibit.
# This holds an idle/sleep lock for the whole interactive session, preventing
# the screen from blanking or the system from suspending mid-game.
#
# Sourced from ~/.bashrc / ~/.zshrc by scripts/07-setup-shell-hook.sh.
# For bash and zsh (POSIX-style function definition).

distrobox() {
  if [ "$1" = "enter" ] && command -v systemd-inhibit >/dev/null 2>&1; then
    systemd-inhibit \
      --what=idle:sleep \
      --who="distrobox-gaming" \
      --why="Gaming session — keep screen and system awake" \
      --mode=block \
      "$(command -v distrobox)" "$@"
  else
    command distrobox "$@"
  fi
}
