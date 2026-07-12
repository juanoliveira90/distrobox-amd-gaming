#!/usr/bin/env bash
# Install repo + AUR packages inside the box.
source "$(dirname "$0")/../lib/common.sh"

box_exists || die "box '$BOX_NAME' does not exist — run 01-create-box.sh first"

# A single broken package must not abort the whole setup: failures are
# collected here, reported at the end and written to FAILED_PACKAGES_FILE
# so setup.sh can print them after the full run.
failed=()
rm -f "$FAILED_PACKAGES_FILE"

log "ensuring [multilib] is enabled"
in_box sudo bash -c '
  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    printf "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" >> /etc/pacman.conf
    echo "multilib enabled"
  fi
'

log "updating system (pacman -Syu)"
in_box sudo pacman -Syu --noconfirm

log "installing repo packages (${#PACMAN_PACKAGES[@]} packages — this downloads several GB)"
# The newline feed answers provider-selection prompts (e.g. proton-cachyos
# flavors) with the default; --noconfirm alone does not cover those. A finite
# printf avoids the SIGPIPE exit that `yes` causes under pipefail.
if ! printf '\n%.0s' $(seq 50) | in_box sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"; then
  # One unresolvable package fails the whole pacman transaction — retry one
  # by one so the rest still get installed, and record what didn't.
  warn "bulk install failed — retrying packages one by one to isolate the culprit"
  for pkg in "${PACMAN_PACKAGES[@]}"; do
    if ! printf '\n%.0s' $(seq 10) | in_box sudo pacman -S --needed --noconfirm "$pkg"; then
      warn "could not install $pkg — continuing"
      failed+=("$pkg")
    fi
  done
fi

have_paru=1
if ! in_box pacman -Qq paru >/dev/null 2>&1 && ! in_box pacman -Qq paru-bin >/dev/null 2>&1; then
  log "installing AUR helper paru"
  if ! in_box sudo pacman -S --needed --noconfirm paru; then
    warn "paru not in repos, bootstrapping from AUR"
    in_box bash -c '
      set -euo pipefail
      tmp=$(mktemp -d)
      git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
      cd "$tmp/paru-bin" && makepkg -si --noconfirm
      rm -rf "$tmp"
    ' || have_paru=0
  fi
fi
[ "$have_paru" -eq 1 ] || warn "could not install paru — AUR packages will be skipped"

for pkg in "${AUR_PACKAGES[@]}"; do
  if in_box pacman -Qq "$pkg" >/dev/null 2>&1; then
    log "$pkg already installed"
    continue
  fi
  # Prefer repo if the package has been adopted there; otherwise AUR.
  if in_box pacman -Si "$pkg" >/dev/null 2>&1; then
    log "installing $pkg from repos"
    in_box sudo pacman -S --needed --noconfirm "$pkg" \
      || { warn "could not install $pkg — continuing"; failed+=("$pkg"); }
  elif [ "$have_paru" -eq 0 ]; then
    failed+=("$pkg")
  else
    log "installing $pkg from AUR"
    in_box paru -S --needed --noconfirm "$pkg" \
      || { warn "could not install $pkg — continuing"; failed+=("$pkg"); }
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  printf '%s\n' "${failed[@]}" > "$FAILED_PACKAGES_FILE"
  warn "package installation finished, but these failed: ${failed[*]}"
else
  log "package installation done"
fi
