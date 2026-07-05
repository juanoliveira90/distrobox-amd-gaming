# distrobox-gaming: keep the screen awake during a gaming session.
#
# Wraps `distrobox` so that `distrobox enter ...` runs under systemd-inhibit.
# This holds an idle/sleep lock for the whole interactive session, preventing
# the screen from blanking or the system from suspending mid-game.
#
# Sourced from ~/.config/fish/config.fish by scripts/07-setup-shell-hook.sh.

function distrobox --wraps distrobox
    if test "$argv[1]" = enter; and command -q systemd-inhibit
        systemd-inhibit \
            --what=idle:sleep \
            --who="distrobox-gaming" \
            --why="Gaming session — keep screen and system awake" \
            --mode=block \
            command distrobox $argv
    else
        command distrobox $argv
    end
end
