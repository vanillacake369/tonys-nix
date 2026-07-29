# Claude Code Configuration

This directory contains Claude Code configuration that is automatically synced via home-manager.

## Directory Structure

```
modules/agents/providers/claude/
├── README.md              # This file
├── AGENTS.md              # Symlink to ../../shared/AGENTS.md
├── settings.json          # Claude Code permissions
├── commands/              # Custom slash commands (/commit, /pr, /blog, etc.)
├── agents/                # Custom AI agents (architect, implementer, etc.)
├── hooks/                 # Claude hook scripts
└── skills/                # Custom skills (architectural-planning, etc.)
```

## AGENTS.md

`AGENTS.md` is a symlink to `modules/agents/shared/AGENTS.md`, the canonical provider-neutral instruction source. Keep behavioral policy there; Claude-specific files should only adapt tools, permissions, hooks, and native commands.

## How Configuration Sync Works

### Automatic Sync via Home-Manager

When you run `just apply`, home-manager:

1. **Symlinks static files** to `~/.claude/`:
   - `commands/` → `~/.claude/commands/`
   - `agents/` → `~/.claude/agents/`
   - `skills/` → `~/.claude/skills/`
   - `AGENTS.md` → `~/.claude/AGENTS.md`

2. **Merges dynamic settings**:
   - `settings.json` plus policy hooks → `~/.claude/settings.json`
   - MCP servers from `modules/agents/agents-mcp.nix` → `~/.claude.json`
   - Preserves runtime data (projects, tips history, etc.)
   - Creates timestamped backup before modification

## Available MCP Servers

| Server | Package | Description |
|--------|---------|-------------|
| context7 | `@upstash/context7-mcp@latest` | 최신 오픈소스 문서 조회 |
| playwright | `@executeautomation/playwright-mcp-server` | 브라우저 제어 및 시각 검증 |

## Modifying Configuration

### Add New MCP Server

Add to `modules/agents/agents-mcp.nix` and apply:
```bash
just apply
```

### Troubleshooting

```bash
# Manually trigger sync
just apply

# Check Claude config
cat ~/.claude.json | jq '.mcpServers'

# Restore from backup
ls -lt ~/.claude.json.backup.*
cp ~/.claude.json.backup.YYYYMMDD_HHMMSS ~/.claude.json
```
