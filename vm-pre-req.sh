#!/bin/bash
# Cloud VM (Debian/Ubuntu) bootstrap for the REMOTE container — the waypipe
# target. Sibling of pre-req.sh, which bootstraps the desktop host; this one
# installs no compositor, no seatd, no greetd and no device passthrough,
# because a VM has no display, no input and no GPU to pass through.
#
# Idempotent. Run it with sudo from your normal user:
#     sudo ./vm-pre-req.sh
set -Eeuo pipefail

VERBOSE=0
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        -h|--help) echo "usage: sudo ./vm-pre-req.sh [-v|--verbose]"; exit 0 ;;
        *) echo "unknown argument: $arg (try --help)" >&2; exit 2 ;;
    esac
done
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
trap 'rc=$?; printf "\033[1;31mERROR\033[0m vm-pre-req.sh aborted at line %s (exit %s) running: %s\n" "$LINENO" "$rc" "$BASH_COMMAND" >&2' ERR
[ "$VERBOSE" = 1 ] && { log "verbose: tracing every command"; set -x; }

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="$DOTFILES/.host"
ME="${SUDO_USER:-$USER}"
APTLOCK="-o DPkg::Lock::Timeout=300"

[[ $EUID -eq 0 ]] || { echo "run with sudo: sudo ./vm-pre-req.sh"; exit 1; }
[[ -n "${SUDO_USER:-}" ]] || { echo "run via sudo from your user, not a root shell"; exit 1; }

log "Installing packages (podman, rootless networking, stow …)"
DEBIAN_FRONTEND=noninteractive apt-get $APTLOCK update
# passt provides pasta, the rootless network backend podman 5 prefers;
# slirp4netns is the older one. Install whichever the release actually has so
# published ports work either way.
net_backends=""
for p in passt slirp4netns; do
    apt-cache policy "$p" 2>/dev/null | grep -q 'Candidate: [0-9]' && net_backends="$net_backends $p"
done
[ -n "$net_backends" ] || warn "neither passt nor slirp4netns available; rootless port publishing may fail"
# shellcheck disable=SC2086
DEBIAN_FRONTEND=noninteractive apt-get $APTLOCK install -y \
    podman crun uidmap dbus-user-session fuse-overlayfs stow git $net_backends

# Rootless podman needs a subuid/subgid range. Debian allocates one when it
# creates a user, but cloud images frequently ship a pre-made user (root,
# debian, ubuntu) that has none — and podman then fails with a bare "no subuid
# ranges found" that is not obviously about this.
if ! grep -q "^$ME:" /etc/subuid 2>/dev/null; then
    log "Allocating subuid/subgid range for $ME"
    usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$ME"
else
    log "subuid range already present for $ME"
fi

# Without lingering, the user's systemd instance is torn down at logout and
# takes the container with it — so the box you just ssh'd out of stops serving
# waypipe. This is the difference between a VM that survives a disconnect and
# one that does not.
log "Enabling lingering for $ME (container survives logout/reboot)"
loginctl enable-linger "$ME" || warn "could not enable lingering; container will stop at logout"

log "Installing rootless podman config for $ME"
user_home="$(getent passwd "$ME" | cut -d: -f6)"
install -d -o "$ME" -g "$ME" -m 755 "$user_home/.config/containers"
for cfg in storage.conf containers.conf; do
    dest="$user_home/.config/containers/$cfg"
    if [[ -e "$dest" ]]; then
        echo "note: $dest exists, leaving it as-is"
    else
        install -o "$ME" -g "$ME" -m 644 "$HOST/containers-config/$cfg" "$dest"
        echo "installed $dest"
    fi
done

log "Installing arch-remote-run"
install -m 755 "$HOST/bin/arch-remote-run" /usr/local/bin/arch-remote-run

log "Installing the user service (starts the container at boot)"
unit_dir="$user_home/.config/systemd/user"
install -d -o "$ME" -g "$ME" -m 755 "$unit_dir"
install -o "$ME" -g "$ME" -m 644 \
    "$HOST/containers/arch-remote/arch-remote.service" "$unit_dir/arch-remote.service"

cat <<EOF

VM setup complete. Next steps, as $ME (not root):

  1. Make sure your laptop's public key is in ~/.ssh/authorized_keys.
     The container is public-key ONLY — without this you cannot get in.

  2. Build the image (use --apps base on a small or metered VM):
       $HOST/containers/arch-remote/build.sh

  3. Start it:
       arch-remote-run
     or have it start at boot:
       systemctl --user enable --now arch-remote.service

  4. Open the port in your provider's firewall (DigitalOcean Cloud Firewall,
     Hetzner Firewall) AND in any local one:
       sudo ufw allow 2222/tcp      # if ufw is in use

  5. From your laptop:
       waypipe ssh -p 2222 $ME@<vm-address> alacritty

  Note: the VM's own sshd keeps port 22. The container's sshd is published
  separately, so locking yourself out of the container never locks you out of
  the VM.
EOF
