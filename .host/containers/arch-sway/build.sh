#!/bin/bash
# Build (or rebuild) the Arch desktop image. Run as your user, not root.
set -euo pipefail
cd "$(dirname "$0")"
exec podman build -t localhost/arch-sway .
