# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal Linux dotfiles repository for an Arch Linux/Wayland development environment, managed using **GNU Stow** for symlink-based configuration deployment. Designed for both native Arch installations and Distrobox containerized environments.

## Deployment Commands

```bash
# Desktop host bootstrap (podman, seatd, greetd) — run on the workstation
sudo ./pre-req.sh

# Run inside container or on native Arch system
./install.sh

# Gaming environment (separate container with gamescope)
./steam.sh
```

### Manual Stow Operations

From the repository root (`~/.dotfiles`):
```bash
stow -D <folder>    # Remove existing symlinks
stow <folder>       # Deploy symlinks to $HOME
```

## Architecture

### Directory Structure

Each top-level directory is a stow package that deploys to `$HOME`:
- Directories containing `.config/` deploy to `~/.config/`
- Directories containing `.local/` deploy to `~/.local/`
- Other dotfiles deploy directly to `~`

### Core Components

| Directory | Purpose |
|-----------|---------|
| **nvim** | Neovim config (lazy.nvim plugin manager, Lua-based) |
| **sway** | Wayland compositor (primary WM) |
| **tmux** | Terminal multiplexer with sessionizer script |
| **zsh** | Shell config with Starship prompt |
| **alacritty** | GPU-accelerated terminal |
| **waybar** | Status bar (jsonc config) |
| **scripts** | Custom utilities in `~/.local/bin/scripts/` |

### Neovim Plugin Architecture

Plugins are defined in `/nvim/.config/nvim/lua/lewis/plugins/` as modular Lua specs:
- `lsp.lua` - Mason-managed LSP servers (intelephense, basedpyright, bashls)
- `telescope.lua` - Fuzzy finder
- `harpoon.lua` - Quick file navigation
- `copilot.lua`, `codecompanion.lua` - AI assistance
- Leader key: Space

### Custom Scripts

Located in `scripts/.local/bin/scripts/`:
- `tmux-sessionizer` - Fuzzy project session launcher (searches ~/PineMedia, ~/cyberscape, ~/.dotfiles, ~/, ~/tmp)
- `sway-launch` - Sway wrapper applying the NVIDIA proprietary-driver workarounds
- `callmix-setup.sh` - PipeWire virtual audio sink for call recording

### Container Architecture

The containerized sway desktop (`.host/`) runs on rootless podman, not Distrobox:
- `--systemd=always --userns=keep-id --user 0` — full systemd as PID 1
- GPU via NVIDIA Container Toolkit / CDI (`--device nvidia.com/gpu=all`)
- Input via host `seatd` (fds passed over the socket); `/dev/input` is
  deliberately never mounted, so container apps cannot read raw evdev
- USB hotplug via a udev-maintained staging dir — see below

### USB Hotplug Passthrough

podman resolves devices at `podman run` time, so anything plugged in later is
invisible to a running container. Two halves work around this:

| Piece | Runs on | Role |
|-------|---------|------|
| `.host/udev/99-container-devices.rules` | host | allowlists device classes |
| `.host/bin/container-device-export` | host | mknods staged nodes into `/run/container-devices` + ACLs them to your uid |
| `.host/systemd/container-devices.service` | host | mounts the staging tmpfs at boot, replays what's already plugged in |
| `.host/containers/arch-sway/container-device-mirror.sh` | container | bind-mounts staged nodes onto their real `/dev` paths |

Allowlist: USB bus nodes, hidraw, USB serial (`ttyUSB*`/`ttyACM*`), webcams,
USB storage. To add a class, edit the `.rules` file — but read the security
note at the top of `container-device-export` first.


## Key Bindings Reference

**Sway**: Mod key = Super (Windows key), terminal = Alacritty, launcher = wofi
**Tmux**: Prefix = Ctrl+A, vim-style navigation (hjkl)
**Zsh**: Ctrl+T (sessionizer), Ctrl+H (sessionizer home), Ctrl+S (sessionizer ~/tmp)
