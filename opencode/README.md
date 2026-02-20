# OpenCode Configuration

## MCP Servers

MCP servers are configured in `opencode.json`. After stowing, add your secrets:

```bash
# Edit the config to add API keys, tokens, etc.
nvim ~/.config/opencode/opencode.json
```

## Skills

To add global skills, create:
```
~/.config/opencode/skills/<skill-name>/SKILL.md
```

See https://opencode.ai/docs/skills for syntax.

## Example MCP Config

The included `opencode.json` shows example configs. Copy it to your local config and add secrets:

```bash
cp ~/.dotfiles/opencode/.config/opencode/opencode.json ~/.config/opencode/opencode.json
# Then edit to add your API keys/tokens
```
