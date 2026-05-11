# Claude Code Configuration

This directory contains Claude Code configuration that is automatically synced via home-manager.

## Directory Structure

```
dotfiles/claude/
├── README.md              # This file
├── AGENTS.md              # Provider-agnostic agent guide (agents.md standard)
├── settings.json          # Claude Code permissions
├── mcp-servers.json       # MCP server configurations
├── commands/              # Custom slash commands (/commit, /pr, /blog, etc.)
├── agents/                # Custom AI agents (architect, implementer, etc.)
└── skills/                # Custom skills (architectural-planning, etc.)
```

## AGENTS.md

`AGENTS.md` follows the [agents.md](https://agents.md/) standard — a provider-agnostic file that any AI coding agent (Claude Code, Cursor, Amp, Copilot, etc.) can read. It contains guardrails, orchestration rules, and commit/PR conventions.

## How Configuration Sync Works

### Automatic Sync via Home-Manager

When you run `just install-pckgs`, home-manager:

1. **Symlinks static files** to `~/.claude/`:
   - `commands/` → `~/.claude/commands/`
   - `agents/` → `~/.claude/agents/`
   - `skills/` → `~/.claude/skills/`
   - `AGENTS.md` → `~/.claude/AGENTS.md`

2. **Merges dynamic settings** into `~/.claude.json`:
   - Permissions from `settings.json`
   - MCP servers from `mcp-servers.json`
   - Preserves runtime data (projects, tips history, etc.)
   - Creates timestamped backup before modification

## Available MCP Servers

| Server | Package | Description |
|--------|---------|-------------|
| context7 | `@upstash/context7-mcp@latest` | 최신 오픈소스 문서 조회 |
| playwright | `@executeautomation/playwright-mcp-server` | 브라우저 제어 및 시각 검증 |

## Modifying Configuration

### Add New MCP Server

Add to `mcp-servers.json` and apply:
```bash
just install-pckgs
```

### Troubleshooting

```bash
# Manually trigger sync
just install-pckgs

# Check Claude config
cat ~/.claude.json | jq '.mcpServers'

# Restore from backup
ls -lt ~/.claude.json.backup.*
cp ~/.claude.json.backup.YYYYMMDD_HHMMSS ~/.claude.json
```
