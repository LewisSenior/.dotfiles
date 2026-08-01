#!/bin/bash
# CONTAINER half of the hotplug device passthrough. Runs as root (system unit)
# inside the arch-sway container; see .host/bin/container-device-export for the
# host half and the security note on the allowlist.
#
# The host stages device nodes into a tmpfs bind-mounted here as
# /run/host-devices. That directory is live — nodes appear in it the moment a
# device is plugged in, container already running — but applications look for
# devices at their real paths (libusb wants /dev/bus/usb/003/002, a udev
# DEVNAME says /dev/hidraw0). So this daemon watches the staging dir and
# projects each node onto its /dev path, and tears it down again on unplug.
#
# Projection is a bind-mount rather than a mknod: creating device nodes inside
# a user namespace is refused by the kernel, whereas bind-mounting an existing
# node over a placeholder file is not. It relies on CAP_SYS_ADMIN, which the
# session already grants (see sway-container-session); if that ever goes away
# we fall back to a symlink, which open() follows just as well but which
# anything doing lstat()+S_ISCHR on the path will reject.
set -u

SRC=/run/host-devices

log() { printf 'container-device-mirror: %s\n' "$*"; }

# Everything currently staged, as paths relative to $SRC ("hidraw0",
# "bus/usb/003/002"). -mindepth 1 keeps the start point itself out.
staged() {
    find "$SRC" -mindepth 1 \( -type c -o -type b \) -printf '%P\n' 2>/dev/null
}

mirror() {
    local rel="$1" src="$SRC/$rel" dst="/dev/$rel"
    [ -e "$src" ] || return 0
    # Never touch a path /dev already provides — the container's own null,
    # zero, dri/*, nvidia* and friends are not ours to replace.
    [ -e "$dst" ] && return 0

    mkdir -p "$(dirname "$dst")" 2>/dev/null || return 0
    : > "$dst" 2>/dev/null || return 0          # placeholder to bind over
    if mount --bind "$src" "$dst" 2>/dev/null; then
        return 0
    fi
    rm -f "$dst"
    if ln -sfn "$src" "$dst" 2>/dev/null; then
        log "bind-mount refused for $dst, fell back to a symlink (is --cap-add=sys_admin still set?)"
        return 0
    fi
    log "could not project $dst"
    return 1
}

unmirror() {
    local rel="$1" dst="/dev/$rel"
    mountpoint -q "$dst" 2>/dev/null && umount "$dst" 2>/dev/null
    rm -f "$dst" 2>/dev/null
    # Drop the directories an unplugged device leaves empty (/dev/bus/usb/003).
    local dir
    dir="$(dirname "$dst")"
    while [ "$dir" != /dev ] && [ -d "$dir" ]; do
        rmdir "$dir" 2>/dev/null || break
        dir="$(dirname "$dir")"
    done
}

# rel path -> 1 for everything this daemon put into /dev. Tracked explicitly so
# teardown only ever removes our own projections.
declare -A MIRRORED=()

sync_all() {
    local rel
    local -A present=()
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        present["$rel"]=1
        [ -n "${MIRRORED[$rel]:-}" ] && continue
        mirror "$rel" && MIRRORED["$rel"]=1
    done < <(staged)

    for rel in "${!MIRRORED[@]}"; do
        [ -n "${present[$rel]:-}" ] && continue
        unmirror "$rel"
        unset 'MIRRORED[$rel]'
    done
}

[ -d "$SRC" ] || { log "$SRC is missing — host side not installed; nothing to do"; exit 0; }

sync_all

# --once: the ExecStartPre pass. Ordering sway.service after this unit then
# guarantees devices already plugged in at boot are in place before the desktop
# starts, instead of racing the watcher below.
[ "${1:-}" = "--once" ] && exit 0

if command -v inotifywait >/dev/null 2>&1; then
    # Process substitution, not a pipe: a pipe would run the loop in a subshell
    # and strand every MIRRORED update there. -r picks up directories created
    # later (a new /run/host-devices/bus/usb/004) on its own.
    while IFS= read -r _; do
        sync_all
    done < <(inotifywait -q -m -r -e create -e delete -e moved_to -e moved_from "$SRC" 2>/dev/null)
    log "inotify watch ended unexpectedly"
    exit 1
fi

log "inotifywait not found — falling back to polling"
while sleep 2; do
    sync_all
done
