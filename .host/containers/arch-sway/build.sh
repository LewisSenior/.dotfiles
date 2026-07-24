#!/bin/bash
# Build (or rebuild) the Arch desktop image. Run as your user, not root.
set -euo pipefail
cd "$(dirname "$0")"

# containers.conf sets image_copy_tmp_dir="storage", which stages layer temp
# data in <graphroot>/tmp. podman does NOT create that dir on its own, so
# without this the first layer commit dies at "creating a temporary directory:
# stat <graphroot>/tmp: no such file or directory". Idempotent.
graphroot="$(podman info -f '{{.Store.GraphRoot}}')"
mkdir -p "$graphroot/tmp"

# Optional: set a sudo password for the in-container user. Leave blank to keep
# passwordless sudo. Passed to the build as a secret (podman --secret), so it
# is baked only into the LOCAL image's /etc/shadow — never into a build layer
# or the (public) repo. Only prompts on an interactive terminal.
SUDOPW=""
if [ -t 0 ]; then
    read -rsp "Container sudo password (blank = passwordless sudo): " SUDOPW || true
    echo
fi

# Fresh cache-bust every build: build secrets aren't part of the layer cache
# key, so without this the (cached) password step wouldn't reflect a changed
# or removed password. It's the last layer, so re-running it is cheap.
epoch="$(date +%s)"

if [ -n "$SUDOPW" ]; then
    export SUDOPW
    exec podman build --secret id=sudopw,env=SUDOPW \
        --build-arg SUDOPW_EPOCH="$epoch" -t localhost/arch-sway .
fi
exec podman build --build-arg SUDOPW_EPOCH="$epoch" -t localhost/arch-sway .
