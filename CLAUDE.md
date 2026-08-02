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

# Cloud VM bootstrap for the remote/waypipe container
sudo ./vm-pre-req.sh
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
| **pi** | pi.dev agent config + hand-written extensions — see below |

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

### pi (pi.dev agent)

`pi/.pi/` deploys to `~/.pi/`. Only hand-written config is tracked; pi's own state
stays in `$HOME`:

| Tracked | Not tracked (see `.gitignore`) |
|---------|-------------------------------|
| `agent/settings.json` — packages, default provider/model | `agent/auth.json` — credential store |
| `agent/extensions/permission-gate.ts` — bash/write gate | `agent/sessions/` — transcripts (work content) |
| `agent/extensions/claude-code-aliases.ts` | `agent/npm/`, `agent/bin/` — fetched by pi |
| `agent/extensions/sandbox.json` — network/fs allowlist | `agent/extensions/sandbox/` — vendored upstream example |
| `web-search.json` | |

Two things this package depends on:

- **`--no-folding` in `.stowrc` is load-bearing.** It keeps `~/.pi/agent/` a real
  directory with per-file symlinks. Fold it and `~/.pi` becomes one symlink into this
  repo — pi would then write `auth.json` and `sessions/` **into a public checkout**.
- **`settings.json` is mutable.** pi rewrites it with a plain `writeFileSync`
  (no temp-file-and-rename), so it writes *through* the symlink and the link survives —
  but `pi install` and version bumps (`lastChangelogVersion`) will show up as repo diffs.

`permission-gate.ts` blocks rather than prompts when there is no UI (`ctx.hasUI`
false), so any non-interactive caller hits a hard deny on a flagged command.

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

### Remote Container (cloud VM + waypipe)

`.host/containers/arch-remote/` is a **sibling** of `arch-sway`, not a variant.
The desktop image exists to be a compositor on real hardware; this one runs
Wayland clients that are displayed elsewhere, so it has no sway/waybar/wofi, no
seatd, no `/dev/dri`, no udev, no device passthrough and no audio stack —
waypipe forwards no audio at all.

```bash
sudo ./vm-pre-req.sh                            # podman, subuid, lingering
.host/containers/arch-remote/build.sh           # prompts; --apps full|base
arch-remote-run                                 # prompts; --port, --electron
# from the laptop:
waypipe ssh -p 2222 lewis@vm alacritty
```

Both scripts are interactive when run bare and fully flag-driven otherwise
(`--yes`), so they also work from cloud-init or a systemd unit.

| Decision | Why |
|----------|-----|
| `--net=host` by default, `--net bridge` available | host netns is the chosen default; note that under it **every** port the container binds is public on the VM's address, not just sshd |
| sshd port comes from a generated drop-in, never the image | under host netns there is no translation layer, so sshd must bind the real port itself; keeping it out of the image leaves the port a runtime flag |
| The image ships **no** `Port` directive at all | sshd *accumulates* `Port` lines rather than overriding them. A `Port 22` in the image plus `Port 2222` in the drop-in makes sshd listen on both, and binding 22 collides with the VM's own sshd — taking the whole daemon down. `sshd -t` reports that config as valid, so it fails only at bind time |
| Refuses `--net host` with port 22 or any port <1024 | rootless podman cannot bind privileged ports, and 22 would collide with the VM's sshd |
| Host keys in `~/.local/share/arch-remote/ssh` | baked-in keys would ship a private key with the image; regenerating per start trips known_hosts on every restart |
| Key-only auth, `AllowUsers`, no root | the port faces the internet the moment it is published |
| `--cap-add=sys_admin` behind `--electron` | bitwarden/1password need it for their SUID sandbox; not a default on an internet-facing box |
| `loginctl enable-linger` | otherwise the container dies when you log out of the VM |

Usernames are hardcoded to `lewis` in `sshd-container.conf` and
`runtime-dir.conf`, matching the existing convention in `arch-sway`
(`container-device-groups.sh`, `sway.service`).

## Key Bindings Reference

**Sway**: Mod key = Super (Windows key), terminal = Alacritty, launcher = wofi
**Tmux**: Prefix = Ctrl+A, vim-style navigation (hjkl)
**Zsh**: Ctrl+T (sessionizer), Ctrl+H (sessionizer home), Ctrl+S (sessionizer ~/tmp)
