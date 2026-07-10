# AGENTS.md - Dotfiles Repository Guidelines

This is a dotfiles repository managed by GNU Stow. It contains configuration files for various tools.

## Repository Structure

```
.dotfiles/
├── .stowrc                # Stow defaults: --target=$HOME --no-folding
├── .attic/                # Retired configs (NOT stowed; kept for reference)
├── .host/                 # Debian HOST files (NOT stowed; installed by pre-req.sh)
│   ├── containers/arch-sway/   # Containerfile + build.sh for the desktop image
│   ├── bin/sway-container-session  # greetd session launcher (→ /usr/local/bin)
│   └── greetd/config.toml      # TUI greeter config (→ /etc/greetd)
├── pre-req.sh             # Debian host setup: podman, seatd, greetd/tuigreet
├── install.sh             # Deploys all configs using stow
├── alacritty/             # Terminal emulator config (yml = live on 0.11, toml = post-0.13)
├── environment.d/         # systemd user-session environment
├── git/                   # Git identity, signing, credential helper
├── kanshi/                # Display manager config
├── mcphub/                # MCP server configs (JSON)
├── nvim/                  # Neovim configuration (Lua)
├── onedrive/              # OneDrive config
├── pgsql/                 # PostgreSQL config (.psqlrc + pgc connection manager)
├── pipewire/              # Audio config
├── profile/               # Login-shell profile (session PATH)
├── ranger/                # File manager config
├── ssh/                   # SSH config (local-only; tracked as config.example)
├── starship/              # Prompt config
├── sway/                  # Wayland compositor config
├── systemd/               # systemd user units (kanshi)
├── tmux/                  # Terminal multiplexer config
├── waybar/                # Status bar config
├── wireplumber/           # Audio pipeline config
├── xwork/                 # xwork agent environment
└── zsh/                   # Shell config (.zshenv owns PATH for zsh)
```

Stow runs with `--no-folding` (via `.stowrc`): target directories are real
directories with per-file symlinks, so programs writing runtime files into
`~/.config/<tool>` do not leak them into this repo. PATH is defined in
`zsh/.zshenv` (all zsh instances) and mirrored in `profile/.profile` for the
graphical login session — do not add PATH exports to `.zshrc`.

## Desktop Architecture (containerized sway)

The Debian host is a thin boot shim; the desktop is an Arch container:

```
boot → greetd (vt1, tuigreet TUI) → sway-container-session (as user)
        └─ rootless podman run localhost/arch-sway → dbus-run-session sway
```

- Seat management: **seatd on the host**, socket bind-mounted in; sway uses
  `LIBSEAT_BACKEND=seatd` (DRM-master/input fds arrive over the socket).
- Host keeps: greetd, seatd, podman, pipewire/wireplumber (socket shared in).
  SDDM remains installed-but-disabled as the rollback login screen.
- Greeter fallback: tuigreet lists host `sway.desktop` (`--sessions`) so a
  broken container can be sidestepped by picking host-native sway at login;
  the container launcher stays the default (`--cmd`).
- `$HOME` is bind-mounted, so all stowed configs apply inside the container.
- Rebuild the image after changing its package list:
  `.host/containers/arch-sway/build.sh`
- Rollback: `sudo systemctl disable greetd && sudo systemctl enable --now sddm`

## Build/Deploy Commands

### Deploy Dotfiles
```bash
./install.sh
```
This runs `stow` to symlink all config folders to `~/.dotfiles`. Run from the repository root.

### Local-only files (*.example convention)
This repo is public. Files containing sensitive values (IPs, hostnames,
usernames, credentials) are never committed. The repo tracks a redacted
`<file>.example` instead; `install.sh` copies it to `<file>` on first run
if missing, and the real file is gitignored. Currently: `ssh/.ssh/config`.
Never commit the real files or put real infrastructure values in the
`.example` templates.

### Single Config Deployment
```bash
stow -D <folder>  # Remove stow links for folder
stow <folder>     # Create stow links for folder
```

### No Tests or Linting
This is a configuration repository - there are no build commands, tests, or linters.
Configuration files are validated by the tools that use them (Neovim, Sway, etc.).

## Code Style Guidelines

### General Principles
- Use 4 spaces for indentation in all config files
- Keep files organized and well-commented
- Group related settings together
- Use descriptive names for variables and keys

