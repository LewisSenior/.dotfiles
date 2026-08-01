#!/bin/bash
# Build the remote (cloud VM) container image. Run as your user, not root.
#
# Interactive by default — run it bare and it asks. Every prompt has a flag, so
# it is also safe in cloud-init or CI:
#     ./build.sh --apps base --yes
set -Eeuo pipefail
cd "$(dirname "$0")"

IMAGE=localhost/arch-remote
APPS=""
ASSUME_YES=0

usage() {
    cat <<EOF
usage: ./build.sh [options]

  --apps full|base   full: + firefox, bitwarden, 1password, wl-clipboard
                     base: dev tooling, alacritty, waypipe, sshd only
  --image NAME       image tag to build (default: $IMAGE)
  -y, --yes          non-interactive; use defaults for anything not given
  -h, --help         this

With no options it prompts. 'full' is a much larger build — on a small or
metered VM 'base' comes up far faster, and you can add applications later with
pacman/yay from inside the container.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --apps)  APPS="${2:-}"; shift 2 ;;
        --image) IMAGE="${2:-}"; shift 2 ;;
        -y|--yes) ASSUME_YES=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1 (try --help)" >&2; exit 2 ;;
    esac
done

if [ -z "$APPS" ]; then
    if [ "$ASSUME_YES" = 1 ] || [ ! -t 0 ]; then
        APPS=full
    else
        echo "Application set:"
        echo "  1) full  — dev tooling + firefox, bitwarden, 1password (large build)"
        echo "  2) base  — dev tooling, alacritty, waypipe, sshd (fast)"
        read -rp "choose [1]: " reply || true
        case "${reply:-1}" in
            2|base) APPS=base ;;
            *)      APPS=full ;;
        esac
    fi
fi
case "$APPS" in
    full|base) ;;
    *) echo "--apps must be 'full' or 'base' (got: $APPS)" >&2; exit 2 ;;
esac

# containers.conf sets image_copy_tmp_dir="storage"; podman does not create
# that directory itself, and the first layer commit dies without it. Same
# workaround as the desktop image's build.sh. Harmless when unset.
graphroot="$(podman info -f '{{.Store.GraphRoot}}')"
mkdir -p "$graphroot/tmp"

echo "==> building $IMAGE (apps=$APPS)"
exec podman build --build-arg APPS="$APPS" -t "$IMAGE" .
