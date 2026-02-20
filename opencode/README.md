# OpenCode Configuration

## MCP Servers

MCP servers are configured in `opencode.json`. Some require environment variables for secrets.

### Environment Variables Required

Set these in your shell profile (`.zshrc`, `.bashrc`, or `.profile`):

```bash
# GitHub MCP (requires a GitHub PAT with repo scope)
export GITHUB_TOKEN="github_pat_..."

# PostgreSQL MCP (Azure database)
export POSTGRES_MCP_URI="postgresql://pmadmin:<password>@pm-pgsql-03.postgres.database.azure.com:5432/pmgis"
```

### MCP Servers Included

| Server | Type | Enabled by Default | Notes |
|--------|------|-------------------|-------|
| context7 | remote | yes | Documentation search |
| github | remote | yes | Requires GITHUB_TOKEN |
| pm-hq | remote | yes | PineMedia HQ |
| fetch | local (docker) | yes | |
| time | local (docker) | yes | |
| 1password | local | no | Requires local install |
| postgres | local | no | Requires POSTGRES_MCP_URI |

### Enabling Disabled Servers

Edit `~/.config/opencode/opencode.json` and set `enabled: true` for servers you want to use.

## Skills

To add global skills, create:
```
~/.config/opencode/skills/<skill-name>/SKILL.md
```

See https://opencode.ai/docs/skills for syntax.

## Setup

After stowing, copy the config and add your secrets:

```bash
# Copy config to local location
cp ~/.dotfiles/opencode/.config/opencode/opencode.json ~/.config/opencode/opencode.json

# Add environment variables to your shell profile
echo 'export GITHUB_TOKEN="your_github_pat"' >> ~/.zshrc
echo 'export POSTGRES_MCP_URI="your_db_uri"' >> ~/.zshrc
source ~/.zshrc
```
