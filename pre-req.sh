#!/bin/bash
# Host (Debian) setup for the containerized sway desktop:
# podman (rootless) + seatd + greetd/tuigreet. Idempotent.
#
# This script does NOT switch the display manager — SDDM stays the login
# screen until you run the switch step it prints at the end, after the
# container session has been verified from a spare TTY.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="$DOTFILES/.host"
ME="${SUDO_USER:-$USER}"

[[ $EUID -eq 0 ]] || { echo "run with sudo: sudo ./pre-req.sh"; exit 1; }
[[ -n "${SUDO_USER:-}" ]] || { echo "run via sudo from your user, not a root shell"; exit 1; }

# Keep sddm the default DM through greetd's install-time debconf question
echo "greetd shared/default-x-display-manager select sddm" | debconf-set-selections || true

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    podman crun uidmap slirp4netns dbus-user-session fuse-overlayfs \
    seatd greetd
DEBIAN_FRONTEND=noninteractive apt-get install -y -t bookworm-backports tuigreet

# Belt and braces: if greetd's postinst grabbed display-manager anyway, undo it
current_dm="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" || true)"
if [[ "$current_dm" == "greetd.service" ]]; then
    systemctl disable greetd >/dev/null 2>&1 || true
    systemctl enable sddm >/dev/null
    echo "note: restored sddm as display-manager; greetd stays off until you switch"
fi

systemctl enable --now seatd

# Group memberships: render/input for device nodes in the rootless container,
# plus whatever group owns the seatd socket. Add pipewire too when present, so
# the user picks up its RT limits (95-pipewire.conf: rtprio 95, nice -19) — the
# rootless-safe way to give the containerized sway realtime scheduling.
seatd_group="$(stat -c %G /run/seatd.sock)"
extra_groups="render,input,$seatd_group"
getent group pipewire >/dev/null && extra_groups="$extra_groups,pipewire"
usermod -aG "$extra_groups" "$ME"

# greetd config — fix the greeter user to whatever the Debian package created
greeter_user="_greetd"
getent passwd "$greeter_user" >/dev/null || greeter_user="greeter"
getent passwd "$greeter_user" >/dev/null || { echo "ERROR: no greetd greeter user found"; exit 1; }
sed "s/^user = .*/user = \"$greeter_user\"/" "$HOST/greetd/config.toml" > /etc/greetd/config.toml
chmod 644 /etc/greetd/config.toml

install -m 755 "$HOST/bin/sway-container-session" /usr/local/bin/sway-container-session

# Rootless podman config for the build: overlay driver + on-/home layer temp.
# Written as $ME (rootless config lives in the user's home), non-destructively
# so an existing hand-tuned config is left alone. Must land before build.sh.
user_home="$(getent passwd "$ME" | cut -d: -f6)"
install -d -o "$ME" -g "$ME" -m 755 "$user_home/.config/containers"
for cfg in storage.conf containers.conf; do
    dest="$user_home/.config/containers/$cfg"
    if [[ -e "$dest" ]]; then
        echo "note: $dest exists, leaving it as-is (check driver=overlay + image_copy_tmp_dir)"
    else
        install -o "$ME" -g "$ME" -m 644 "$HOST/containers-config/$cfg" "$dest"
        echo "installed $dest"
    fi
done

cat <<EOF

Host setup complete (login screen unchanged). Next steps, in order:

  1. Log out and back in (or reboot) so the new groups apply to $ME:
       render, input, $seatd_group
  2. Build the desktop image (as $ME, not root):
       $HOST/containers/arch-sway/build.sh
  3. Verify from a spare TTY (Ctrl-Alt-F3, log in on the console):
       sway-container-session
     Expect containerized sway on real hardware. Check input, wofi,
     alacritty, audio, VT switching. Log: ~/.local/state/sway-container.log
  4. Only when (3) works — switch the login screen:
       sudo systemctl disable sddm && sudo systemctl enable greetd && sudo reboot

  Rollback at any time:
       sudo systemctl disable greetd && sudo systemctl enable --now sddm
EOF
