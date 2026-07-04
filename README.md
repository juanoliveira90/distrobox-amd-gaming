# distrobox-gaming

A distrobox dedicated to gaming (native + emulation) on a CachyOS host with an
AMD GPU. Inspired by [akitaonrails/distrobox-gaming](https://github.com/akitaonrails/distrobox-gaming),
rebuilt as plain shell scripts with the CachyOS container image and an
AMD/RADV-first design (no NVIDIA workarounds needed).

## What it sets up

- Distrobox `gaming` from `docker.io/cachyos/cachyos-v3:latest` with a
  dedicated home at `~/distrobox/gaming`
- **Native gaming**: Steam, proton-cachyos, Heroic, Lutris, wine, winetricks,
  protontricks, gamemode, mangohud, gamescope (all with lib32 Vulkan/RADV)
- **Emulation**: PCSX2 (PS2), DuckStation (PS1), RPCS3 (PS3)
- BIOS symlinks from your games drive into each emulator, RPCS3 firmware
  install from `PS3UPDAT.PUP` (if present in your BIOS folder)
- Host application-menu entries for everything via `distrobox-export`

## Quick start

```sh
./setup.sh
```

Steps run in order and are idempotent — re-run `setup.sh` (or any single
script under `scripts/`) whenever you change `config/gaming.env`.

| Script | Purpose |
|---|---|
| `scripts/00-check-host.sh` | preflight: tools, GPU node, games drive mounted |
| `scripts/01-create-box.sh` | create the distrobox |
| `scripts/02-install-packages.sh` | pacman + AUR packages inside the box |
| `scripts/03-link-storage.sh` | BIOS links, `~/Games` symlink, PS3 firmware |
| `scripts/04-export-apps.sh` | export launchers to the host menu |
| `scripts/05-verify.sh` | post-setup assertions (RADV, binaries, links) |

## Configuration

Everything lives in `config/gaming.env`: box name/image, paths, and the
package/export lists. Edit it before running `setup.sh`:

```sh
BOX_HOME=$HOME/distrobox/gaming            # dedicated home for the box
GAMES_ROOT=/run/media/$USER/HDD/Games      # where your ROMs/games live
BIOS_ROOT=$GAMES_ROOT/Bios                 # BIOS files (flat or one level of subdirs)
```

The scripts never hardcode paths — changing `GAMES_ROOT` and re-running
`setup.sh` is all it takes to point at a different drive.

## Storage caveats

- If your games drive is removable/auto-mounted (udisks2 under `/run/media/...`),
  it only exists after being mounted — open it once in the file manager after
  boot, or add an fstab entry with a stable path (e.g. `/mnt/games`) and set
  `GAMES_ROOT` to that instead.
- ROMs on an NTFS drive are fine. **Steam libraries and Proton/Wine prefixes
  are not** — keep game installs inside `BOX_HOME` on a Linux filesystem
  (ext4/btrfs). NTFS Steam libraries are a well-known source of Proton
  breakage.

## Everyday use

### Launching things

The normal way is the **host application menu**: every app was exported and
shows up with an "(on gaming)" suffix — Steam, Heroic, Lutris, PCSX2,
DuckStation, RPCS3. Click and play; no terminal needed.

From a terminal, the equivalents are:

```sh
distrobox enter gaming -- steam           # Steam
distrobox enter gaming -- heroic          # Heroic (Epic/GOG)
distrobox enter gaming -- lutris          # Lutris
distrobox enter gaming -- pcsx2-qt        # PCSX2 (PS2)
distrobox enter gaming -- duckstation-qt  # DuckStation (PS1)
distrobox enter gaming -- rpcs3           # RPCS3 (PS3)

distrobox enter gaming                    # or just get a shell inside the box
```

ROMs are visible inside the box at the same path as on the host, and via the
`~/Games` symlink in the box home. BIOS files are already linked, so the
emulators find them without any setup.

### Controllers

Controller handling lives on the **host**, not in the box: pair/connect your
pad on the host (USB or Bluetooth) and the box sees the same `/dev/input`
devices automatically — emulators and games pick it up with no per-box setup,
hotplug included.

One host-side requirement: **Steam Input** (remapping, PS/Switch pad support,
Steam's virtual controller) creates a virtual device through `/dev/uinput`,
which is root-only by default. Install the udev rules **on the host** (not in
the box — udev runs on the host):

```sh
sudo pacman -S game-devices-udev    # CachyOS/AUR; on other distros: steam-devices
```

Then reconnect the controller. Without this, plain controller input still
works, but Steam Input features fail silently.

### MangoHud and gamemode

Both are wrappers around a game, not apps you open:

- **Steam**: right-click a game → Properties → Launch Options:
  `mangohud gamemoderun %command%`
- **Heroic**: game settings → toggle "Use GameMode" and "MangoHud"
- **Lutris**: game → Configure → System options → same toggles
- **Emulators / anything else**: prefix the command, e.g.
  `distrobox enter gaming -- mangohud pcsx2-qt`

### After a reboot

If your games drive is auto-mounted (see storage caveats), mount it before
launching emulators — open it once in the file manager, or run
`udisksctl mount -b /dev/sdXN` (your drive's partition) — otherwise ROMs and
BIOS links point at nothing. Drives mounted via fstab need no extra step.

### Updating the box (occasionally)

```sh
distrobox enter gaming -- sudo pacman -Syu   # repo packages (Steam, Mesa, Proton…)
distrobox enter gaming -- paru -Syu          # AUR packages (emulators, Heroic)
```

### Stopping the box

The container keeps running in the background after you use it. To free RAM:

```sh
distrobox stop gaming
```

It starts again automatically the next time you launch anything from it.

### Rules of thumb

- **One Steam per home**: if any other distrobox (or the host) shares this
  box's home directory, never run Steam from two of them at once — two clients
  on the same `~/.steam` will corrupt each other's state.
- **Install games to the box home**, not a removable/NTFS drive: Steam
  libraries and Proton/Wine prefixes belong in `BOX_HOME` on a Linux
  filesystem. The games drive is for ROMs, BIOS, and media.

## Removing / rebuilding

```sh
distrobox rm -f gaming     # container only; BOX_HOME state survives
./setup.sh                 # rebuild — configs/saves in BOX_HOME are reused
rm -rf ~/distrobox/gaming  # ONLY if you also want to wipe saves/configs
```

This repo contains no ROMs, BIOS, or firmware — scripts only link what
already exists on your disk.
