# Claude Code Configuration

This directory contains Claude Code configuration that is automatically synced via home-manager.

## Directory Structure

```
dotfiles/claude/
├── README.md              # This file
├── CLAUDE.md              # Project-specific instructions for Claude Code
├── config-overlay.json    # Permissions and MCP server configurations
├── commands/              # Custom slash commands
├── agents/                # Custom AI agents
└── skills/                # Custom skills
```

## How Configuration Sync Works

### Automatic Sync via Home-Manager

When you run `just install-pckgs`, home-manager:

1. **Symlinks static files** to `~/.claude/`:
   - `commands/` → `~/.claude/commands/`
   - `agents/` → `~/.claude/agents/`
   - `skills/` → `~/.claude/skills/`
   - `CLAUDE.md` → `~/.claude/CLAUDE.md`

2. **Merges dynamic settings** from `config-overlay.json` into `~/.claude.json`:
   - Permissions (allow/deny rules for tools)
   - MCP servers configuration
   - Preserves runtime data (projects, tips history, etc.)
   - Creates timestamped backup before modification

### Configuration Files

#### `config-overlay.json`

Contains only the settings you want to version control:

- **permissions**: Tool access rules
  - `allow`: Permitted tool patterns (e.g., `Read(*)`, `WebFetch(https://docs.*.com/*)`)
  - `deny`: Blocked tool patterns (e.g., `WebFetch(localhost:*)`)

- **mcpServers**: MCP server configurations
  - Server name and command
  - Arguments and environment variables
  - Connection settings

**Example:**
```json
{
  "permissions": {
    "allow": ["Read(*)", "WebSearch(*)"],
    "deny": ["WebFetch(localhost:*)"]
  },
  "mcpServers": {
    "gdrive": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-gdrive"],
      "env": {
        "GDRIVE_CREDENTIALS_PATH": "${GDRIVE_CREDENTIALS_PATH}"
      }
    }
  }
}
```

#### `~/.claude.json`

Your local configuration file (NOT version controlled) that contains:
- Settings from `config-overlay.json` (auto-synced)
- Runtime data: `numStartups`, `tipsHistory`, `projects`
- Machine-specific state

## Environment Variables for MCP Servers

Some MCP servers require environment variables for credentials. These are defined in `modules/language.nix`:

```nix
home.sessionVariables = {
  # Google Drive MCP credentials
  GDRIVE_CREDENTIALS_PATH = "${config.home.homeDirectory}/dev/tonys-mcp-claude-code-credentials.json";
  GDRIVE_OAUTH_PATH = "${config.home.homeDirectory}/dev/tonys-mcp-claude-code.json";

  # KakaoPay MCP credentials
  KAKAOPAY_SECRET_KEY = "your-secret-key";
};
```

Then reference them in `config-overlay.json`:
```json
{
  "mcpServers": {
    "gdrive": {
      "env": {
        "GDRIVE_CREDENTIALS_PATH": "${GDRIVE_CREDENTIALS_PATH}"
      }
    }
  }
}
```

## Available MCP Servers

| Server | Package | Description |
|--------|---------|-------------|
| npay-payments | `@naverpay/payments-mcp` | 네이버 페이 |
| kakaopay | `@kakaopay-develop/mcp` | 카카오페이 |
| context7 | `@upstash/context7-mcp@latest` | 최신 오픈소스 조회 |
| sequential-thinking | `@modelcontextprotocol/server-sequential-thinking` | 순차적 사고 설계 |
| memory | `@modelcontextprotocol/server-memory` | 세션 간 단기 기억 |
| webresearch | `@mzxrai/mcp-webresearch@latest` | 웹 검색 |
| figma | HTTP server | 피그마 |
| gdrive | `@modelcontextprotocol/server-gdrive` | 구글 드라이브 |

## Modifying Configuration

### Add/Remove Permissions

Edit `config-overlay.json`:
```json
{
  "permissions": {
    "allow": [
      "Read(*)",
      "YourNewTool(*)"
    ]
  }
}
```

Apply changes:
```bash
just install-pckgs
```

### Add New MCP Server

1. **Define environment variables** (if needed) in `modules/language.nix`:
```nix
home.sessionVariables = {
  YOUR_SERVER_TOKEN = "your-token";
};
```

2. **Add server configuration** to `config-overlay.json`:
```json
{
  "mcpServers": {
    "your-server": {
      "command": "npx",
      "args": ["-y", "@example/mcp-server"],
      "env": {
        "TOKEN": "${YOUR_SERVER_TOKEN}"
      },
      "_comment": "서버 설명"
    }
  }
}
```

3. **Apply changes**:
```bash
just install-pckgs
```

### Remove MCP Server

Simply remove the server configuration from `config-overlay.json` and run:
```bash
just install-pckgs
```

## Benefits of This Approach

✅ **Version Control**: Share permissions and MCP servers across machines
✅ **Preserve Runtime Data**: Project history and settings stay intact
✅ **Automatic Sync**: No manual steps needed
✅ **Safe Updates**: Automatic backups before each sync
✅ **Multi-Machine**: Same configuration on all your devices
✅ **Platform Independent**: Works across WSL, NixOS, and macOS

## Troubleshooting

### Configuration not syncing

```bash
# Check if jq is available
which jq

# Manually trigger sync
just install-pckgs

# Check Claude config
cat ~/.claude.json | jq '.mcpServers'
```

### MCP server not starting

```bash
# Check environment variables
echo $GDRIVE_CREDENTIALS_PATH

# Test MCP server manually
npx -y @modelcontextprotocol/server-gdrive

# Check Claude Code logs (if available)
```

### Restore from backup

```bash
# List backups
ls -lt ~/.claude.json.backup.*

# Restore specific backup
cp ~/.claude.json.backup.YYYYMMDD_HHMMSS ~/.claude.json
```

## Implementation Details

The sync is powered by:
- **Nix `home.activation`**: Runs after symlinks are created
- **jq**: Merges JSON files using `.[0] * .[1]` operator
- **sponge** (moreutils): Safely writes to files
- **lib.hm.dag.entryAfter**: Ensures proper execution order

See `home.nix:47-72` for the implementation.

## Related Documentation

- [CLAUDE.md](./CLAUDE.md) - Project-specific Claude Code instructions
- [/docs/integrations/claude-code/overview.md](../../docs/integrations/claude-code/overview.md) - Complete Claude Code integration guide
- [MCP Documentation](https://modelcontextprotocol.io/) - Model Context Protocol specification
