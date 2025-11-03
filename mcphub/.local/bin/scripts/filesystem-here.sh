#! /bin/bash
set -euo pipefail
ROOT="$(pwd -P)"
exec docker run --rm -i \
  -u "$(id -u)":"$(id -g)" \
  -v "$ROOT":"$ROOT":rw \
  -w "$ROOT" \
  mcp/filesystem \
  "$ROOT"
