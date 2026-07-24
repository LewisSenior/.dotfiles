#!/bin/bash
# Steam "gaming mode": a minimal host Sway session running only Steam (Deck UI).
# Wired into the TUI login via /usr/share/wayland-sessions/steam.desktop.

if [ "$1" = "--run" ]; then
    config="$HOME/.config/sway/steam-session.conf"
    here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # sway-launch applies the NVIDIA proprietary-driver workarounds
    # (--unsupported-gpu + GBM/GLX/cursor env) when that driver is loaded.
    # Temporary: capture sway/wlroots/XWayland stderr so display crashes are debuggable.
    exec "$here/scripts/.local/bin/scripts/sway-launch" -c "$config" > "$HOME/steam-sway.log" 2>&1
fi
