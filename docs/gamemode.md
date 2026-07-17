# Game Mode
****
This project includes "game mode", which aims to provide a better experience for gaming on linux. it's a simple SDL program that ask you what console-like front end you want to start, and it will open it in a separate session (tty4 or tty5) with Gamescope as its compositor. You can use a controller or a keyboard to control it.

<img width="640" height="479" alt="image" src="https://github.com/user-attachments/assets/bd93d23f-9eec-4f8b-af0e-013e56bdda5a" />

## Installation
In order for this to work properly, you'll need to set some things up.
### Adding it to PATH
```
cd gamemode
./install.sh
```

### Creating the processes
You''l need to create the processes that switch session and enter the distrobox:
`/etc/systemd/system/gamemode-steam.service`:
```
[Unit]
Description=Gamescope + Steam (distrobox) in tty5
Conflicts=getty@tty5.service
After=systemd-user-sessions.service

[Service]
User=YOUR_USERNAME
PAMName=login
TTYPath=/dev/tty5
StandardInput=tty
StandardOutput=journal
StandardError=journal
UtmpIdentifier=tty5
UtmpMode=user
ExecStartPre=/usr/bin/chvt 5
ExecStart=/usr/bin/distrobox enter linux-gaming -- /usr/bin/gamescope -w 1920 -h 1080 -r 144 -f -- /usr/bin/steam -tenfoot
ExecStopPost=-/usr/bin/chvt 2
ExecStopPost=-/usr/bin/systemctl start getty@tty5.service
```
`/etc/systemd/system/gamemode-esde.service:
```
[Unit]
Description=Gamescope + ES-DE in tty4
Conflicts=getty@tty4.service
After=systemd-user-sessions.service

[Service]
User=YOUR_USERNAME
PAMName=login
TTYPath=/dev/tty4
StandardInput=tty
StandardOutput=journal
StandardError=journal
UtmpIdentifier=tty4
UtmpMode=user
ExecStartPre=/usr/bin/chvt 4
ExecStart=/usr/bin/distrobox enter linux-gaming -- /usr/bin/gamescope -w 1920 -h 1080 -r 144 -f -- /usr/bin/steam -tenfoot
ExecStopPost=-/usr/bin/chvt 2
ExecStopPost=-/usr/bin/systemctl start getty@tty4.service
```
### Permissions
You'll also need to add the permission to start and stop those services without a password. Go to `/etc/sudoers` and add that in the last line:
```
YOUR_USERNAME ALL=(ALL) NOPASSWD: /usr/bin/systemctl start gamemode-steam.service, /usr/bin/systemctl stop gamemode-steam.service, /usr/bin/systemctl start gamemode-esde.service,
/usr/bin/systemctl stop gamemode-esde.service,
```

Don't forget to change `YOUR_USERNAME` to your real user profile name.
