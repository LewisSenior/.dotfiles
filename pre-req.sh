#!/bin/bash
# Host (Debian) setup for the containerized sway desktop:
# podman (rootless) + seatd + greetd/tuigreet. Idempotent.
#
# This script does NOT switch the display manager — SDDM stays the login
# screen until you run the switch step it prints at the end, after the
# container session has been verified from a spare TTY.
set -Eeuo pipefail

# ---- diagnostics -----------------------------------------------------------
# Progress logging, an optional -v/--verbose command trace, and an ERR trap that
# names the failing line + command — so a mid-run `set -e` abort is never silent.
VERBOSE=0
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        -h|--help) echo "usage: sudo ./pre-req.sh [-v|--verbose]"; exit 0 ;;
        *) echo "unknown argument: $arg (try --help)" >&2; exit 2 ;;
    esac
done
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
trap 'rc=$?; printf "\033[1;31mERROR\033[0m pre-req.sh aborted at line %s (exit %s) running: %s\n" "$LINENO" "$rc" "$BASH_COMMAND" >&2' ERR
[ "$VERBOSE" = 1 ] && { log "verbose: tracing every command"; set -x; }
# ----------------------------------------------------------------------------

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="$DOTFILES/.host"
ME="${SUDO_USER:-$USER}"

# Wait up to 5 min for the dpkg lock rather than aborting if a background apt
# (e.g. unattended-upgrades) is mid-run. Unquoted on use so it word-splits.
APTLOCK="-o DPkg::Lock::Timeout=300"

[[ $EUID -eq 0 ]] || { echo "run with sudo: sudo ./pre-req.sh"; exit 1; }
[[ -n "${SUDO_USER:-}" ]] || { echo "run via sudo from your user, not a root shell"; exit 1; }

# Keep sddm the default DM through greetd's install-time debconf question
echo "greetd shared/default-x-display-manager select sddm" | debconf-set-selections || true

log "Installing base packages (podman, crun, seatd, greetd, stow, gnupg …)"
DEBIAN_FRONTEND=noninteractive apt-get $APTLOCK install -y \
    podman crun uidmap slirp4netns dbus-user-session fuse-overlayfs \
    seatd greetd stow gnupg

# tuigreet: trixie/main ships a current (0.9.x) build, but bookworm/main only
# has the buggy 0.7.x that panics ('invalid key'), so on bookworm pull it from
# backports. Pick the source per the running release rather than hardcoding it.
log "Installing tuigreet (greeter)"
codename="$(. /etc/os-release; echo "${VERSION_CODENAME:-}")"
# Capture then match with a herestring: `apt-cache ... | grep -q` would SIGPIPE
# apt-cache (grep -q exits on first match), and under `pipefail` that makes the
# whole `if` false regardless of the match.
tg_policy="$(apt-cache policy tuigreet 2>/dev/null || true)"
if grep -q "${codename}-backports" <<<"$tg_policy"; then
    DEBIAN_FRONTEND=noninteractive apt-get $APTLOCK install -y -t "${codename}-backports" tuigreet
else
    DEBIAN_FRONTEND=noninteractive apt-get $APTLOCK install -y tuigreet
fi

# Belt and braces: if greetd's postinst grabbed display-manager anyway, undo it
# — but ONLY when sddm actually exists to hand it back to. On a host where
# greetd is already the (only) display manager, sddm isn't installed; disabling
# greetd here would leave no DM at all, and `systemctl enable sddm` would fail
# outright (non-idempotent). So gate the whole restore on sddm being present.
current_dm="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" || true)"
if [[ "$current_dm" == "greetd.service" ]] && systemctl cat sddm.service >/dev/null 2>&1; then
    systemctl disable greetd >/dev/null 2>&1 || true
    systemctl enable sddm >/dev/null
    echo "note: restored sddm as display-manager; greetd stays off until you switch"
fi

log "Enabling seatd"
systemctl enable --now seatd

log "Adding $ME to groups: render/input/seat (+pipewire if present)"
# Group memberships: render/input for device nodes in the rootless container,
# plus whatever group owns the seatd socket. Add pipewire too when present, so
# the user picks up its RT limits (95-pipewire.conf: rtprio 95, nice -19) — the
# rootless-safe way to give the containerized sway realtime scheduling.
seatd_group="$(stat -c %G /run/seatd.sock)"
extra_groups="render,input,$seatd_group"
getent group pipewire >/dev/null && extra_groups="$extra_groups,pipewire"
usermod -aG "$extra_groups" "$ME"

log "Writing greetd config"
# greetd config — fix the greeter user to whatever the Debian package created
greeter_user="_greetd"
getent passwd "$greeter_user" >/dev/null || greeter_user="greeter"
getent passwd "$greeter_user" >/dev/null || { echo "ERROR: no greetd greeter user found"; exit 1; }
sed "s/^user = .*/user = \"$greeter_user\"/" "$HOST/greetd/config.toml" > /etc/greetd/config.toml
chmod 644 /etc/greetd/config.toml

