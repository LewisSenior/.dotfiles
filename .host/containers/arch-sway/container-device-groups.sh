#!/bin/bash
# Give the desktop user access to the HOST device nodes/sockets bind-mounted
# into the container. Their GIDs are the host's and don't match Arch's group
# GIDs, so create matching groups on the fly and add the user to them. Runs as
# root (system oneshot) before sway.service.
set -u
USER_NAME=lewis

for path in /dev/dri/* /dev/input/event* /run/seatd.sock; do
    [ -e "$path" ] || continue
    gid="$(stat -c %g "$path" 2>/dev/null)" || continue
    [ "$gid" = 0 ] && continue                      # root-owned: user access N/A

    gname="$(getent group "$gid" | cut -d: -f1)"
    if [ -z "$gname" ]; then
        gname="hostdev$gid"
        groupadd -g "$gid" "$gname" 2>/dev/null || true
    fi
    id -nG "$USER_NAME" | tr ' ' '\n' | grep -qx "$gname" \
        || usermod -aG "$gname" "$USER_NAME"
done