### Neovim (Lua) - nvim/.config/nvim/lua/

**File Organization:**
- `init.lua` - Main entry point, loads other modules
- `remap.lua` - Key mappings
- `opt.lua` - Vim options
- `myconfig.lua` - User preferences
- `lazy/` - Plugin configurations

**Lua Conventions:**
- Use snake_case for variables and functions
- Use `vim.keymap.set()` for key mappings (not `nnoremap`)
- Use `require("module")` for module loading
- Prefer `local` variables over global
- Use double quotes for strings
- Add `{ noremap = true, silent = true }` to keymaps

**Example keymap pattern:**
```lua
vim.keymap.set("n", "<leader>gd", "<cmd>Telescope lsp_definitions<cr>")
vim.keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>", { noremap = true, silent = true })
```

**LSP Configuration:**
- Use `vim.lsp.config[]` for new-style config (Neovim 0.10+)
- Use `on_attach` function for buffer-local keymaps
- Include `capabilities` from `cmp_nvim_lsp`

### Sway Config - sway/.config/sway/config

**Structure:**
- Variables at top (`$mod`, `$term`, `$menu`)
- Output configuration
- Input configuration
- Key bindings organized by category
- Include statements at end

**Conventions:**
- Use vim-like keybindings (h/j/k/l for direction)
- Use `$mod` (Super/Win) as modifier
- Comment sections clearly
- Group related bindsyms together
- Use `exec_always` for persistent background apps
- Use `exec` for startup apps

### Zsh - zsh/.zshrc

**Conventions:**
- Standard zsh syntax
- Use `eval` for complex initializations
- Define aliases after loading nvm/completions
- Keep PATH exports organized
- Use `[[ ]]` for conditionals, not `[ ]`

### MCP Server Config - mcphub/test

**Format:** JSON (MCP JSON schema)

**Conventions:**
- Standard JSON formatting
- 2-space indentation
- Properties: `command`, `args`, `env`, `disabled`
- Use `disabled: true` to disable a server without removing config

### Shell Scripts

**Conventions:**
- Use `#!/bin/bash` or `#!/usr/bin/env bash`
- Use `set -e` for strict mode where appropriate
- Quote variables: `"$VAR"` not `$VAR`
- Use `[[ ]]` for bash conditionals
- Check command success with `|| exit 1` where critical

## Common Patterns

### Key Mapping Leader
- Use space as leader: `vim.g.mapleader = " "`
- Prefix personal mappings with `<leader>`

### Plugin Setup Pattern
```lua
require("plugin-name").setup({
    -- config table
})
```

### Testing Changes
After modifying Neovim config:
1. Run `:source %` in Neovim to reload current file
2. Or restart Neovim to load all changes

After modifying Sway config:
1. Run `swaymsg reload` to reload without logging out

## pgc - PostgreSQL Connection Manager

`pgc` is a CLI wrapper around `psql` that stores named server aliases backed by 1Password.
Credentials are never stored locally — they are fetched from 1Password at connect time via `op`.

Config: `~/.config/pgc/servers.json`

### Querying a database

```bash
# List available servers
pgc ls --json

# Show connection details for a server (without connecting)
pgc show <name> --json

# Run a SQL query non-interactively
pgc <name> -- -c 'SELECT count(*) FROM users'

# Run a query with raw output (no headers, no alignment)
pgc <name> -- -A -t -c 'SELECT version()'

# Get connection URI
pgc uri <name>
```

### Managing servers

```bash
# Add a server (non-interactive, for scripts/agents)
pgc add --name <alias> --op-item <1password-item-id> --vault <vault-name> --env <production|testing>

# Edit a server
pgc edit <name> --env testing
pgc edit <name> --op-item <new-id> --vault <new-vault>

# Remove a server
pgc rm <name>
```

### Important notes
- `pgc <name>` with no `-- -c` args opens an **interactive** psql session — do not use this from agents
- Always use `pgc <name> -- -c 'SQL'` for non-interactive queries
- Use `--json` flag on `ls` and `show` for machine-readable output
- The `--env` field (`production` or `testing`) controls the tmux status bar colour indicator

## File Paths

Configs are symlinked from `~/.dotfiles/` to their standard locations:
- Neovim: `~/.config/nvim/`
- Sway: `~/.config/sway/`
- Zsh: `~/.zshrc`
- Alacritty: `~/.config/alacritty/`