# The installed config pins /usr/local/bin/tuigreet (see the note in
# config.toml). If nothing put a binary there but a packaged/built tuigreet is
# on PATH, symlink it so the greeter actually launches — otherwise greetd would
# fail 'command not found' on next boot. A real hand-built binary is left alone.
if [[ ! -e /usr/local/bin/tuigreet ]] && command -v tuigreet >/dev/null; then
    ln -s "$(command -v tuigreet)" /usr/local/bin/tuigreet
    echo "linked /usr/local/bin/tuigreet -> $(command -v tuigreet)"
fi

log "Installing greetd session menu + host session binary + sway-launch"
# Session menu: exactly two entries (containerized + host sway), plus an empty
# xsessions dir so tuigreet doesn't also list /usr/share/xsessions.
install -d -m 755 /etc/greetd/sessions /etc/greetd/xsessions
install -m 644 "$HOST/greetd/sessions/"*.desktop /etc/greetd/sessions/

install -m 755 "$HOST/bin/sway-container-session" /usr/local/bin/sway-container-session
install -m 755 "$HOST/bin/sway-steam-session" /usr/local/bin/sway-steam-session

# Host-native sway launcher (used by the "Sway (host)" greetd session): applies
# the NVIDIA proprietary-driver workarounds when that driver is loaded.
# (nvidia_drm.modeset=1, which sway needs, is set by the nvidia driver packaging
# in /etc/modprobe.d — not managed here. sway-launch warns at runtime if KMS
# isn't active.)
install -m 755 "$DOTFILES/scripts/.local/bin/scripts/sway-launch" /usr/local/bin/sway-launch

# NVIDIA Container Toolkit (CDI): lets the containerized desktop use the GPU via
# `--device nvidia.com/gpu=all` (see sway-container-session). Only on NVIDIA
# hosts. The toolkit mounts the host's matching driver userspace into the image,
# so the image needs no nvidia packages. A boot-time root unit regenerates the
# CDI spec into /etc/cdi (podman's default, root-only scan dir — rootless podman
# does not honour a user-provided cdi_spec_dirs override) so it always matches
# the running driver.
#
# Gate on the loaded driver via sysfs/proc, NOT `lspci | grep -q`: under
# `pipefail`, grep -q closes the pipe early and SIGPIPEs lspci, so the pipeline
# returns non-zero and the whole block silently skips even on an NVIDIA host.
if [ -e /proc/driver/nvidia/version ] || [ -d /sys/module/nvidia ]; then
    log "NVIDIA GPU detected — setting up the Container Toolkit / CDI"
    if ! command -v nvidia-ctk >/dev/null; then
        # Add NVIDIA's libnvidia-container apt repo ONLY if the toolkit isn't
        # already installable. Hosts with the CUDA/driver repo already ship it,
        # and adding a second source can fail where the first doesn't (e.g. a
        # proxy that's present in your interactive shell but not under sudo).
        tk_policy="$(apt-cache policy nvidia-container-toolkit 2>/dev/null || true)"
        if grep -q 'Candidate: [0-9]' <<<"$tk_policy"; then
            log "nvidia: toolkit already available from a configured repo; skipping repo-add"
        else
            log "nvidia: adding the libnvidia-container apt repo"
            install -d -m 755 /usr/share/keyrings
            curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
                | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
            curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
                | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
                > /etc/apt/sources.list.d/nvidia-container-toolkit.list
            apt-get $APTLOCK update
        fi
        log "nvidia: installing nvidia-container-toolkit"
        DEBIAN_FRONTEND=noninteractive apt-get $APTLOCK install -y nvidia-container-toolkit
    else
        log "nvidia: nvidia-ctk already installed ($(nvidia-ctk --version 2>/dev/null | head -1 || true))"
    fi
    # Boot-time regeneration unit, and generate once now so this boot has a spec
    # without waiting for a reboot.
    log "nvidia: installing + enabling the boot-time CDI refresh service"
    install -m 644 "$HOST/systemd/nvidia-cdi-refresh.service" /etc/systemd/system/nvidia-cdi-refresh.service
    systemctl daemon-reload
    systemctl enable nvidia-cdi-refresh.service >/dev/null 2>&1 || true
    log "nvidia: generating CDI spec -> /etc/cdi/nvidia.yaml"
    install -d -m 755 /etc/cdi
    if nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml; then
        log "nvidia: CDI ready; GPU injected via '--device nvidia.com/gpu=all'"
    else
        warn "initial CDI generate failed; the refresh unit will retry at next boot"
    fi
fi

log "Installing rootless podman config for $ME"
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
