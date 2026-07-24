# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal Linux dotfiles repository for an Arch Linux/Wayland development environment, managed using **GNU Stow** for symlink-based configuration deployment. Designed for both native Arch installations and Distrobox containerized environments.

## Deployment Commands

```bash
# Full setup in new Distrobox container (primary method)
./pre-req.sh

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
- `input-hotplug-watch` - Device monitoring for Distrobox containers
- `callmix-setup.sh` - PipeWire virtual audio sink for call recording

### Container Architecture

Uses Distrobox with:
- `--root --init` for systemd support
- `--nvidia` for GPU pass-through
- Host device mounting via `input-hotplug-watch` script
- ACL rules in `99-distrobox-acl.rules`

## Key Bindings Reference

**Sway**: Mod key = Super (Windows key), terminal = Alacritty, launcher = wofi
**Tmux**: Prefix = Ctrl+A, vim-style navigation (hjkl)
**Zsh**: Ctrl+T (sessionizer), Ctrl+H (sessionizer home), Ctrl+S (sessionizer ~/tmp)
