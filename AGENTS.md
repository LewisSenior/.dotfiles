# AGENTS.md - Dotfiles Repository Guidelines

This is a dotfiles repository managed by GNU Stow. It contains configuration files for various tools.

## Repository Structure

```
.dotfiles/
├── install.sh              # Deploys all configs using stow
├── alacritty/              # Terminal emulator config
├── kanshi/                 # Display manager config
├── mcphub/                 # MCP server configs (JSON)
├── nvim/                   # Neovim configuration (Lua)
├── onedrive/              # OneDrive config
├── pipewire/              # Audio config
├── powershell/            # PowerShell config
├── profile/               # Profile scripts
├── ranger/                # File manager config
├── rofi/                  # App launcher config
├── ssh/                   # SSH config
├── starship/              # Prompt config
├── sway/                  # Wayland compositor config
├── tmux/                  # Terminal multiplexer config
├── waybar/                # Status bar config
├── wireplumber/           # Audio pipeline config
├── xinitrc/               # X11 init config
├── xmodmap/               # Keyboard mapping
├── xmonad/                # Window manager config
└── zsh/                   # Shell config
```

## Build/Deploy Commands

### Deploy Dotfiles
```bash
./install.sh
```
This runs `stow` to symlink all config folders to `~/.dotfiles`. Run from the repository root.

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

## File Paths

Configs are symlinked from `~/.dotfiles/` to their standard locations:
- Neovim: `~/.config/nvim/`
- Sway: `~/.config/sway/`
- Zsh: `~/.zshrc`
- Alacritty: `~/.config/alacritty/`
